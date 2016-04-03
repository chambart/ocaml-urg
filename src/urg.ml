type measure = (nativeint, Bigarray.nativeint_elt, Bigarray.c_layout) Bigarray.Array1.t

module Binding = struct

  type urg

  external urg_disconnect : urg -> unit = "ocaml_urg_disconnect"
  external urg_connect : string -> int -> urg option = "ocaml_urg_connect"

  type typ =
    | URG_GD
    | URG_GD_INTENSITY
    | URG_GS
    | URG_MD
    | URG_MD_INTENSITY
    | URG_MS

  external urg_dataMax : urg -> int = "ocaml_urg_dataMax"
  external urg_requestData : urg -> typ -> int = "ocaml_urg_requestData"
  external urg_receiveData : urg -> measure -> int = "ocaml_urg_receiveData"
  external urg_recentTimestamp : urg -> int = "ocaml_urg_recentTimestamp"

  external urg_scanMsec : urg -> int = "ocaml_urg_scanMsec"
  (* in milliseconds *)

  external urg_maxDistance : urg -> int = "ocaml_urg_maxDistance"
  (* in millimeters *)

  external urg_minDistance : urg -> int = "ocaml_urg_minDistance"
  (* in millimeters *)

  external urg_setCaptureTimes : urg -> int -> int = "ocaml_urg_setCaptureTimes"
  (* work only with captures MD and MS:
     set to 0 for continuous scanning *)

  external urg_remainCaptureTimes : urg -> int = "urg_remainCaptureTimes"
  (* number of captures scheduled and not done *)

  external urg_index2rad : urg -> int -> float = "ocaml_urg_index2rad"
  external urg_reboot : urg -> int = "ocaml_urg_reboot"

  external urg_versionLines : urg -> string array option = "ocaml_urg_versionLines"

end

let get_angles urg size =
  Array.init size (fun i -> Binding.urg_index2rad urg i)

type t =
  { urg : Binding.urg;
    size : int;
    angles : float array;
    info : string array; }

let make_point_data n =
  Bigarray.Array1.create Bigarray.nativeint Bigarray.c_layout n

let create_buffer t = make_point_data t.size

let init ~tty =
  match Binding.urg_connect tty 115200 with
  | None -> failwith "fail connect"
  | Some urg ->
    match Binding.urg_versionLines urg with
    | None ->
      failwith "Urg.init: Couldn't get id"
    | Some info ->
      let size = Binding.urg_dataMax urg in
      if Binding.urg_setCaptureTimes urg 0 < 0
      then failwith "Urg.init: set capture times";
      if Binding.urg_requestData urg Binding.URG_MD < 0
      then failwith "Urg.init: request data";
      let angles = get_angles urg size in
      { urg; size; info; angles }

let update t buffer =
  if Bigarray.Array1.dim buffer <> t.size then
    invalid_arg "Urg.update";
  if Binding.urg_receiveData t.urg buffer < 0
  then failwith "Urg.update: receive data";
  let ts = Binding.urg_recentTimestamp t.urg in
  0.001 *. float ts

let get t =
  let b = make_point_data t.size in
  if Binding.urg_receiveData t.urg b < 0
  then failwith "Urg.get: receive data";
  let ts = Binding.urg_recentTimestamp t.urg in
  0.001 *. float ts, b

let angles t = t.angles

let id t =
  String.sub t.info.(4) 5 8

let info t = t.info
