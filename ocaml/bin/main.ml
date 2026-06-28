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

let run_solver (module S : Solver) input =
  let t0 = Sys.time () in
  let res =
    match S.solve input with
    | exception Bad_input s -> Error s
    | p1, p2 -> Ok (p1, p2)
  in
  let elapsed = Sys.time () -. t0 in
  (elapsed, res)

let () =
  match Solvers.Registry.get (year, day) with
  | None -> printf "No solution found for year %d day %d\n" (year + 2000) day
  | Some (module S : Solver) ->
      printf "\n[%d.%d]:\n" (year + 2000) day;
      let input = Input.read year day in
      let elapsed, res = run_solver (module S) input in
      let () =
        match res with
        | Error s -> printf "  Error: %s\n" s
        | Ok (p1, p2) ->
            let p1, p2 = (Ans.to_string p1, Ans.to_string p2) in
            printf "  Part 1: %s\n  Part 2: %s\n" p1 p2
      in
      printf "  [Elapsed = %.6f]\n" elapsed
