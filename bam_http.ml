open Core.Std
open Async.Std

type handler = 
    (Cohttp.Request.t -> 
     Bam_regex.Match.t -> 
     Cohttp_async.Server.response Deferred.t)

type request_result = 
    | Supported of handler * Bam_regex.Match.t
    | Unsupported of Cohttp.Code.status_code

type regexp_str = string


module HandlerMap : sig
    type t 
    val create : unit -> t
    val add : t -> ?methods:Cohttp.Code.meth list -> regexp_str -> handler -> t
    val find : t -> Cohttp.Code.meth -> string -> request_result
end = struct
    type t = (regexp_str * ((Cohttp.Code.meth list) * handler)) list

    let create () = ([] : t)

    let add t ?methods path handler =
        List.Assoc.add t path ((Option.value ~default:[] methods), handler)

    let find t meth path =
        let path_matches = List.filter t ~f:(fun (regex_str, _) -> 
            Str.string_match (Str.regexp regex_str) path 0)
        in
        match path_matches with  
        | [] -> Unsupported `Not_found
        (* Just use the first match *)
        | (path_regex_str, (methods, handler))::_ -> 
            let path_regex_match = 
                Bam_regex.Match.create_exn path_regex_str path
            in
            let return_supported = Supported (handler, path_regex_match) in
            (match methods with
            | [] -> return_supported
            | _::_ -> 
                if List.exists ~f:((=) meth) methods then 
                    return_supported
                else 
                    Unsupported `Method_not_allowed)
end


module Server = struct
    type t = HandlerMap.t

    let create () = HandlerMap.create ()

    let add_handler ?methods t ~path ~handler = 
        HandlerMap.add t ?methods path handler

    let serve_file t ~path ~filename = 
            HandlerMap.add t ~methods:[`GET] path (fun _ _ ->
                    Cohttp_async.Server.respond_with_file filename)

    let run_on_port t ~port =
        let handler ~body:_ _sock req =
            let uri = Cohttp.Request.uri req in
            let path, meth = Uri.path uri, Cohttp.Request.meth req in
            match HandlerMap.find t meth path with
            | Supported (path_handler, path_regex_match) ->
                path_handler req path_regex_match
            | Unsupported code ->
                Cohttp_async.Server.respond_with_string ~code
                    (Cohttp.Code.string_of_status code)
        in
        Cohttp_async.Server.create ~on_handler_error:`Raise
            (Tcp.on_port port) handler 
        >>| ignore |> don't_wait_for
end
