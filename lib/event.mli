type name = string
type tags = (string * string) list
type value = float

type t = {
  timestamp : float;  (** Unix epoch, in seconds. *)
  source_id : string;  (** Registry id of the producing plugin, e.g. ["mem"]. *)
  source_name : string;
      (** Config instance name; distinguishes two instances of the same plugin.
      *)
  name : name;
      (** Metric name, with unit suffix by convention, e.g. ["mem_total_bytes"],
          ["dns_up"]. *)
  tags : tags;
      (** Dimensions identifying the series, e.g. [("host", "example.com")]. *)
  value : value;  (** The measurement. Booleans are encoded as [1.0]/[0.0]. *)
}
(** A single metric sample, the only value flowing on the event bus.
    [(source_name, name, tags)] identifies a series; [(timestamp, value)] is one
    point of it. *)

val create :
  global_tags:(string * string) list ->
  timestamp:float ->
  source_id:string ->
  source_name:string ->
  name:name ->
  tags:tags ->
  value:value ->
  t
(** [create ~global_tags ~timestamp ~source_id ~source_name ~name ~tags ~value]
    makes an event.

    [global_tags] are merged into [tags]; on a key conflict the plugin's tag
    wins. The resulting tags are sorted by key. [global_tags] must be sorted by
    key. *)

val emit : stream:t Eio.Stream.t -> t -> unit
(** [emit ~stream event] pushes [event] to [stream].

    Blocks if [stream] is full, producers slow down instead of dropping events.
*)

val tags_to_yojson : tags -> Yojson.Safe.t
(** Converts tags to a JSON object, one field per tag.

    Tags must be sorted by key; the tags of any [t] already are, [create]
    guarantees it. Equal sorted tag sets serialize identically, series identity
    in sinks relies on this. *)

val to_yojson : t -> Yojson.Safe.t
(** Converts an event to a single flat JSON object: field names match the
    record, [tags] is rendered with {!tags_to_yojson}. This format is a public
    contract, external consumers parse it. *)
