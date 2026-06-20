open Advent

let dims_as_ints (l, w, h) =
  try (int_of_string l, int_of_string w, int_of_string h)
  with Failure _ ->
    let msg = Printf.sprintf "Got a non-integer dimension (%sx%sx%s)" l w h in
    raise (Bad_input msg)

let parse_line line =
  let dims = String.split_on_char 'x' line in
  match dims with
  | [ l; w; h ] -> dims_as_ints (l, w, h)
  | _ ->
      let msg =
        Printf.sprintf "Expected 3 dimensions, got %d (%s)" (List.length dims)
          line
      in
      raise (Bad_input msg)

let rec parse lines =
  match lines with
  | [] -> []
  | "" :: tail -> parse tail
  | line :: tail -> parse_line line :: parse tail

let paper (l, w, h) =
  let lw = l * w in
  let lh = l * h in
  let wh = w * h in
  let min = Int.min (Int.min lw lh) wh in
  (2 * lw) + (2 * lh) + (2 * wh) + min

let rec sum_paper ?(acc = 0) dims =
  match dims with
  | [] -> acc
  | (l, w, h) :: tail ->
      let acc = paper (l, w, h) + acc in
      sum_paper ~acc tail

let solve input =
  let dims = parse input in
  (Ans.Int (sum_paper dims), Ans.None)
