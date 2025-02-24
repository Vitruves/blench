const std = @import("std");
const Atomic = std.atomic.Value;
const Thread = std.Thread;

var counter = Atomic(usize).init(0);

const SIEVE_SIZE: usize = 1_000_000;
const SQRT_LIMIT: usize = 1_000;

fn worker(timeout: u64) void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var sieve = arena.allocator().alloc(bool, SIEVE_SIZE) catch unreachable;
    
    const start = std.time.timestamp();
    while (std.time.timestamp() - start < timeout) {
        @memset(sieve, true);
        sieve[0] = false;
        sieve[1] = false;
        
        var i: usize = 2;
        while (i < SQRT_LIMIT) : (i += 1) {
            if (sieve[i]) {
                var j: usize = i * i;
                while (j < SIEVE_SIZE) : (j += i) {
                    sieve[j] = false;
                }
            }
        }
        _ = counter.fetchAdd(1, .monotonic);
    }
}

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);
    
    if (args.len != 5 or std.mem.eql(u8, args[1], "--help")) {
        std.debug.print("usage: bench_zig --timeout <sec> --mp <n-cores>\n", .{});
        return;
    }
    
    const timeout = try std.fmt.parseInt(u64, args[2], 10);
    const n_cores = try std.fmt.parseInt(usize, args[4], 10);
    
    var threads = try std.ArrayList(Thread).initCapacity(std.heap.page_allocator, n_cores);
    defer threads.deinit();
    
    var i: usize = 0;
    while (i < n_cores) : (i += 1) {
        const thread = try Thread.spawn(.{}, worker, .{timeout});
        try threads.append(thread);
    }
    
    for (threads.items) |thread| {
        thread.join();
    }
    
    std.debug.print("-- Operations performed: {}\n", .{counter.load(.monotonic)});
} 