open Argos.Syntax

let run plugins env =
  let bus_stream = Eio.Stream.create 1000 in
  let plugin_inputs = List.filter_map snd plugins in
  let plugin_fibers =
    List.map (fun (plugin, _) -> plugin env bus_stream) plugins
  in
  let dispatcher_fiber =
    Argos.Dispatcher.run ~input:bus_stream ~outputs:plugin_inputs
  in
  Eio.Fiber.all (dispatcher_fiber :: plugin_fibers)

let boot () =
  let path = Sys.argv.(1) in
  let* config = Argos.Config.load_from_path path in
  let* plugins = Argos.Loader.load_plugins_from_config config.plugins in
  Ok (Eio_main.run (run plugins))

let () =
  Logs.set_reporter (Logs_fmt.reporter ());
  Logs.set_level (Some Logs.Info);
  match boot () with
  | Ok _ -> ()
  | Error (`Msg err) ->
      Logs.err (fun m -> m "loading error: %s" err);
      exit 1
