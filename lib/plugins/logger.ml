let id = "logger"

let consume name stdout input ~state:_ =
  let event = Eio.Stream.take input in
  let json = Yojson.Safe.to_string (Event.to_yojson event) in
  Eio.Flow.copy_string (json ^ "\n") stdout

let run ~name ~input ~env ~emit () =
  let stdout = env#stdout in
  let consume = consume name stdout input in
  Plugin.consumer ~state:() consume

(* Config *)

let load ~name =
  let input = Eio.Stream.create 1000 in
  Ok (run ~name ~input, Some input)

let load_from_config (config : Config.plugin) =
  match config.params with
  | None -> load ~name:config.name
  | _ -> Error.msgf "plugin(%s): too many params given" config.name
