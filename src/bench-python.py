#!/usr/bin/env python3
import time
import multiprocessing as mp
import argparse
from multiprocessing import Value

SIEVE_SIZE = 1_000_000
SQRT_LIMIT = 1_000

def worker(counter, timeout):
    start = time.time()
    while time.time() - start < timeout:
        sieve_of_eratosthenes()
        with counter.get_lock():
            counter.value += 1

def sieve_of_eratosthenes():
    sieve = [True] * SIEVE_SIZE
    sieve[0] = sieve[1] = False
    
    for i in range(2, SQRT_LIMIT):
        if sieve[i]:
            for j in range(i * i, SIEVE_SIZE, i):
                sieve[j] = False

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--timeout', type=int, required=True)
    parser.add_argument('--mp', type=int, required=True)
    args = parser.parse_args()
    
    counter = Value('i', 0)
    processes = []
    for _ in range(args.mp):
        p = mp.Process(target=worker, args=(counter, args.timeout))
        processes.append(p)
        p.start()
    
    for p in processes:
        p.join()
    
    print(f"-- Operations performed: {counter.value}")

if __name__ == '__main__':
    main() 