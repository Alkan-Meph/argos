val run :
  input:Event.t Eio.Stream.t -> outputs:Event.t Eio.Stream.t list -> unit -> 'a
(** [run ~input ~outputs ()] forwards every event taken from [input] to each
    stream of [outputs], in list order. Never returns.

    Delivery is blocking: when an output stream is full, the dispatcher waits,
    which in turn stalls the whole bus. A consumer that stops draining its
    stream eventually stops every producer. *)
