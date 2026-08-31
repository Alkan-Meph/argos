type t = [ `Msg of string ]
(** An error meant for humans: a message, nothing to match on.

    Structurally compatible with the [`Msg] convention used across the ecosystem
    (yaml, fpath, bos, ...), so their errors flow through argos code
    unconverted. *)

val msgf : ('a, Format.formatter, unit, ('b, t) result) format4 -> 'a
(** [msgf fmt ...] is [Error (`Msg msg)] with [msg] built printf-style.

    [Format] directives are supported, notably [%a] for printers:
    [msgf "%s: %a" cmd Eio.Exn.pp exn]. *)
