open Syntax

type plugin = { name : string; id : string; params : Yaml.value option }
[@@deriving of_yaml]

type tags = Event.tags

let rec tag_pairs_of_yaml = function
  | [] -> Ok []
  | (key, `String value) :: rest ->
      let+ rest = tag_pairs_of_yaml rest in
      (key, value) :: rest
  | (key, _) :: _ -> Error.msgf "global_tags: %S must be a string" key

let tags_of_yaml = function
  | `O assoc ->
      let+ tags = tag_pairs_of_yaml assoc in
      List.sort (fun (k0, _) (k1, _) -> compare k0 k1) tags
  | _ -> Error.msgf "global_tags must be a mapping of strings"

type config = { global_tags : tags; [@default []] plugins : plugin list }
[@@deriving of_yaml]

let load_from_path path =
  let* yaml = Yaml_unix.(of_file Fpath.(v path)) in
  config_of_yaml yaml
