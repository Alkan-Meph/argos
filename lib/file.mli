val load : fs:'a Eio.Path.t -> string -> (string, Error.t) result
(** [load ~fs path] reads the contents of [path]. *)
