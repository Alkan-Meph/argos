type t = {
  timestamp : float;  (** Unix epoch, in seconds. *)
  source_id : string;  (** Registry id of the producing plugin, e.g. ["mem"]. *)
  source_name : string;
      (** Config instance name; distinguishes two instances of the same plugin.
      *)
  name : string;
      (** Metric name, with unit suffix by convention, e.g. ["mem_total_bytes"],
          ["dns_up"]. *)
  tags : (string * string) list;
      (** Dimensions identifying the series, e.g. [("host", "example.com")]. *)
  value : float;  (** The measurement. Booleans are encoded as [1.0]/[0.0]. *)
}
(** A single metric sample, the only value flowing on the event bus.
    [(source_name, name, tags)] identifies a series; [(timestamp, value)] is one
    point of it. *)

val create :
  clock:'a Eio.Time.clock ->
  source_id:string ->
  source_name:string ->
  name:string ->
  tags:(string * string) list ->
  value:float ->
  t
(** [create ~clock ~source_id ~source_name ~name ~tags ~value] makes an event,
    stamping [timestamp] from [clock]. *)

val emit :
  clock:'a Eio.Time.clock ->
  stream:t Eio.Stream.t ->
  source_id:string ->
  source_name:string ->
  name:string ->
  tags:(string * string) list ->
  value:float ->
  unit
(** [emit ~clock ~stream ~source_id ~source_name ~name ~tags ~value] makes an
    event, stamping [timestamp] from [clock], and pushes it to [stream].

    Blocks if [stream] is full, producers slow down instead of dropping events.
*)

val tags_to_yojson : (string * string) list -> Yojson.Safe.t
(** Converts tags to a JSON object, one field per tag.

    Tags are sorted by key first, so equal tag sets always serialize
    identically, series identity in sinks relies on this. *)

val to_yojson : t -> Yojson.Safe.t
(** Converts an event to a single flat JSON object: field names match the
    record, [tags] is rendered with {!tags_to_yojson}. This format is a public
    contract, external consumers parse it. *)
