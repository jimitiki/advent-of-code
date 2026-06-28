let table : (int * int, (module Advent.Solver)) Hashtbl.t = Hashtbl.create 500
let register k m = Hashtbl.add table k m
let get k = Hashtbl.find_opt table k
let all () = table |> Hashtbl.to_seq |> List.of_seq |> List.sort compare
