let load ~fs path =
  match Eio.Path.load Eio.Path.(fs / path) with
  | content -> Ok content
  | exception (Eio.Io _ as exc) -> Error.msgf "%s: %a" path Eio.Exn.pp exc
