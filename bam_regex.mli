module Match :
  sig
    type t
    exception No_match
    val create : string -> string -> t option
    val create_exn : string -> string -> t
    val count : t -> int
    val nth : t -> int -> string option
    val nth_exn : t -> int -> string 
  end
