open Advent
open Printf

type instruction = Toggle | On | Off
type mode = B | I

let parse_coordinates s =
  match String.split_on_char ',' s with
  | [ x; y ] -> (int_of_string x, int_of_string y)
  | _ ->
      let msg = sprintf "Invalid coordinate string %s" s in
      raise (Bad_input msg)

let parse_instruction s =
  let inst, t =
    match String.split_on_char ' ' s with
    | "toggle" :: t -> (Toggle, t)
    | "turn" :: "on" :: t -> (On, t)
    | "turn" :: "off" :: t -> (Off, t)
    | _ ->
        let msg = sprintf "Invalid instruction %s" s in
        raise (Bad_input msg)
  in
  let coord1, coord2 =
    match t with
    | [ a; "through"; b ] -> (parse_coordinates a, parse_coordinates b)
    | _ ->
        let msg = sprintf "Invalid instruction %s" s in
        raise (Bad_input msg)
  in
  (inst, coord1, coord2)

let sum lights =
  Array.fold_left
    (fun sum row -> sum + Array.fold_left (fun sum l -> sum + l) 0 row)
    0 lights

let f_exec m inst =
  match (m, inst) with
  | B, Toggle -> fun l -> if l = 1 then 0 else 1
  | B, Off -> fun l -> 0
  | B, On -> fun l -> 1
  | I, Toggle -> fun l -> l + 2
  | I, Off -> fun l -> max 0 (l - 1)
  | I, On -> fun l -> l + 1

let rec exec m instructions lights =
  match instructions with
  | [] -> sum lights
  | h :: t ->
      let inst, s, e = parse_instruction h in
      let f = f_exec m inst in
      for i = snd s to snd e do
        let row = lights.(i) in
        let _ = f in
        for j = fst s to fst e do
          row.(j) <- f row.(j)
        done
      done;
      exec m t lights

let run m instructions =
  let lights = Array.init 1000 (fun _ -> Array.make 1000 0) in
  exec m instructions lights

let solve input =
  let p1 = Ans.Int (run B input) in
  let p2 = Ans.Int (run I input) in
  (p1, p2)

module S = struct
  let solve = solve
end

let () = Registry.register (15, 06) (module S : Solver)
