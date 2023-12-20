const std = @import("std");
pub const memsimd = @import("memsimd");

const iteration_times = 1_000_000;
var rand_impl = std.rand.DefaultPrng.init(0);
const testing_types: [8]type = [8]type{
    u8,
    i8,
    u16,
    i16,
    u32,
    i32,
    u64,
    i64,
};
const GeneratedNum = struct {
    len: usize,
    num: *void,
    num_copy: *void,
    guaranteed_unequal: *void,

    // [0] = num, [1] = num_copy, [2] = guaranteed_unequal
    fn cast(self: *const GeneratedNum, comptime T: type) [3][]T {
        var num: []T = undefined;
        num.ptr = @as([*]T, @alignCast(@ptrCast(self.num)));
        num.len = self.len;
        var num_copy: []T = undefined;
        num_copy.ptr = @as([*]T, @alignCast(@ptrCast(self.num_copy)));
        num_copy.len = self.len;
        var guaranteed_unequal: []T = undefined;
        guaranteed_unequal.ptr = @as([*]T, @alignCast(@ptrCast(self.guaranteed_unequal)));
        guaranteed_unequal.len = self.len;

        return .{ num, num_copy, guaranteed_unequal };
    }

    fn gen(comptime T: type, allocator: std.mem.Allocator, min_length: usize, max_length: usize) !GeneratedNum {
        const strlen = rand_impl.random().intRangeAtMost(usize, min_length, max_length);
        var num = try allocator.alloc(T, strlen);
        var num_copy = try allocator.alloc(T, strlen);
        var guaranteed_unequal = try allocator.alloc(T, strlen);
        for (0..strlen) |randnum_idx| {
            num[randnum_idx] = rand_impl.random().intRangeAtMost(T, std.math.minInt(T), std.math.maxInt(T));
            num_copy[randnum_idx] = num[randnum_idx];
            guaranteed_unequal[randnum_idx] = std.math.minInt(T);
        }

        // This ensures that the num_arr3 isn't equal to num_arr1 and num_arr2
        if (std.mem.eql(T, num, guaranteed_unequal)) {
            return gen(T, allocator, min_length, max_length);
        }

        return GeneratedNum{ .num = @ptrCast(num.ptr), .num_copy = @ptrCast(num_copy.ptr), .guaranteed_unequal = @ptrCast(guaranteed_unequal.ptr), .len = strlen };
    }
};

pub fn test_function(eql: anytype, random_nums: [testing_types.len]std.ArrayList(GeneratedNum)) !void {
    inline for (testing_types, 0..) |T, idx| {
        for (random_nums[idx].items) |generated_num_untyped| {
            // [0] = num, [1] = num_copy, [2] = guaranteed_unequal
            const generated_num = generated_num_untyped.cast(T);
            try std.testing.expect(eql(T, generated_num[0], generated_num[1]));
            try std.testing.expect(!eql(T, generated_num[0], generated_num[2]));
        }
    }
}

test "Eql functions" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    const allocator = arena.allocator();
    var random_nums: [testing_types.len]std.ArrayList(GeneratedNum) = undefined;
    for (0..testing_types.len) |idx| {
        random_nums[idx] = std.ArrayList(GeneratedNum).init(allocator);
    }
    defer {
        for (0..testing_types.len) |idx| {
            random_nums[idx].deinit();
        }
        arena.deinit();
    }

    for (0..iteration_times) |_| {
        inline for (testing_types, 0..) |T, type_idx| {
            const randnum = try GeneratedNum.gen(T, allocator, 1, 40);
            try random_nums[type_idx].append(randnum);
        }
    }

    try test_function(memsimd.avx.eql, random_nums);
    try test_function(memsimd.nosimd.eql, random_nums);
    try test_function(memsimd.sse2.eql, random_nums);
    try test_function(memsimd.sse4.eql, random_nums);
}
