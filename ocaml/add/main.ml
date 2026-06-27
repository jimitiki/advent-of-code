open Printf

let template =
  format_of_string
    "open Advent\n\n\
     let solve input = (Ans.None, Ans.None)\n\n\
     module S = struct\n\
    \  let solve = solve\n\
     end\n\n\
     let () = Registry.register (%02d, %02d) (module S : Solver)\n"

let exit msg =
  print_endline msg;
  raise Exit

let write path src =
  let src_file =
    open_out_gen [ Open_creat; Open_excl; Open_text; Open_wronly ] 0o644 path
  in
  output_string src_file src;
  Out_channel.flush src_file;
  close_out src_file

let read_cookie () =
  match In_channel.with_open_text "../cookie.txt" In_channel.input_line with
  | None -> exit "Failed to read cookie"
  | Some cookie -> cookie

let mkdir parent year =
  let path = sprintf "%s/y%02d" parent year in
  if not (Sys.file_exists path) then Sys.mkdir path 0o755;
  path

let fetch_input year day =
  let url = sprintf "https://adventofcode.com/20%02d/day/%d/input" year day in
  let cookie = read_cookie () in
  let headers = [ ("Cookie", cookie) ] in
  match Ezcurl.get ~url ~headers () with
  | Error (code, msg) ->
      let code = Curl.int_of_curlCode code in
      let msg = sprintf "Failed to fetch input (%d - %s)" code msg in
      exit msg
  | Ok resp -> (
      match resp.Ezcurl.code with
      | 200 -> resp.Ezcurl.body
      | c -> exit (sprintf "Unexpected response code: %d" c))

let ensure_input year day =
  let dir_path = mkdir "../inputs" year in
  let file_path = sprintf "%s/d%02d.txt" dir_path day in
  if Sys.file_exists file_path then ()
  else
    let input = fetch_input year day in
    let file = open_out file_path in
    Out_channel.output_string file input;
    close_out file

let create_solver year day =
  ensure_input year day;
  let dir_path = mkdir "bin/solvers" year in
  let src = sprintf template year day in
  let src_path = sprintf "%s/d%02d.ml" dir_path day in
  write src_path src

let rec find_day ?(day = 1) year =
  let max = if year >= 25 then 12 else 25 in
  let path = sprintf "bin/solvers/y%02d/d%02d.ml" year day in
  if not (Sys.file_exists path) then Some day
  else
    let day = day + 1 in
    if day >= max then None else find_day year ~day

let find_day_exc ?(day = 1) year =
  match find_day ~day year with
  | Some d -> d
  | None -> exit (sprintf "All year %02d solutions already exist" year)

let rec find_next ?(year = 15) () =
  let path = sprintf "bin/solvers/y%02d" year in
  if not (Sys.file_exists path) then (year, 1)
  else
    match find_day year with
    | Some day -> (year, day)
    | None ->
        let year = year + 1 in
        if year > 99 then raise Exit else find_next ~year ()

let arg name =
  let index = match name with "year" -> 1 | "day" -> 2 | _ -> raise Exit in
  match int_of_string Sys.argv.(index) with
  | exception Failure _ -> exit (sprintf "Invalid %s arg" name)
  | exception Invalid_argument _ -> None
  | d -> Some d

let year, day =
  let year_arg = arg "year" in
  match arg "day" with
  | Some d -> (Option.get year_arg, d)
  | None -> (
      match year_arg with Some y -> (y, find_day_exc y) | None -> find_next ())

let () =
  let src_path = sprintf "./bin/solvers/y%02d/d%02d.ml" year day in
  if Sys.file_exists src_path then exit "Solution already exists"

let () =
  printf "Creating solution %02d-%02d\n" year day;
  create_solver year day;
  print_endline "Rebuilding project";
  let _ = Sys.command "dune build" in
  print_endline "Done."
