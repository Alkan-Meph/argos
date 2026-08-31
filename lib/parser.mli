val parse_re : re:Re.re -> what:string -> string -> (string, Error.t) result
(** [parse_re ~re ~what input] searches [input] for the first match of [re].

    [re] must contain at least one capture group; other groups are ignored. No
    match is an [Error] mentioning [what], a short human-readable label for the
    value being extracted, e.g. ["page size"]. *)

val parse_float : string -> (float, Error.t) result
(** [parse_float input] is [input] as a float, accepting any syntax
    [float_of_string] does. *)

val parse_float_re :
  re:Re.re -> what:string -> string -> (float, Error.t) result
(** [parse_re] specialized to float values: extracts the first capture group and
    parses it. *)
