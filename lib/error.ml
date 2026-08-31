type t = [ `Msg of string ]

let msgf fmt = Format.kasprintf (fun m -> Error (`Msg m)) fmt
