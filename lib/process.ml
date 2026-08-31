let run ~process_mgr cmd =
  match Eio.Process.parse_out process_mgr Eio.Buf_read.take_all cmd with
  | stdout -> Ok stdout
  | exception (Eio.Io _ as exc) ->
      let cmd = String.concat " " cmd in
      Error.msgf "%s: %a" cmd Eio.Exn.pp exc
