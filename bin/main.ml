open Argos.Syntax
open Cmdliner

let run plugins env =
  let bus_stream = Eio.Stream.create 1000 in
  let plugin_inputs = List.filter_map snd plugins in
  let plugin_fibers =
    List.map (fun (plugin, _) -> plugin ~env ~output:bus_stream) plugins
  in
  let dispatcher_fiber =
    Argos.Dispatcher.run ~input:bus_stream ~outputs:plugin_inputs
  in
  Eio.Fiber.all (dispatcher_fiber :: plugin_fibers)

let boot config_path log_level =
  Logs.set_reporter (Logs_fmt.reporter ());
  Logs.set_level log_level;
  match
    let* config = Argos.Config.load_from_path config_path in
    let+ plugins = Argos.Loader.load_plugins_from_config config.plugins in
    Eio_main.run (run plugins)
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
