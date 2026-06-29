open Advent

let rec diff_decoded s =
  if String.length s = 0 then 0
  else
    let diff, drop =
      match s.[0] with
      | '\\' -> (
          match s.[1] with
          | '\\' | '"' -> (1, 2)
          | 'x' -> (3, 4)
          | _ ->
              let esc = String.take_first 2 s in
              let msg = Printf.sprintf "Invalid escape sequence %s" esc in
              raise (Bad_input msg))
      | '"' -> (1, 1)
      | _ -> (0, 1)
    in
    diff + diff_decoded (String.drop_first drop s)

let rec diff_encoded s =
  if String.length s = 0 then 2
  else
    let d = match s.[0] with '"' | '\\' -> 1 | _ -> 0 in
    d + diff_encoded (String.drop_first 1 s)

let solve input =
  let p1 = List.fold_left (fun acc s -> acc + diff_decoded s) 0 input in
  let p2 = List.fold_left (fun acc s -> acc + diff_encoded s) 0 input in
  (Ans.Int p1, Ans.Int p2)

module S = struct
  let solve = solve
end

let () = Registry.register (15, 08) (module S : Solver)
