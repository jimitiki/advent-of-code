open Advent

let hash input =
  let hex = Digest.MD5.string input in
  Digest.MD5.to_hex hex

let rec find_prefix ?(index = 1) salt prefix =
  let msg = Printf.sprintf "%s%d" salt index in
  let digest = hash msg in
  if String.starts_with digest ~prefix then index
  else
    let index = index + 1 in
    find_prefix salt ~index prefix

let solve input =
  let salt = Input.one_line input in
  let zero5 = String.make 5 '0' in
  let p1 = find_prefix salt zero5 in
  let zero6 = String.make 6 '0' in
  let p2 = find_prefix ~index:p1 salt zero6 in
  (Ans.Int p1, Ans.Int p2)

module S = struct
  let solve = solve
end

let () = Registry.register (15, 04) (module S : Solver)
