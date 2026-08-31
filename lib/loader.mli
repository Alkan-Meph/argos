val load_plugin_from_config : Config.plugin -> (Plugin.loaded, Error.t) result
(** Resolves [config.id] in the plugin table and builds the plugin from its
    params. Unknown ids and invalid params are [Error]s naming the offending
    plugin. *)

val load_plugins_from_config :
  Config.plugin list -> (Plugin.loaded list, Error.t) result
(** Loads every plugin of the configuration, in order. All-or-nothing: the first
    failure aborts the whole load, so a partially valid configuration never
    starts. *)
