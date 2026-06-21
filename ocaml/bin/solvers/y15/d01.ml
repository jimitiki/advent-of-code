open Advent

let next_floor str index floor =
  match str.[index] with
  | '(' -> floor + 1
  | ')' -> floor - 1
  | c ->
      let msg =
        Printf.sprintf "Invalid character `%c` at position %d" c index
      in
      raise (Bad_input msg)

let rec walk_floors ?(index = 0) ?(floor = 0) input fn =
  match fn index floor (String.length input) with
  | Some ans -> ans
  | None ->
      let floor = next_floor input index floor in
      let index = index + 1 in
      walk_floors ~index ~floor input fn

let final_floor index floor len =
  if index = len then Some (Ans.Int floor) else None

let first_negative index floor len =
  if index = len then Some Ans.None
  else if floor < 0 then Some (Ans.Int index)
  else None

let solve input =
  let input = Input.one_line input in
  (walk_floors input final_floor, walk_floors input first_negative)

module S = struct
  let solve = solve
end

let () = Registry.register (15, 1) (module S : Solver)
