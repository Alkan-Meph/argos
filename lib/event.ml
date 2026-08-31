type t = {
  timestamp : float;
  source_id : string;
  source_name : string;
  name : string;
  tags : (string * string) list;
  value : float;
}

let create ~clock ~source_id ~source_name ~name ~tags ~value =
  { timestamp = Eio.Time.now clock; source_id; source_name; name; tags; value }

let emit ~clock ~stream ~source_id ~source_name ~name ~tags ~value =
  Eio.Stream.add stream
    (create ~clock ~source_id ~source_name ~name ~tags ~value)

let tags_to_yojson tags =
  `Assoc
    (tags
    |> List.sort (fun (k1, _) (k2, _) -> compare k1 k2)
    |> List.map (fun (k, v) -> (k, `String v)))

let to_yojson event =
  `Assoc
    [
      ("timestamp", `Float event.timestamp);
      ("source_name", `String event.source_name);
      ("source_id", `String event.source_id);
      ("name", `String event.name);
      ("tags", tags_to_yojson event.tags);
      ("value", `Float event.value);
    ]
