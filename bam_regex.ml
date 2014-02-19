open Core.Std

module Match = struct
    type t = string list 
    exception No_match

    let create regex_str str =
        let re = Str.regexp regex_str in
        let rec loop acc group_n =
            try
                loop (acc @ [Str.matched_group group_n str]) (group_n + 1)
            with Invalid_argument _ -> acc
        in
        let empty = ([] : t) in
        if (Str.string_match re str 0) = true then Some (loop empty 1) else None

    let create_exn regex_str str =
        match create regex_str str with
        | Some t -> t
        | None   -> raise No_match

    let count = List.length
    let (nth: t -> int -> string option) = List.nth
    (* This exception with be List's, not mine, but whatev *)
    let (nth_exn: t -> int -> string) = List.nth_exn
end
