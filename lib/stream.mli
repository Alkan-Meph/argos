type 'a t
(** A bounded queue: an [Eio.Stream.t] that knows its own capacity, which makes
    a non-blocking {!try_add} possible.

    Mirrors the [Eio.Stream] interface, argument order included. *)

val create : int -> 'a t
(** [create capacity] is an empty stream holding up to [capacity] items.

    [capacity] follows [Eio.Stream.create]'s semantics, [0] (rendezvous)
    included; note that {!try_add} always fails on a zero-capacity stream. *)

val add : 'a t -> 'a -> unit
(** [add t item] adds [item] to [t]; blocks while [t] is full. *)

val try_add : 'a t -> 'a -> bool
(** [try_add t item] adds [item] to [t] and returns [true], or returns [false]
    without blocking when [t] is full. The item is lost on [false]; logging the
    drop is the caller's job.

    The check and the add are atomic within a single domain only (fibers cannot
    interleave between them); racy if several domains write to [t]. *)

val take : 'a t -> 'a
(** [take t] removes and returns the next item; blocks while [t] is empty. *)

val take_nonblocking : 'a t -> 'a option
(** [take_nonblocking t] is [Some (take t)], or [None] instead of blocking when
    [t] is empty. *)

val length : 'a t -> int
(** [length t] is the number of items currently in [t]. *)

val is_empty : 'a t -> bool
(** [is_empty t] is [length t = 0]. *)
