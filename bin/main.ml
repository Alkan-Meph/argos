open Argos.Syntax
open Cmdliner

let run global_tags plugins env =
  let bus = Eio.Stream.create 1000 in
  let plugin_inputs = List.filter_map snd plugins in
  let clock = Eio.Stdenv.clock env in
  let emit = Argos.Plugin.make_emit ~global_tags ~clock ~bus in
  let plugin_fibers = List.map (fun (plugin, _) -> plugin ~env ~emit) plugins in
  let dispatcher_fiber = Argos.Dispatcher.run ~bus ~inputs:plugin_inputs in
  Eio.Fiber.all (dispatcher_fiber :: plugin_fibers)

let boot config_path log_level =
  Logs.set_reporter (Logs_fmt.reporter ());
  Logs.set_level log_level;
  match
    let* config = Argos.Config.load_from_path config_path in
    let+ plugins = Argos.Loader.load_plugins_from_config config.plugins in
    Eio_main.run (run config.global_tags plugins)
  with
  | Ok _ -> 0
  | Error (`Msg err) ->
      Logs.err (fun m -> m "loading error: %s" err);
      1

let config_arg =
  let doc = "path to the YAML config file" in
  Arg.(required & pos 0 (some file) None & info [] ~docv:"CONFIG" ~doc)

let cmd =
  let doc = "a tiny plugin-based monitoring agent" in
  Cmd.make (Cmd.info "argos" ~doc)
    Term.(const boot $ config_arg $ Logs_cli.level ())

let () = exit (Cmd.eval' cmd)
