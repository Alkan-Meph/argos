let consume_publish ~bus ~inputs =
  let event = Eio.Stream.take bus in
  List.iter (fun s -> Eio.Stream.add s event) inputs

let run ~bus ~inputs () =
  (* TODO: a full input stream blocks the whole bus (one stalled consumer
     freezes every producer). *)
  while true do
    consume_publish ~bus ~inputs
  done
