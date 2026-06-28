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

let print_res res =
  match res with
  | Error s -> printf "  Error: %s\n" s
  | Ok (p1, p2) ->
      let p1, p2 = (Ans.to_string p1, Ans.to_string p2) in
      printf "  Part 1: %s\n  Part 2: %s\n" p1 p2

let run_solver (module S : Solver) input =
  let t0 = Sys.time () in
  let res =
    match S.solve input with
    | exception Bad_input s -> Error s
    | p1, p2 -> Ok (p1, p2)
  in
  let elapsed = Sys.time () -. t0 in
  print_res res;
  elapsed

let run_all () =
  let run ((year, day), (module S : Solver)) =
    printf "\n[%d.%d]:\n" (year + 2000) day;
    let input = Input.read year day in
    let t = run_solver (module S) input in
    printf "  Elapsed time: %.6f seconds\n" t;
    flush Out_channel.stdout;
    t
  in
  let entries = Solvers.Registry.all () in
  let elapsed = List.fold_left (fun t entry -> t +. run entry) 0.0 entries in
  printf "Total elapsed time: %.6f seconds\n" elapsed

let run_one year day =
  match Solvers.Registry.get (year, day) with
  | None -> printf "No solution found for year %d day %d\n" (year + 2000) day
  | Some (module S : Solver) ->
      let input = Input.read year day in
      let elapsed = run_solver (module S) input in
      printf "  Elapsed time: %.6f seconds\n" elapsed

let () =
  if Sys.argv.(1) = "all" then run_all ()
  else
    let year = get_arg 1 "year" in
    let day = get_arg 2 "day" in
    run_one year day
