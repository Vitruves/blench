package bench;

import java.util.concurrent.atomic.AtomicLong;
import java.util.concurrent.CountDownLatch;

public class BenchJava {
    private static final int SIEVE_SIZE = 1_000_000;
    private static final int SQRT_LIMIT = 1_000;
    private static final AtomicLong counter = new AtomicLong(0);
    
    static class Worker implements Runnable {
        private final int timeout;
        private final CountDownLatch latch;
        
        Worker(int timeout, CountDownLatch latch) {
            this.timeout = timeout;
            this.latch = latch;
        }
        
        @Override
        public void run() {
            long startTime = System.currentTimeMillis() / 1000;
            while ((System.currentTimeMillis() / 1000) - startTime < timeout) {
                sieveOfEratosthenes();
                counter.incrementAndGet();
            }
            latch.countDown();
        }
    }
    
    private static void sieveOfEratosthenes() {
        boolean[] sieve = new boolean[SIEVE_SIZE];
        java.util.Arrays.fill(sieve, true);
        sieve[0] = sieve[1] = false;
        
        for (int i = 2; i < SQRT_LIMIT; i++) {
            if (sieve[i]) {
                for (int j = i * i; j < SIEVE_SIZE; j += i) {
                    sieve[j] = false;
                }
            }
        }
    }
    
    public static void main(String[] args) {
        if (args.length != 4 || args[0].equals("--help")) {
            System.out.println("usage: java bench.BenchJava --timeout <sec> --mp <n-cores>");
            System.exit(1);
        }
        
        int timeout = Integer.parseInt(args[1]);
        int nCores = Integer.parseInt(args[3]);
        
        CountDownLatch latch = new CountDownLatch(nCores);
        Thread[] threads = new Thread[nCores];
        
        for (int i = 0; i < nCores; i++) {
            threads[i] = new Thread(new Worker(timeout, latch));
            threads[i].start();
        }
        
        try {
            latch.await();
        } catch (InterruptedException e) {
            System.err.println("Interrupted");
            System.exit(1);
        }
        
        System.out.println("-- Operations performed: " + counter.get());
    }
} 