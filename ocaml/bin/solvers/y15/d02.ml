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

let rec sum ?(acc = 0) f dims =
  match dims with
  | [] -> acc
  | (l, w, h) :: tail ->
      let acc = f (l, w, h) + acc in
      sum ~acc f tail

let paper (l, w, h) =
  let lw, lh, wh = (l * w, l * h, w * h) in
  let min = Int.min (Int.min lw lh) wh in
  (2 * lw) + (2 * lh) + (2 * wh) + min

let ribbon (l, w, h) =
  let vol = l * w * h in
  let l2, w2, h2 = (l * 2, w * 2, h * 2) in
  vol + Int.min (Int.min (l2 + w2) (l2 + h2)) (w2 + h2)

let solve input =
  let dims = parse input in
  (Ans.Int (sum paper dims), Ans.Int (sum ribbon dims))

module S = struct
  let solve = solve
end

let () = Registry.register (15, 2) (module S : Solver)
