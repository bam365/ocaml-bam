open Core.Std
open Async.Std

let () =
    Bam_http.Server.create ()
    |> Bam_http.Server.serve_file ~path:"/test" ~filename:"test.html"
    |> Bam_http.Server.run_on_port ~port:8080 ;
    Scheduler.go () |> never_returns
