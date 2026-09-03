type name = string
type tags = (string * string) list
type value = float

type t = {
  timestamp : float;
  source_id : string;
  source_name : string;
  name : name;
  tags : tags;
  value : value;
}

let merge_tags tags0 tags1 =
  let compare (k0, _) (k1, _) = compare k0 k1 in
  let tags = List.sort compare tags1 in
  tags0 |> List.merge compare tags |> List.sort_uniq compare

let create ~global_tags ~timestamp ~source_id ~source_name ~name ~tags ~value =
  let tags = merge_tags global_tags tags in
  { timestamp; source_id; source_name; name; tags; value }

let emit ~stream t = Eio.Stream.add stream t
let tags_to_yojson tags = `Assoc (List.map (fun (k, v) -> (k, `String v)) tags)

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
