# OCaml-URG

Simple OCaml interface to Hokuyo's URG laser rangefinder

```OCaml
(* Load libraries *)
#use "topfind";;
#require "graphics";;
#require "urg";;

(* Connect to the device *)
let t = Urg.init ~tty:"/dev/ttyACM0"

let angles = Urg.angles t

(* Receive a range measure *)
let _, measure = Urg.get t

let scale f points =
  Array.map (fun (x, y) -> f *. x, f *. y) points

let shift (a, b) points =
  Array.map (fun (x, y) -> a +. x, b +. y) points

let coordinate distances i =
  let distance = 0.001 *. Nativeint.to_float distances.{i} in
  distance *. cos angles.(i),
  distance *. sin angles.(i)

let () =
  Graphics.open_graph " 200x200";
  Graphics.clear_graph ();

  (* Convert distances to coordinates *)
  let points = Array.init (Bigarray.Array1.dim measure) (coordinate measure) in

  (* Shift and scale points to have something visible *)
  let moved_points = (shift (200., 100.) (scale 200. points)) in
  Array.iter (fun (x, y) ->
      Graphics.plot (int_of_float x) (int_of_float y))
    moved_points;

  (* Wait for the user to press a key before exiting *)
  ignore (Graphics.wait_next_event [Graphics.Key_pressed])
```
