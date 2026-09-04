type metrics = (Event.name * Event.tags * Event.value) list
(** One tick's worth of measurements, emitted as a single batch. *)

type emitter = source_id:string -> source_name:string -> metrics -> unit
(** Turns a batch of metrics into events and pushes them on the bus.

    All events of one call share the same timestamp: a batch is a snapshot.
    Plugins usually fix [~source_id] and [~source_name] once by partial
    application. *)

type t = env:Eio_unix.Stdenv.base -> emit:emitter -> unit -> unit
(** A plugin that is called by Argos.

    [emit] is the plugin's only way to produce events; the dispatcher then
    broadcasts them to every consuming plugin.

    Applying the final [()] starts the plugin. It is meant to be forked by the
    runtime. *)

type loaded = t * Event.t Eio.Stream.t option
(** A plugin ready to be wired up and run.

    The stream is the plugin's input queue: [Some stream] means the plugin
    consumes events from this stream, the dispatcher must broadcast events into
    this stream. [None] means the plugin only produces.

    A plugin that returns [Some stream] owns the stream and is the only reader.
*)

val make_emit :
  global_tags:Event.tags ->
  clock:'a Eio.Time.clock ->
  bus:Event.t Eio.Stream.t ->
  source_id:string ->
  source_name:string ->
  metrics ->
  unit
(** [make_emit ~global_tags ~clock ~bus] is the {!emitter} handed to plugins: it
    stamps the batch with one timestamp from [clock], merges [global_tags] in,
    builds the events and pushes them to [bus]. *)

type 'a callback = state:'a -> 'a
(** One step of a plugin loop: takes the current state, returns the state for
    the next step. A mutable state (e.g. a [Hashtbl.t]) is returned as is; a
    stateless plugin uses [unit] and ignores it ([~state:_]). *)

val producer :
  clock:'a Eio.Time.clock -> delay:float -> state:'b -> 'b callback -> unit
(** [producer ~clock ~delay ~state produce] runs [produce] forever, threading
    the state and sleeping [delay] seconds between calls.

    The first call happens immediately, not after [delay].

    [delay] is a pause, not a period: the effective interval is [delay] plus the
    producer's own execution time. *)

val consumer : state:'a -> 'a callback -> unit
(** [consumer ~state consume] runs [consume] forever, threading the state.

    No pacing: [consume] is expected to block on its input stream. *)
