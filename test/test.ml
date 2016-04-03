(** Print measurement extremas *)

let tty = if Array.length Sys.argv > 1 then Sys.argv.(1) else "/dev/ttyACM0"

let t = Urg.init ~tty

let min_val = 30

let rad_table = Urg.angles t

let valid_measure a =
  (* We drop measures bellow 30mm, those are probably noise *)
  a < min_val

let ba_extrema ba filter cmp =
  let m = ref (Nativeint.to_int ba.{0}) in
  let pos = ref 0 in
  for i = 0 to Bigarray.Array1.dim ba - 1 do
    let v = Nativeint.to_int ba.{i} in
    if cmp v !m
    then (m := v; pos := i)
  done;
  0.001 *. float !m, !pos

let () = Printf.printf "id: %s\n%!" (Urg.id t)

let () =
  let data = Urg.create_buffer t in
  while true do
    let ts = Urg.update t data in
    let min, pos_min = ba_extrema data valid_measure ((<):int -> int -> bool) in
    let max, pos_max = ba_extrema data valid_measure ((>):int -> int -> bool) in
    let rad_min = rad_table.(pos_min) in
    let rad_max = rad_table.(pos_max) in
    Printf.printf "%.3f min: %.3f (%.3f rad) max: %.3f (%.3f rad)\n%!"
      ts min rad_min max rad_max
  done
