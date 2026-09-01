open Syntax

let id = "mem"

type mem_stats = {
  mem_total_bytes : float;
  mem_used_bytes : float;
  mem_available_bytes : float;
  mem_used_pct : float;
}

module Linux = struct
  let mem_total_re = Re.compile (Re.Perl.re {|MemTotal:\s+(\d+) kB|})
  let mem_available_re = Re.compile (Re.Perl.re {|MemAvailable:\s+(\d+) kB|})

  let parse_stats meminfo =
    let open Parser in
    let* mem_total_kb =
      parse_float_re ~re:mem_total_re ~what:"MemTotal" meminfo
    in
    let+ mem_available_kb =
      parse_float_re ~re:mem_available_re ~what:"MemAvailable" meminfo
    in
    let mem_used_kb = mem_total_kb -. mem_available_kb in
    let mem_used_pct = mem_used_kb /. mem_total_kb *. 100.0 in
    {
      mem_total_bytes = mem_total_kb *. 1024.0;
      mem_used_bytes = mem_used_kb *. 1024.0;
      mem_available_bytes = mem_available_kb *. 1024.0;
      mem_used_pct;
    }

  let get_mem_stats fs () =
    let* meminfo = File.load ~fs "/proc/meminfo" in
    parse_stats meminfo
end

module Darwin = struct
  let total_mem_re = Re.compile (Re.Perl.re {|(\d+)\n|})
  let page_size_re = Re.compile (Re.Perl.re {|page size of (\d+) bytes|})
  let pages_active_re = Re.compile (Re.Perl.re {|Pages active:\s+(\d+)\.|})

  let pages_wired_down_re =
    Re.compile (Re.Perl.re {|Pages wired down:\s+(\d+)\.|})

  let pages_occupied_re =
    Re.compile (Re.Perl.re {|Pages occupied by compressor:\s+(\d+)\.|})

  let parse_stats sysctl vm_stats =
    let open Parser in
    let* mem_total_bytes =
      parse_float_re ~re:total_mem_re ~what:"total mem" sysctl
    in
    let* page_size =
      parse_float_re ~re:page_size_re ~what:"page size" vm_stats
    in
    let* pages_active =
      parse_float_re ~re:pages_active_re ~what:"pages active" vm_stats
    in
    let* pages_wired_down =
      parse_float_re ~re:pages_wired_down_re ~what:"pages wired down" vm_stats
    in
    let+ pages_occupied =
      parse_float_re ~re:pages_occupied_re ~what:"pages occupied" vm_stats
    in
    let mem_used_bytes =
      (pages_active +. pages_wired_down +. pages_occupied) *. page_size
    in
    let mem_available_bytes = mem_total_bytes -. mem_used_bytes in
    let mem_used_pct = mem_used_bytes /. mem_total_bytes *. 100.0 in
    { mem_total_bytes; mem_used_bytes; mem_available_bytes; mem_used_pct }

  let get_mem_stats process_mgr () =
    let* sysctl_stdout =
      Process.run ~process_mgr [ "sysctl"; "-n"; "hw.memsize" ]
    in
    let* vm_stats_stdout = Process.run ~process_mgr [ "vm_stat" ] in
    parse_stats sysctl_stdout vm_stats_stdout
end

type backend = Linux | Darwin

let choose_backend uname =
  match String.trim uname with
  | "Linux" -> Ok Linux
  | "Darwin" -> Ok Darwin
  | uname -> Error.msgf "unknown os %S" uname

let choose_get_mem_stats env =
  let process_mgr = Eio.Stdenv.process_mgr env in
  let* uname = Process.run ~process_mgr [ "uname" ] in
  let+ backend = choose_backend uname in
  match backend with
  | Linux -> Linux.get_mem_stats (Eio.Stdenv.fs env)
  | Darwin -> Darwin.get_mem_stats process_mgr

let emit_events name host clock output stats =
  let tags = [ ("host", host) ] in
  Event.emit ~clock ~stream:output ~source_id:id ~source_name:name
    ~name:"mem_total_bytes" ~tags ~value:stats.mem_total_bytes;
  Event.emit ~clock ~stream:output ~source_id:id ~source_name:name
    ~name:"mem_used_bytes" ~tags ~value:stats.mem_used_bytes;
  Event.emit ~clock ~stream:output ~source_id:id ~source_name:name
    ~name:"mem_available_bytes" ~tags ~value:stats.mem_available_bytes;
  Event.emit ~clock ~stream:output ~source_id:id ~source_name:name
    ~name:"mem_used_pct" ~tags ~value:stats.mem_used_pct

let produce name host clock get_mem_stats output () =
  match get_mem_stats () with
  | Ok stats -> emit_events name host clock output stats
  | Error (`Msg err) -> Logs.warn (fun m -> m "plugin(%s): %s" name err)

let run ~name ~delay ~host ~env ~output () =
  let clock = Eio.Stdenv.clock env in
  match choose_get_mem_stats env with
  | Ok get_mem_stats ->
      let producer = produce name host clock get_mem_stats output in
      Plugin.loop ~clock ~delay producer
  | Error (`Msg err) ->
      Logs.err (fun m -> m "plugin(%s): impossible to run: %s" name err)

(* Config *)

type params = { delay : float; host : string } [@@deriving of_yaml]

let check_params delay host =
  if delay <= 0.0 then Error.msgf "invalid delay %g" delay
  else if host = "" then Error.msgf "host is empty"
  else Ok ()

let load ~name ~delay ~host =
  let host = String.trim host in
  match check_params delay host with
  | Ok () -> Ok (run ~name ~delay ~host, None)
  | Error (`Msg err) -> Error.msgf "plugin(%s): %s" name err

let load_from_config (config : Config.plugin) =
  match config.params with
  | None -> Error.msgf "plugin(%s): missing params" config.name
  | Some params ->
      let* params = params_of_yaml params in
      load ~name:config.name ~delay:params.delay ~host:params.host
