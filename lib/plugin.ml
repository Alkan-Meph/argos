type metrics = (Event.name * Event.tags * Event.value) list
type emitter = source_id:string -> source_name:string -> metrics -> unit
type t = env:Eio_unix.Stdenv.base -> emit:emitter -> unit -> unit
type loaded = t * Event.t Eio.Stream.t option
type 'a callback = state:'a -> 'a

let make_emit ~global_tags ~clock ~bus ~source_id ~source_name metrics =
  let timestamp = Eio.Time.now clock in
  let create_event (name, tags, value) =
    Event.create ~global_tags ~timestamp ~source_id ~source_name ~name ~tags
      ~value
  in
  metrics |> List.map create_event |> List.iter (Event.emit ~stream:bus)

let rec producer ~clock ~delay ~state produce =
  let state = produce ~state in
  Eio.Time.sleep clock delay;
  producer ~clock ~delay ~state produce

let rec consumer ~state consume =
  let state = consume ~state in
  consumer ~state consume
