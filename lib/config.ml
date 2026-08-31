open Syntax

type plugin = { name : string; id : string; params : Yaml.value option }
[@@deriving of_yaml]

type config = { plugins : plugin list } [@@deriving of_yaml]

let load_from_path path =
  let* yaml = Yaml_unix.(of_file Fpath.(v path)) in
  config_of_yaml yaml
