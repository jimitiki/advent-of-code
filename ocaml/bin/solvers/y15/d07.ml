open Advent

(* TODO: Ensure that all signals are limited to 16 bits *)

type signal = Wire of string | Static of int

type gate =
  | Direct of signal
  | Not of signal
  | And of (signal * signal)
  | Or of (signal * signal)
  | Lshift of (signal * int)
  | Rshift of (signal * int)

let parse_signal s = try Static (int_of_string s) with Failure _ -> Wire s

let parse_gate s =
  match String.split_all ~sep:" " s with
  | [ a; "->"; o ] -> (o, Direct (parse_signal a))
  | [ "NOT"; a; "->"; o ] -> (o, Not (parse_signal a))
  | [ a; "AND"; b; "->"; o ] -> (o, And (parse_signal a, parse_signal b))
  | [ a; "OR"; b; "->"; o ] -> (o, Or (parse_signal a, parse_signal b))
  | [ a; "LSHIFT"; b; "->"; o ] -> (o, Lshift (parse_signal a, int_of_string b))
  | [ a; "RSHIFT"; b; "->"; o ] -> (o, Rshift (parse_signal a, int_of_string b))
  | _ ->
      let msg = Printf.sprintf "Invalid gate specifier %s" s in
      raise (Bad_input msg)

let rec parse input gates =
  match input with
  | [] -> ()
  | h :: t ->
      let w, g = parse_gate h in
      Hashtbl.replace gates w g;
      parse t gates

let eval_wire gates w =
  let memo = Hashtbl.create (Hashtbl.length gates) in
  let rec eval_signal s =
    match s with
    | Static i -> i
    | Wire w -> (
        match Hashtbl.find_opt memo w with
        | Some v -> v
        | None ->
            let v =
              match Hashtbl.find gates w with
              | Direct a -> eval_signal a
              | Not a -> lnot (eval_signal a)
              | And (a, b) -> eval_signal a land eval_signal b
              | Or (a, b) -> eval_signal a lor eval_signal b
              | Lshift (a, b) -> eval_signal a lsl b
              | Rshift (a, b) -> eval_signal a lsr b
            in
            Hashtbl.replace memo w v;
            v)
  in
  eval_signal (Wire w)

let solve input =
  let gates = Hashtbl.create (List.length input) in
  parse input gates;
  let s1 = eval_wire gates "a" in
  Hashtbl.replace gates "b" (Direct (Static s1));
  let s2 = eval_wire gates "a" in
  (Ans.Int s1, Ans.Int s2)

module S = struct
  let solve = solve
end

let () = Registry.register (15, 07) (module S : Solver)
