#!/usr/bin/env julia

using Base.Threads

const SIEVE_SIZE = 1_000_000

function sieve_of_eratosthenes()
    sieve = fill(true, SIEVE_SIZE + 1)  # +1 to handle 0-based indexing
    sieve[1] = false  # 0 and 1 are not prime
    sieve[2] = false
    
    for i in 3:isqrt(SIEVE_SIZE + 1)
        if sieve[i]
            for j in (i*i):i:(SIEVE_SIZE + 1)
                sieve[j] = false
            end
        end
    end
    
    # Count primes (to ensure same work as other languages)
    prime_count = count(sieve[2:end])  # Skip 0 and 1
    return nothing
end

function main()
    if length(ARGS) != 4 || ARGS[1] != "--timeout" || ARGS[3] != "--mp"
        println("usage: bench-julia --timeout <sec> --mp <n-cores>")
        exit(1)
    end
    
    timeout = parse(Int, ARGS[2])
    n_cores = parse(Int, ARGS[4])
    
    # Set number of threads
    if n_cores > 1
        JULIA_NUM_THREADS = n_cores
    end
    
    counter = Atomic{Int}(0)
    start_time = time()
    
    # Create tasks for each thread
    tasks = []
    for _ in 1:nthreads()
        push!(tasks, @spawn begin
            while (time() - start_time) < timeout
                sieve_of_eratosthenes()
                atomic_add!(counter, 1)
            end
        end)
    end
    
    # Wait for all tasks
    for t in tasks
        wait(t)
    end
    
    println("-- Operations performed: ", counter[])
end

main() 