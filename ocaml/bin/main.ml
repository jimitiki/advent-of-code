open Advent
open Printf

let exit msg =
  let () = printf "%s\n" msg in
  raise Exit

let get_arg i name =
  let arg =
    try Sys.argv.(i)
    with Invalid_argument _ -> exit (sprintf "Missing arg: %s" name)
  in
  try int_of_string arg
  with Failure _ -> exit (sprintf "%s arg is not a number" name)

let year = get_arg 1 "year"
let day = get_arg 2 "day"

let () =
  match Solvers.Registry.get (year, day) with
  | None -> printf "No solution found for year %d day %d\n" (year + 2000) day
  | Some (module S : Solver) -> (
      match S.solve (Input.read year day) with
      | exception Bad_input s -> printf "Error: %s\n" s
      | p1, p2 ->
          printf "\nPart 1: %s\nPart 2: %s\n" (Ans.to_string p1)
            (Ans.to_string p2))
