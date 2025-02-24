package main

import (
    "flag"
    "fmt"
    "sync"
    "sync/atomic"
    "time"
)

func worker(counter *uint64, timeout int) {
    start := time.Now()
    for time.Since(start).Seconds() < float64(timeout) {
        sieve := make([]bool, 1000000)
        for i := range sieve {
            sieve[i] = true
        }
        sieve[0], sieve[1] = false, false
        
        for i := 2; i < 1000; i++ {
            if sieve[i] {
                for j := i * i; j < 1000000; j += i {
                    sieve[j] = false
                }
            }
        }
        atomic.AddUint64(counter, 1)
    }
}

func main() {
    timeout := flag.Int("timeout", 0, "timeout in seconds")
    mp := flag.Int("mp", 0, "number of cores")
    flag.Parse()
    
    if *timeout == 0 || *mp == 0 {
        fmt.Println("usage: bench-go --timeout <sec> --mp <n-cores>")
        return
    }
    
    var counter uint64
    var wg sync.WaitGroup
    
    for i := 0; i < *mp; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            worker(&counter, *timeout)
        }()
    }
    
    wg.Wait()
    fmt.Printf("-- Operations performed: %d\n", counter)
} 