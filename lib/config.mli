(** Configuration file loading. *)

type plugin = {
  name : string;  (** Instance name, free-form, unique per config. *)
  id : string;  (** Plugin id, resolved against [Plugins.Table]. *)
  params : Yaml.value option;
      (** Plugin-specific section, decoded by the plugin itself; [None] when
          absent or null. *)
}

type tags = Event.tags
type config = { global_tags : tags; plugins : plugin list }

val load_from_path : string -> (config, Error.t) result
(** Reads and decodes a YAML configuration file. Fails on unreadable files and
    on any entry missing [name] or [id]. *)
