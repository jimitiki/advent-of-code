open Advent

let is_vowel c = match c with 'a' | 'e' | 'i' | 'o' | 'u' -> true | _ -> false

let count_vowels s =
  String.fold_left (fun acc c -> if is_vowel c then acc + 1 else acc) 0 s

let has_3_vowels s = count_vowels s >= 3

let rec has_pair s =
  if String.length s < 2 then false
  else if s.[0] = s.[1] then true
  else has_pair (String.drop_first 1 s)

let has_forbidden s =
  String.includes ~affix:"ab" s
  || String.includes ~affix:"cd" s
  || String.includes ~affix:"pq" s
  || String.includes ~affix:"xy" s

let rec has_matching_pair s =
  if String.length s < 4 then false
  else if
    let pair, rest = String.cut_first 2 s in
    String.includes ~affix:pair rest
  then true
  else
    let s = String.drop_first 1 s in
    has_matching_pair s

let rec has_sandwich s =
  if String.length s < 3 then false
  else if s.[0] = s.[2] then true
  else
    let s = String.drop_first 1 s in
    has_sandwich s

let is_nice1 s = has_3_vowels s && has_pair s && not (has_forbidden s)
let is_nice2 s = has_matching_pair s && has_sandwich s

let count_nice f input =
  List.fold_left (fun acc s -> if f s then acc + 1 else acc) 0 input

let solve input =
  (Ans.Int (count_nice is_nice1 input), Ans.Int (count_nice is_nice2 input))

module S = struct
  let solve = solve
end

let () = Registry.register (15, 05) (module S : Solver)
