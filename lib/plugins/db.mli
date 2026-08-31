val run : name:string -> uri:Uri.t -> input:Event.t Eio.Stream.t -> Plugin.t
(** [run ~name ~uri ~input] is the storage sink: it connects to the database at
    [uri], prepares the schema, then stores every event taken from [input],
    forever.

    The schema (tables, indexes, WAL mode) is created at startup when missing; a
    fresh database file works out of the box.

    A failed insert is logged and the event is dropped; the sink keeps running.
    A failed connection or schema setup disables the plugin entirely. *)

val load : name:string -> uri:string -> (Plugin.loaded, Error.t) result
(** [load ~name ~uri] validates [uri] and prepares the plugin. Only the
    [sqlite3] scheme is accepted. *)

val load_from_config : Config.plugin -> (Plugin.loaded, Error.t) result
(** Expects a [params] section with a [uri] field, e.g.
    [uri: "sqlite3:/var/lib/argos/argos.db"]. *)
