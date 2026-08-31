(lang dune 3.24)

(name argos)

(source
 (github Alkan-Meph/argos))

(authors "Alkan-Meph")

(maintainers "Alkan-Meph")

(license MIT)

(package
 (name argos)
 (synopsis "A tiny plugin-based monitoring agent built on Eio")
 (description
  "Argos runs producer plugins that collect metrics (memory, DNS, ...) and\n\
   sink plugins that consume them (JSON Lines output, SQLite storage), all\n\
   wired together from a YAML configuration file.")
 (depends
  (ocaml
   (>= 5.5))
  dune
  eio_main
  yaml
  ppx_deriving_yaml
  fpath
  re
  logs
  fmt
  yojson
  uri
  caqti
  caqti-eio
  caqti-driver-sqlite3
  cmdliner
  (alcotest :with-test))
 (tags
  (monitoring metrics eio)))
