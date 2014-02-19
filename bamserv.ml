open Core.Std
open Async.Std

let () =
    Bam_http.Server.create ()
    |> Bam_http.Server.add_handler ~path:"/test" ~handler:(fun _ _ -> 
            Cohttp_async.Server.respond_with_file "test.html")
    |> Bam_http.Server.run_on_port ~port:8080 ;
    Scheduler.go () |> never_returns
