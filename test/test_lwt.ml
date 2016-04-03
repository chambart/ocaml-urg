(** Print measurement extremas, show how to interract with lwt *)

open Lwt

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

let count = ref 0

let get' t =
  let t1 = Unix.gettimeofday () in
  let c1 = !count in
  Lwt_preemptive.detach Urg.get t >>= fun (ts, data) ->
  let t2 = Unix.gettimeofday () in
  let c2 = !count in
  Printf.printf "diff count %i %f\n%!" (c2 - c1) (t2 -. t1);
  return (ts, data)

let () =
  let rec aux () =
    get' t >>= fun (ts, data) ->
    let min, pos_min = ba_extrema data valid_measure ((<):int -> int -> bool) in
    let max, pos_max = ba_extrema data valid_measure ((>):int -> int -> bool) in
    let rad_min = rad_table.(pos_min) in
    let rad_max = rad_table.(pos_max) in
    Printf.printf "%.3f min: %.3f (%.3f rad) max: %.3f (%.3f rad)\n%i\n%!"
      ts min rad_min max rad_max !count;
    aux ()
  in
  let rec loop () =
    incr count;
    Lwt_unix.sleep 0.001 >>= fun () ->
    loop ()
  in
  let t1 = aux () in
  let _ = loop () in
  Lwt_unix.run t1
