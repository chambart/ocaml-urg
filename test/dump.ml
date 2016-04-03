let n = 30

let () =
  if Array.length Sys.argv < 3 then begin
    Printf.eprintf "Usage: tty output_file";
    exit 1
  end

let out_file = Sys.argv.(2)
let dump = open_out out_file

let t = Urg.init ~tty:Sys.argv.(1)

let () = Printf.printf "id: %s\n%!" (Urg.id t)

type point_data = (nativeint, Bigarray.nativeint_elt, Bigarray.c_layout) Bigarray.Array1.t

let () =
  let data =
    Array.init n (fun i ->
        let ts, data = Urg.get t in
        Printf.printf "%i %0.2f %i\n%!" i ts (Bigarray.Array1.dim data);
        (data:point_data))
  in
  output_value dump data;
  close_out dump
