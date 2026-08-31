let consume_publish ~input ~outputs =
  let event : Event.t = Eio.Stream.take input in
  List.iter (fun s -> Eio.Stream.add s event) outputs

let run ~input ~outputs () =
  (* TODO: a full output stream blocks the whole bus (one stalled consumer
   freezes every producer). *)
  while true do
    consume_publish ~input ~outputs
  done
