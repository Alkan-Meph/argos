(** Binding operators for [result]-returning code. *)

val ( let* ) : ('a, 'b) result -> ('a -> ('c, 'b) result) -> ('c, 'b) result
(** [Result.bind]: [let* x = e in body] runs [body] only if [e] is [Ok x]; the
    first [Error] short-circuits the whole chain. *)

val ( let+ ) : ('a, 'b) result -> ('a -> 'c) -> ('c, 'b) result
(** [Result.map]: like [( let* )] but [body] cannot fail, use it for the final
    transformation to avoid wrapping in [Ok]. *)
