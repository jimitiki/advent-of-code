exception Bad_input of string

module Ans = struct
  type answer = Int of int | Str of string | None

  let to_string ans =
    match ans with None -> "No answer" | Str s -> s | Int i -> Int.to_string i
end

module Input = struct
  let rec read_input ch =
    match input_line ch with
    | exception End_of_file -> []
    | s -> s :: read_input ch

  let read year day =
    let ch = Printf.sprintf "../inputs/y%02d/d%02d.txt" year day |> open_in in
    let input = read_input ch in
    close_in ch;
    match input with
    | [] -> raise (Bad_input "Input file is empty")
    | _ -> input

  let one_line input =
    match input with
    | [] -> raise (Bad_input "Input file is empty")
    | line :: [] -> line
    | "" :: _ -> raise (Bad_input "First line is empty")
    | _ :: _ -> raise (Bad_input "Too many lines")
end

module type Solver = sig
  val solve : string list -> Ans.answer * Ans.answer
end
