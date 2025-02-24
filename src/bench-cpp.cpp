#include <iostream>
#include <vector>
#include <thread>
#include <atomic>
#include <chrono>

const size_t SIEVE_SIZE = 1000000;
const size_t SQRT_LIMIT = 1000;

std::atomic<size_t> counter(0);

// Forward declaration
void sieve_of_eratosthenes();

void worker(int timeout) {
    auto start = std::chrono::steady_clock::now();
    while (std::chrono::duration_cast<std::chrono::seconds>(
           std::chrono::steady_clock::now() - start).count() < timeout) {
        sieve_of_eratosthenes();
        counter++;
    }
}

void sieve_of_eratosthenes() {
    std::vector<bool> sieve(SIEVE_SIZE, true);
    sieve[0] = sieve[1] = false;
    
    for (size_t i = 2; i < SQRT_LIMIT; i++) {
        if (sieve[i]) {
            for (size_t j = i * i; j < SIEVE_SIZE; j += i) {
                sieve[j] = false;
            }
        }
    }
}

int main(int argc, char* argv[]) {
    if (argc != 5 || std::string(argv[1]) == "--help") {
        std::cout << "usage: bench-cpp --timeout <sec> --mp <n-cores>" << std::endl;
        return 1;
    }
    
    int timeout = std::stoi(argv[2]);
    int n_cores = std::stoi(argv[4]);
    
    std::vector<std::thread> threads;
    threads.reserve(n_cores);
    
    for (int i = 0; i < n_cores; i++) {
        threads.push_back(std::thread(worker, timeout));
    }
    
    for (std::thread& t : threads) {
        t.join();
    }
    
    std::cout << "-- Operations performed: " << counter.load() << std::endl;
    return 0;
} 