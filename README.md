# Argos 👀

A small monitoring agent written in OCaml on top of [Eio](https://github.com/ocaml-multicore/eio).

Argos runs a set of plugins defined in a YAML file. Producer plugins collect
metrics (memory usage, DNS resolution, ...) and push events on an internal
bus; sink plugins consume the bus and do something with the events (print
them as JSON Lines, store them in SQLite, ...). Everything is a plugin with
the same interface, wired together at boot from the configuration.

This is a personal project, built for fun and to learn Eio. Do not expect
stability, support, or a roadmap.

## About AI usage

The architecture, the design decisions, and the code itself are written by a
human. AI is used on this project as an assistant: writing documentation (sorry
I'm bad in English...) and gathering information. 

## Conventions

### Function signatures

A function takes at most one positional argument: its subject (the thing the
function's name is about), placed last. Every other argument is labeled. When
there is no obvious single subject, everything is labeled. Printf-style
functions (like `Error.msgf`) follow the ecosystem idiom instead and stay
positional.

Private helpers inside a module are free to use positional arguments. Their
order follows one canon: name, then configuration, then capabilities, then
streams last.

### Errors

Errors are values: `('a, Error.t) result` everywhere, chained with the
`let*` and `let+` operators from `Syntax`. `Error.t` is the ecosystem's
`` `Msg`` convention and is built exclusively through `Error.msgf`.

Error and log messages locate problems by the plugin instance name, using the
`plugin(<name>): ...` prefix. The offending value is quoted with `%S` so that
invisible characters show up. Errors bubble up and are handled once, at the
boundary: boot errors stop the program with a message on stderr and exit code
1, runtime errors are logged and the plugin keeps running.

### Metrics

Metric names follow `<domain>_<measure>_<unit>`, for example
`mem_total_bytes` or `dns_up`. Values use base units only: bytes and seconds,
never kilo or mega. Percentages range from 0 to 100 and use the `_pct`
suffix. Booleans are encoded as `1.0` and `0.0`, with 1 meaning the healthy
state.

### Interfaces and documentation

Modules that other modules rely on expose a `.mli`. It declares only the
public contract; everything else is private. Documentation using odoc syntax
lives in the `.mli`.

### Naming

The main type of a module is `t`. Conversions are named `to_xxx`
(`Event.to_yojson`).

## Release build

Releases are static Linux binaries built in Docker (BuildKit required):

```sh
sh scripts/release.sh              # linux/amd64 (default)
sh scripts/release.sh linux/arm64
```

The result lands in `dist/argos-<arch>`: a statically linked, stripped
binary that runs on any Linux distribution, bare containers included.
The script fails if the binary is not actually static.

Under the hood, `scripts/Dockerfile` is a multi-stage build: the
dependencies declared in `dune.lock` are compiled in their own layer
through dune's `@pkg-install` alias, so only the first build (and any
lock change) pays the full cost; source changes rebuild argos alone.

Building on a non-x86 host relies on emulation for `linux/amd64`,
which slows compilation down; build the platform matching your
machine when you just want to test the pipeline.

## TODO

- Automatically tag every event with `host`
- Let the logger plugin offer several output formats (text, JSON, ...)
- Add data retention (purge of old events) to the db plugin
- Support PostgreSQL / MariaDB in the db plugin
- Add a CPU plugin
- Add a TCP / UDP plugin
- Add a processes plugin (per-process information)
- Add a metrics visualization plugin
- Add a rules engine: evaluate thresholds on events and emit alerts
- Add alerting sinks (Telegram, Slack, webhook, ...)
- Validate the configuration: non-empty and unique plugin names
- Proper CLI (cmdliner): config path, verbosity flags, version
- Share one timestamp across all events of a plugin tick
- Rebuild the test suite (parsers, dispatcher, loader)
