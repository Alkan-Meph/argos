type 'a t = { stream : 'a Eio.Stream.t; capacity : int }

let create capacity = { stream = Eio.Stream.create capacity; capacity }
let add t = Eio.Stream.add t.stream

let try_add t item =
  if Eio.Stream.length t.stream < t.capacity then begin
    add t item;
    true
  end
  else false

let take t = Eio.Stream.take t.stream
let take_nonblocking t = Eio.Stream.take_nonblocking t.stream
let length t = Eio.Stream.length t.stream
let is_empty t = Eio.Stream.is_empty t.stream
