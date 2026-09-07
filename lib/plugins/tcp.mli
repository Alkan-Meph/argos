val run :
  name:string ->
  delay:float ->
  target:string ->
  port:int ->
  timeout:float option ->
  Plugin.t
(** [run ~name ~delay ~target ~port ~timeout] is a producer: every [delay]
    seconds it attempts a TCP connection to [target]:[port] and emits a [tcp_up]
    event tagged with [target] and [port], valued [1.0] when the connection is
    established, [0.0] otherwise (refused, unreachable, resolution failure or
    timeout).

    [target] is an IP address or a domain name; resolution goes through the
    system resolver, and every resolved address is tried in order until one
    accepts. [timeout] (seconds) bounds each connection attempt; without it, a
    blackholing target can stall the probe well beyond [delay]. *)

val load :
  name:string ->
  delay:float ->
  target:string ->
  port:int ->
  timeout:float option ->
  (Plugin.loaded, Error.t) result
(** [load ~name ~delay ~target ~port ~timeout] prepares the plugin. [delay] must
    be strictly positive, [target] non-empty, [port] within [1-65535] and
    [timeout], when given, strictly positive. *)

val load_from_config : Config.plugin -> (Plugin.loaded, Error.t) result
(** Expects a [params] section with [delay] (seconds, float), [target], [port]
    and, optionally, [timeout] (seconds, float) fields, e.g.:
    {[
      params:
        delay: 30.0
        target: "example.com"
        port: 443
        timeout: 5.0
    ]} *)
