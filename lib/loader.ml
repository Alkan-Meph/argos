open Syntax

let load_plugin_from_config (config : Config.plugin) =
  match List.assoc_opt config.id Plugins.Table.plugins with
  | Some plugin -> plugin config
  | None ->
      Error.msgf "loader: unknown plugin id %S for %S" config.id config.name

let load_plugins_from_config configs =
  let rec load configs plugins =
    match configs with
    | [] -> Ok plugins
    | config :: configs ->
        let* plugin = load_plugin_from_config config in
        load configs (plugin :: plugins)
  in
  load configs []
