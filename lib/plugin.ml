type t = env:Eio_unix.Stdenv.base -> output:Event.t Eio.Stream.t -> unit -> unit
type loaded = t * Event.t Eio.Stream.t option

let loop ~clock ~delay producer =
  while true do
    producer ();
    Eio.Time.sleep clock delay
  done
