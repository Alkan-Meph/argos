type t = env:Eio_unix.Stdenv.base -> output:Event.t Eio.Stream.t -> unit -> unit
(** A plugin that is called by Argos.

    The stream is the output of the plugin. Every event emitted into it will be
    dispatched into the input streams of all the plugins.

    Applying the final [()] starts the plugin. It is meant to be forked by the
    runtime. *)

type loaded = t * Event.t Eio.Stream.t option
(** A plugin ready to be wired up and run.

    The stream is the plugin's input queue: [Some stream] means the plugin
    consumes events from this stream, the dispatcher must broadcast events into
    this stream. [None] means the plugin only produces.

    A plugin that returns [Some stream] owns the stream and is the only reader.
*)

val loop : clock:'a Eio.Time.clock -> delay:float -> (unit -> unit) -> unit
(** [loop ~clock ~delay producer] runs [producer] forever, sleeping [delay]
    seconds between calls.

    The first call happens immediately, not after [delay].

    [delay] is a pause, not a period: the effective interval is [delay] plus the
    producer's own execution time. *)
