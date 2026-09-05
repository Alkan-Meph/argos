open Syntax
open Caqti.Templater

type state = {
  cache : (string * string * string, int) Hashtbl.t;
  mutable last_purge_timestamp : float;
}

let id = "db"
let state () = { cache = Hashtbl.create 20; last_purge_timestamp = 0.0 }

let series_table_sql =
  {|
CREATE TABLE IF NOT EXISTS series (
  id          INTEGER PRIMARY KEY,
  source_id   TEXT NOT NULL,
  source_name TEXT NOT NULL,
  name        TEXT NOT NULL,
  tags        TEXT NOT NULL DEFAULT '{}',
  UNIQUE(source_name, name, tags)
) STRICT
|}

let events_table_sql =
  {|
CREATE TABLE IF NOT EXISTS events (
  id        INTEGER PRIMARY KEY,
  timestamp REAL NOT NULL,
  series_id INTEGER REFERENCES series(id) NOT NULL,
  value     REAL NOT NULL
) STRICT
|}

let events_ts_idx_sql =
  "CREATE INDEX IF NOT EXISTS idx_events_ts ON events (timestamp);"

let events_series_ts_idx_sql =
  "CREATE INDEX IF NOT EXISTS idx_events_series_ts ON events (series_id, \
   timestamp);"

let create_series_table_req = static T.(unit -->. unit) series_table_sql
let create_events_table_req = static T.(unit -->. unit) events_table_sql
let create_events_ts_idx_req = static T.(unit -->. unit) events_ts_idx_sql

let create_events_series_ts_idx_req =
  static T.(unit -->. unit) events_series_ts_idx_sql

let set_journal_mode_pragma_req =
  static T.(unit -->! string) "PRAGMA journal_mode=WAL"

let insert_series_req =
  static
    T.(t4 string string string string -->! int)
    {|
      INSERT INTO series (source_id, source_name, name, tags)
      VALUES (?,?,?,?)
      ON CONFLICT (source_name, name, tags) DO UPDATE SET name = excluded.name
      RETURNING id
    |}

let insert_event_req =
  static
    T.(t3 float int float -->. unit)
    "INSERT INTO events (timestamp, series_id, value) VALUES (?,?,?)"

let delete_events_req =
  static T.(float -->. unit) "DELETE FROM events WHERE timestamp <= ?"

let init (module C : Caqti_eio.CONNECTION) =
  let* _ = C.find set_journal_mode_pragma_req () in
  let* _ = C.exec create_series_table_req () in
  let* _ = C.exec create_events_table_req () in
  let* _ = C.exec create_events_ts_idx_req () in
  let+ _ = C.exec create_events_series_ts_idx_req () in
  ()

let insert_series (module C : Caqti_eio.CONNECTION) (event : Event.t) tags =
  C.find insert_series_req (event.source_id, event.source_name, event.name, tags)

let insert_event (module C : Caqti_eio.CONNECTION) (event : Event.t) series_id =
  C.exec insert_event_req (event.timestamp, series_id, event.value)

let delete_events (module C : Caqti_eio.CONNECTION) timestamp =
  C.exec delete_events_req timestamp

let get_or_insert_series (module C : Caqti_eio.CONNECTION) cache
    (event : Event.t) =
  let tags = Yojson.Safe.to_string (Event.tags_to_yojson event.tags) in
  let key = (event.source_name, event.name, tags) in
  match Hashtbl.find_opt cache key with
  | Some id -> Ok id
  | None ->
      let+ series_id = insert_series (module C) event tags in
      Hashtbl.add cache key series_id;
      series_id

let purge name clock (module C : Caqti_eio.CONNECTION) retention purge_delay
    ~state =
  match (retention, purge_delay) with
  | Some retention, Some purge_delay -> begin
      let now = Eio.Time.now clock in
      let delta = now -. state.last_purge_timestamp in
      if delta >= purge_delay then
        let cutoff = now -. retention in
        match delete_events (module C) cutoff with
        | Ok () -> state.last_purge_timestamp <- now
        | Error err ->
            Logs.err (fun m ->
                m "plugin(%s): purge error: %a" name Caqti.Error.pp err)
    end
  | _, _ -> () (* Cannot happen *)

let consume name (module C : Caqti_eio.CONNECTION) input ~state =
  let event = Eio.Stream.take input in
  begin match get_or_insert_series (module C) state.cache event with
  | Ok series_id ->
      begin match insert_event (module C) event series_id with
      | Ok () -> ()
      | Error err ->
          Logs.err (fun m ->
              m "plugin(%s): insert event error: %a" name Caqti.Error.pp err)
      end
  | Error err ->
      Logs.err (fun m ->
          m "plugin(%s): insert series error: %a" name Caqti.Error.pp err)
  end;
  state

let run ~name ~uri ~retention ~purge_delay ~input ~env ~emit () =
  Eio.Switch.run @@ fun sw ->
  match Caqti_eio_unix.connect ~sw ~stdenv:(env :> Caqti_eio.stdenv) uri with
  | Error err ->
      Logs.err (fun m ->
          m "plugin(%s): connection error: %a" name Caqti.Error.pp err)
  | Ok (module C) ->
      begin match init (module C) with
      | Error err ->
          Logs.err (fun m ->
              m "plugin(%s): init error: %a" name Caqti.Error.pp err)
      | Ok () ->
          let clock = Eio.Stdenv.clock env in
          let purge = purge name clock (module C) retention purge_delay in
          let consume = consume name (module C) input in
          let state = state () in
          let callback ~state =
            purge ~state;
            consume ~state
          in
          Plugin.consumer ~state callback
      end

(* Config *)

type params = {
  uri : string;
  retention : float option;
  purge_delay : float option;
}
[@@deriving of_yaml]

let parse_uri uri =
  let parsed_uri = Uri.of_string uri in
  match Uri.scheme parsed_uri with
  | Some "sqlite3" -> Ok parsed_uri
  | Some s -> Error.msgf "unsupported scheme %S" s
  | None -> Error.msgf "invalid db uri %S" uri

let check_params retention purge_delay =
  match (retention, purge_delay) with
  | None, Some _ -> Error.msgf "purge_delay is set but retention is missing"
  | Some _, None -> Error.msgf "retention is set but purge_delay is missing"
  | _, _ -> Ok ()

let load ~name ~uri ~retention ~purge_delay =
  begin
    let* () = check_params retention purge_delay in
    let+ uri = parse_uri uri in
    let input = Eio.Stream.create 1000 in
    (run ~name ~uri ~retention ~purge_delay ~input, Some input)
  end
  |> Result.map_error (fun (`Msg err) ->
      `Msg (Printf.sprintf "plugin(%s): %s" name err))

let load_from_config (config : Config.plugin) =
  match config.params with
  | None -> Error.msgf "plugin(%s): missing params" config.name
  | Some params ->
      let* params = params_of_yaml params in
      load ~name:config.name ~uri:params.uri ~retention:params.retention
        ~purge_delay:params.purge_delay
