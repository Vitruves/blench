use std::env;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::Arc;
use std::thread;
use std::time::Instant;

const SIEVE_SIZE: usize = 1_000_000;
const SQRT_LIMIT: usize = 1_000;  // sqrt of SIEVE_SIZE

fn sieve_of_eratosthenes() {
    let mut sieve = vec![true; SIEVE_SIZE];
    sieve[0] = false;
    sieve[1] = false;
    
    for i in 2..SQRT_LIMIT {
        if sieve[i] {
            let mut j = i * i;
            while j < SIEVE_SIZE {
                sieve[j] = false;
                j += i;
            }
        }
    }
}

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() != 5 || args[1] == "--help" {
        println!("usage: bench-rust --timeout <sec> --mp <n-cores>");
        return;
    }
    
    let timeout = args[2].parse::<u64>().unwrap();
    let n_cores = args[4].parse::<usize>().unwrap();
    
    let counter = Arc::new(AtomicUsize::new(0));
    let start = Instant::now();
    let mut handles = vec![];
    
    for _ in 0..n_cores {
        let counter = Arc::clone(&counter);
        handles.push(thread::spawn(move || {
            while start.elapsed().as_secs() < timeout {
                sieve_of_eratosthenes();
                counter.fetch_add(1, Ordering::Relaxed);
            }
        }));
    }
    
    for handle in handles {
        handle.join().unwrap();
    }
    
    println!("-- Operations performed: {}", counter.load(Ordering::Relaxed));
} 