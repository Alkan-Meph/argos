val run :
  bus:Event.t Eio.Stream.t -> inputs:Event.t Eio.Stream.t list -> unit -> 'a
(** [run ~bus ~inputs ()] forwards every event taken from [bus] to each consumer
    input of [inputs], in list order. Never returns.

    Delivery is blocking: when a consumer input is full, the dispatcher waits,
    which in turn stalls the whole bus. A consumer that stops draining its input
    eventually stops every producer. *)
