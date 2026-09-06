val run : bus:Event.t Stream.t -> inputs:Event.t Stream.t list -> unit -> 'a
(** [run ~bus ~inputs ()] forwards every event taken from [bus] to each consumer
    input of [inputs], in list order. Never returns.

    Delivery is non-blocking: when a consumer input is full, the event is
    dropped for that consumer (with a warning) and delivery to the others goes
    on. A stalled consumer loses events but never freezes the bus. *)
