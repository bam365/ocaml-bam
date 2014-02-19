open Core.Std
open Async.Std

let handler ~body:_ _ sock req =
    let uri = Cohttp.Request.uri req in
    if (Uri.path uri) = "/test" then
        let a = Uri.get_query_param uri "hello" in
        let b = Option.map ~f:(fun v-> "hello: " ^ v) a in
        let c = Option.value ~default:"No param hello supplied" b in
        Cohttp_async.Server.respond_with_string c
    else
        Cohttp_async.Server.respond_with_string ~code:`Not_found
            "Route not found"


let () =
    Cohttp_async.Server.create ~on_handler_error:`Raise
        (Tcp.on_port 8080) handler >>| ignore |> don't_wait_for;
    Scheduler.go () |> never_returns
