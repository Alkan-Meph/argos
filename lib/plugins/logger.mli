val run : name:string -> input:Event.t Eio.Stream.t -> Plugin.t
(** [run ~name ~input] is a sink: it writes every event taken from [input] to
    standard output, one JSON object per line (JSON Lines).

    The object layout is {!Event.to_yojson}'s. Only events go to stdout; argos
    logs go to stderr, so the output can be piped: [argos config.yml | jq]. *)

val load : name:string -> (Plugin.loaded, Error.t) result
(** [load ~name] prepares the plugin. *)

val load_from_config : Config.plugin -> (Plugin.loaded, Error.t) result
(** Takes no [params]: providing a section is an error, so a misconfigured entry
    fails at boot instead of being silently ignored. *)
