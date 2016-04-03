(** Generates a static .ml file containing the measurement angles *)

let t = Urg.init ~tty:Sys.argv.(1)

let rad_table = Urg.angles t

open Format

let print_rad_table =
  printf "let angles =@ @[<1>[|";
  for i = 0 to Array.length rad_table - 1 do
    printf "%.30f;@ " rad_table.(i);
  done;
  printf "@]|]@."
