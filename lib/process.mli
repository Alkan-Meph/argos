val run :
  process_mgr:'a Eio.Process.mgr -> string list -> (string, Error.t) result
(** [run ~process_mgr cmd] runs [cmd] and captures its standard output.

    A non-zero exit status is an [Error], with the command and reason in the
    message.

    Standard error is not captured: it flows to the parent's stderr. *)
