val run :
  name:string ->
  uri:Uri.t ->
  retention:float option ->
  purge_delay:float option ->
  input:Event.t Eio.Stream.t ->
  Plugin.t
(** [run ~name ~uri ~retention ~purge_delay ~input] is the storage sink: it
    connects to the database at [uri], prepares the schema, then stores every
    event taken from [input], forever.

    The schema (tables, indexes, WAL mode) is created at startup when missing; a
    fresh database file works out of the box.

    When [retention] and [purge_delay] are set, events older than [retention]
    seconds are deleted, at most once every [purge_delay] seconds. The check
    runs in the consuming loop: no event, no purge, but the database is not
    growing either. Series are never deleted.

    A failed insert is logged and the event is dropped; the sink keeps running.
    A failed purge is logged and retried on the next event. A failed connection
    or schema setup disables the plugin entirely. *)

val load :
  name:string ->
  uri:string ->
  retention:float option ->
  purge_delay:float option ->
  (Plugin.loaded, Error.t) result
(** [load ~name ~uri ~retention ~purge_delay] validates the parameters and
    prepares the plugin. Only the [sqlite3] scheme is accepted. [retention] and
    [purge_delay] go together: setting one without the other is an error. *)

val load_from_config : Config.plugin -> (Plugin.loaded, Error.t) result
(** Expects a [params] section with a [uri] field and, optionally, [retention]
    and [purge_delay] (seconds, floats), e.g.:
    {[
      params:
        uri: "sqlite3:/var/lib/argos/argos.db"
        retention: 604800.0
        purge_delay: 3600.0
    ]} *)
