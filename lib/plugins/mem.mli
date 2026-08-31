val run : name:string -> delay:float -> host:string -> Plugin.t
(** [run ~name ~delay ~host] is a producer: every [delay] seconds it samples
    system memory and emits four events, tagged with [host]: [mem_total_bytes],
    [mem_used_bytes], [mem_available_bytes] (bytes) and [mem_used_pct] (0 to
    100).

    [host] names the machine argos runs on; it makes the series safe to store
    alongside other machines' metrics.

    The OS backend is chosen once at startup ([sysctl] and [vm_stat] on macOS,
    [/proc/meminfo] on Linux). An unsupported OS disables the plugin with an
    error log. A failed sampling is logged as a warning and skipped; the loop
    keeps running. *)

val load :
  name:string -> delay:float -> host:string -> (Plugin.loaded, Error.t) result
(** [load ~name ~delay ~host] prepares the plugin. [delay] must be strictly
    positive and [host] non-empty. *)

val load_from_config : Config.plugin -> (Plugin.loaded, Error.t) result
(** Expects a [params] section with [delay] (seconds, float) and [host] (this
    machine's name) fields. *)
