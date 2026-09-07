open Syntax

let id = "tcp"

let is_port_up target port timeout net =
  match
    Eio.Net.with_tcp_connect ?timeout ~host:target ~service:(string_of_int port)
      net (fun _ -> ())
  with
  | () -> true
  | exception Eio.Io _ -> false

let produce target port timeout net emit ~state:_ =
  let tags = [ ("target", target); ("port", string_of_int port) ] in
  let value = if is_port_up target port timeout net then 1.0 else 0.0 in
  emit [ ("tcp_up", tags, value) ]

let run ~name ~delay ~target ~port ~timeout ~env ~emit () =
  let net = Eio.Stdenv.net env in
  let clock = Eio.Stdenv.clock env in
  let mono = Eio.Stdenv.mono_clock env in
  let emit = emit ~source_id:id ~source_name:name in
  let timeout = Option.map (Eio.Time.Timeout.seconds mono) timeout in
  let produce = produce target port timeout net emit in
  Plugin.producer ~clock ~delay ~state:() produce

(* Config *)

type params = {
  delay : float;
  target : string;
  port : int;
  timeout : float option;
}
[@@deriving of_yaml]

let check_params delay target port timeout =
  if delay <= 0.0 then Error.msgf "invalid delay %g" delay
  else if target = "" then Error.msgf "target is empty"
  else if port < 1 || port > 65535 then
    Error.msgf "invalid port %d (must be between 1 and 65535)" port
  else if Option.value timeout ~default:1.0 <= 0.0 then
    Error.msgf "invalid timeout %g (must be strictly positive)"
      (Option.get timeout)
  else Ok ()

let load ~name ~delay ~target ~port ~timeout =
  let target = String.trim target in
  match check_params delay target port timeout with
  | Ok () -> Ok (run ~name ~delay ~target ~port ~timeout, None)
  | Error (`Msg err) -> Error.msgf "plugin(%s): %s" name err

let load_from_config (config : Config.plugin) =
  match config.params with
  | None -> Error.msgf "plugin(%s): missing params" config.name
  | Some params ->
      let* params = params_of_yaml params in
      load ~name:config.name ~delay:params.delay ~target:params.target
        ~port:params.port ~timeout:params.timeout
