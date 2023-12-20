const std = @import("std");
pub const memsimd = @import("memsimd");

pub fn main() !void {
    const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Please enter the iteration number. Leave empty for default(one million).\n", .{});

    // Get the maximum_iteration from stdin
    var maximum_iterations: usize = 1_000_000;
    var stdin_buf: [20]u8 = undefined;
    const stdin = std.io.getStdIn().reader();
    if (stdin.readUntilDelimiter(&stdin_buf, '\n')) |user_input| {
        maximum_iterations = std.fmt.parseInt(usize, user_input, 10) catch 1_000_000;
    } else |_| {}

    // Setup allocators and random number generator
    var rand_impl = std.rand.DefaultPrng.init(0);
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    const allocator = arena.allocator();
    defer {
        arena.deinit();
        _ = gpa.deinit();
    }

    // Generate fake strings. Here are two different ArrayLists with two different
    // allocations in order to prevent the strings from being the in same memory address
    // which would ruin the whole point of this benchmark.
    var string_array1 = std.ArrayList([]u8).init(allocator);
    var string_array2 = std.ArrayList([]u8).init(allocator);
    try stdout.print("Generating random strings...\n", .{});
    for (0..maximum_iterations) |_| {
        const strlen = rand_impl.random().intRangeAtMost(usize, 1, 1024);

        var allocated_str1 = try allocator.alloc(u8, strlen);
        var allocated_str2 = try allocator.alloc(u8, strlen);
        for (0..strlen) |randstr_idx| {
            allocated_str1[randstr_idx] = charset[rand_impl.random().intRangeAtMost(usize, 0, charset.len - 1)];
            allocated_str2[randstr_idx] = allocated_str1[randstr_idx];
        }
        try string_array1.append(allocated_str1);
        try string_array2.append(allocated_str2);
    }

    const nosimd_start_time = std.time.milliTimestamp();
    for (string_array1.items, 0..) |item, idx| {
        if (!memsimd.nosimd.eql(u8, item, string_array2.items[idx])) {
            std.debug.panic("Wrong comparison!\n", .{});
        }
        if (memsimd.nosimd.eql(u8, item, "@@@@@@@@@@@@@@@@@@@@@")) {
            std.debug.panic("Wrong comparison!\n", .{});
        }
    }
    const nosimd_elapsed_time = std.time.milliTimestamp() - nosimd_start_time;

    const sse2_start_time = std.time.milliTimestamp();
    for (string_array1.items, 0..) |item, idx| {
        if (!memsimd.sse2.eql(u8, item, string_array2.items[idx])) {
            std.debug.panic("Wrong comparison!\n", .{});
        }
        if (memsimd.sse2.eql(u8, item, "@@@@@@@@@@@@@@@@@@@@@")) {
            std.debug.panic("Wrong comparison!\n", .{});
        }
    }
    const sse2_elapsed_time = std.time.milliTimestamp() - sse2_start_time;

    const sse4_start_time = std.time.milliTimestamp();
    for (string_array1.items, 0..) |item, idx| {
        if (!memsimd.sse42.eql(u8, item, string_array2.items[idx])) {
            std.debug.panic("Wrong comparison!\n", .{});
        }
        if (memsimd.sse42.eql(u8, item, "@@@@@@@@@@@@@@@@@@@@@")) {
            std.debug.panic("Wrong comparison!\n", .{});
        }
    }
    const sse4_elapsed_time = std.time.milliTimestamp() - sse4_start_time;

    const avx_start_time = std.time.milliTimestamp();
    for (string_array1.items, 0..) |item, idx| {
        if (!memsimd.avx.eql(u8, item, string_array2.items[idx])) {
            std.debug.panic("Wrong comparison!\n", .{});
        }
        if (memsimd.avx.eql(u8, item, "@@@@@@@@@@@@@@@@@@@@@")) {
            std.debug.panic("Wrong comparison!\n", .{});
        }
    }
    const avx_elapsed_time = std.time.milliTimestamp() - avx_start_time;

    try stdout.print("No SIMD strcmp took: {any}ms\n", .{nosimd_elapsed_time});
    try stdout.print("SSE2 strcmp took: {any}ms\n", .{sse2_elapsed_time});
    try stdout.print("SS4.2 strcmp took: {any}ms\n", .{sse4_elapsed_time});
    try stdout.print("AVX strcmp took: {any}ms\n", .{avx_elapsed_time});
}
