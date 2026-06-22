open Advent

let rec unique_visits ?(index = 0) ?(pos = (0, 0)) ?(stride = 1) tbl input =
  if index >= String.length input then Hashtbl.length tbl
  else
    let () = Hashtbl.replace tbl pos () in
    let x, y = pos in
    let pos =
      match input.[index] with
      | '>' -> (x + 1, y)
      | '^' -> (x, y + 1)
      | '<' -> (x - 1, y)
      | 'v' -> (x, y - 1)
      | c -> raise (Bad_input (Printf.sprintf "Invalid move %c" c))
    in
    let index = index + stride in
    unique_visits ~index ~pos ~stride tbl input

let solve input =
  let input = Input.one_line input in
  let tbl = Hashtbl.create 1024 in
  let p1 = unique_visits tbl input in
  Hashtbl.clear tbl;
  let _ = unique_visits ~stride:2 tbl input in
  let p2 = unique_visits ~index:1 ~stride:2 tbl input in
  (Ans.Int p1, Ans.Int p2)

module S = struct
  let solve = solve
end

let () = Registry.register (15, 03) (module S : Solver)
