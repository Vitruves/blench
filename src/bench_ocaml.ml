open Unix

let counter = ref 0
let mutex = Mutex.create ()

let sieve_size = 1_000_000
let sqrt_limit = 1_000

let sieve_of_eratosthenes () =
  let sieve = Array.make sieve_size true in
  sieve.(0) <- false;
  sieve.(1) <- false;
  for i = 2 to sqrt_limit - 1 do
    if sieve.(i) then
      for j = i * i to sieve_size - 1 do
        sieve.(j) <- false
      done
  done

let worker timeout =
  let start_time = Unix.time () in
  while Unix.time () -. start_time < float_of_int timeout do
    sieve_of_eratosthenes ();
    Mutex.lock mutex;
    incr counter;
    Mutex.unlock mutex
  done

let () =
  if Array.length Sys.argv <> 5 || Sys.argv.(1) = "--help" then begin
    Printf.printf "usage: bench_ocaml --timeout <sec> --mp <n-cores>\n";
    exit 1
  end;
  let timeout = int_of_string Sys.argv.(2) in
  let n_cores = int_of_string Sys.argv.(4) in
  let threads = Array.init n_cores (fun _ ->
    Thread.create worker timeout
  ) in
  Array.iter Thread.join threads;
  Printf.printf "-- Operations performed: %d\n" !counter