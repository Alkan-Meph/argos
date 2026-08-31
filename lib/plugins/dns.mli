val run : name:string -> delay:float -> target:string -> Plugin.t
(** [run ~name ~delay ~target] is a producer: every [delay] seconds it resolves
    [target] and emits a [dns_up] event tagged with [target], valued [1.0] when
    at least one address is returned, [0.0] otherwise.

    Resolution goes through the system resolver ([/etc/hosts], configured DNS
    servers...). A [0.0] does not distinguish between a non-existent domain and
    a failing resolver. *)

val load :
  name:string -> delay:float -> target:string -> (Plugin.loaded, Error.t) result
(** [load ~name ~delay ~target] prepares the plugin. [delay] must be strictly
    positive and [target] non-empty. *)

val load_from_config : Config.plugin -> (Plugin.loaded, Error.t) result
(** Expects a [params] section with [delay] (seconds, float) and [target]
    fields, e.g.:
    {[
      params:
        delay: 30.0
        target: "example.com"
    ]} *)
