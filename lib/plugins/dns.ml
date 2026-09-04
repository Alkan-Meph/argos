open Syntax

let id = "dns"

let is_dns_up net target =
  match Eio.Net.getaddrinfo net target with
  | _ :: _ -> true
  | [] | (exception Eio.Io _) -> false

let produce target net emit ~state:_ =
  let tags = [ ("target", target) ] in
  let value = if is_dns_up net target then 1.0 else 0.0 in
  emit [ ("dns_up", tags, value) ]

let run ~name ~delay ~target ~env ~emit () =
  let net = Eio.Stdenv.net env in
  let clock = Eio.Stdenv.clock env in
  let emit = emit ~source_id:id ~source_name:name in
  let produce = produce target net emit in
  Plugin.producer ~clock ~delay ~state:() produce

(* Config *)

type params = { delay : float; target : string } [@@deriving of_yaml]

let check_params delay target =
  if delay <= 0.0 then Error.msgf "invalid delay %g" delay
  else if target = "" then Error.msgf "target is empty"
  else Ok ()

let load ~name ~delay ~target =
  let target = String.trim target in
  match check_params delay target with
  | Ok () -> Ok (run ~name ~delay ~target, None)
  | Error (`Msg err) -> Error.msgf "plugin(%s): %s" name err

let load_from_config (config : Config.plugin) =
  match config.params with
  | None -> Error.msgf "plugin(%s): missing params" config.name
  | Some params ->
      let* params = params_of_yaml params in
      load ~name:config.name ~delay:params.delay ~target:params.target
