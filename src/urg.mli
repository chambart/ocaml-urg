(** Interraction with Hokuyo's URG laser rangefinder *)

type t
(** A connected device *)

val init : tty:string -> t
(** Initialize the scanner connected to the [tty] device.
    {[init ~tty:"/dev/ttyACM0"]}

    The scanner is initialized in the continuous scanning mode.
*)

type measure = (nativeint, Bigarray.nativeint_elt, Bigarray.c_layout) Bigarray.Array1.t
(** A bigarray containing measures. ordered from left to right.
    The distances are in millimeter. An absence of measure is represented as [-1]
*)

val get : t -> float * measure
(** [get device] receive fresh data from the device.
    It returns the measure and a timestamp in seconds.

    The [i] point coordinate in meters (in the device frame of reference) is
    {[let distance = 0.001 *. Nativeint.to_float (snd (get device).{i}) in
      distance *. cos (angle device).(i),
      distance *. sin (angle device).(i)]}

    To avoid the repeated allocation cost, [update] can be used instead.
*)

val create_buffer : t -> measure
(** Create a fresh buffer of the right size *)

val update : t -> measure -> float
(** [update device buffer] Wait for the next data from the device and
    write it in [buffer].
    Returns the timestamp of the measure in seconds.

    [get device] is equivalent to:
    {[let buffer = create_buffer device in
      update device buffer, buffer]}

    Fails with [Invalid_argument] if the buffer is not of the right
    size.
*)

val angles : t -> float array
(** The angles in radiant of measure points.
    The angle in front of the device is 0,
    Left are negative angles and right positive.
*)

val id : t -> string
(** The device (normaly unique) identifier *)

val info : t -> string array
(** Various device informations *)
