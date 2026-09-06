let consume_publish ~bus ~inputs =
  let event = Stream.take bus in
  let add_or_log stream =
    if not (Stream.try_add stream event) then
      Logs.warn (fun m ->
          m "dropped event %S from plugin(%s): consumer input full"
            event.Event.name event.Event.source_name)
  in
  List.iter add_or_log inputs

let run ~bus ~inputs () =
  while true do
    consume_publish ~bus ~inputs
  done
