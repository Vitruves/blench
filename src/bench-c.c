#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <pthread.h>
#include <time.h>
#include <stdatomic.h>

#define SIEVE_SIZE 1000000
#define SQRT_LIMIT 1000

atomic_size_t counter = 0;

// Forward declaration
void sieve_of_eratosthenes(void);

struct worker_args {
    int timeout;
};

void* worker(void* arg) {
    struct worker_args* args = (struct worker_args*)arg;
    time_t start = time(NULL);
    
    while (time(NULL) - start < args->timeout) {
        sieve_of_eratosthenes();
        atomic_fetch_add(&counter, 1);
    }
    
    return NULL;
}

void sieve_of_eratosthenes() {
    bool* sieve = malloc(SIEVE_SIZE * sizeof(bool));
    memset(sieve, true, SIEVE_SIZE * sizeof(bool));
    sieve[0] = sieve[1] = false;
    
    for (int i = 2; i < SQRT_LIMIT; i++) {
        if (sieve[i]) {
            for (int j = i * i; j < SIEVE_SIZE; j += i) {
                sieve[j] = false;
            }
        }
    }
    free(sieve);
}

int main(int argc, char* argv[]) {
    if (argc != 5 || strcmp(argv[1], "--help") == 0) {
        printf("usage: bench-c --timeout <sec> --mp <n-cores>\n");
        return 1;
    }
    
    int timeout = atoi(argv[2]);
    int n_cores = atoi(argv[4]);
    
    pthread_t* threads = malloc(n_cores * sizeof(pthread_t));
    struct worker_args args = {timeout};
    
    for (int i = 0; i < n_cores; i++) {
        pthread_create(&threads[i], NULL, worker, &args);
    }
    
    for (int i = 0; i < n_cores; i++) {
        pthread_join(threads[i], NULL);
    }
    
    printf("-- Operations performed: %zu\n", counter);
    
    free(threads);
    return 0;
} 