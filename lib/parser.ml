open Syntax

let parse_re ~re ~what input =
  match Re.exec_opt re input with
  | Some result -> Ok (Re.Group.get result 1)
  | None -> Error.msgf "%s not found" what

let parse_float input =
  match float_of_string input with
  | n -> Ok n
  | exception _ -> Error.msgf "impossible to parse float %S" input

let parse_float_re ~re ~what input =
  let* result = parse_re ~re ~what input in
  parse_float result
