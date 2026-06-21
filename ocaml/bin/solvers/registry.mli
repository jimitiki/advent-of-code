open Advent

val register : int * int -> (module Solver) -> unit
val get : int * int -> (module Solver) option
