const builtin = @import("builtin");
const nosimd = @import("nosimd.zig");
const common = @import("common.zig");

extern fn asm_sve_eql(ptr1: [*]const u8, ptr2: [*]const u8, off: usize) bool;
comptime {
    asm (
        \\asm_sve_eql:
        \\      ldr     q1, [x0, x2]
        \\      ldr     q0, [x1, x2]
        \\      cmeq    v0.16b, v0.16b, v1.16b
        \\      umaxv   b0, v0.16b
        \\      umov    w0, v0.b[0]
        \\      tst     w0, 255
        \\      cset    w0, eq
        \\      ret
    );
}

/// Equality check of a and b (a, b are bytes) using sve instructions (16 bytes at a time) without:
/// 1: Checking the length of a and b (ensure they're equal)
/// 2: Checking if a and b point to the same location
/// 3: Checking if the length of a and b are zero
/// 4: Checking if the first elements are equal without any special instruction (for faster unsuccessful checks)
pub fn eql_byte_nocheck(a: []const u8, b: []const u8) bool {
    @setRuntimeSafety(false);

    const rem: usize = a.len & 0xf;
    const len: usize = a.len -% rem;

    var off: usize = 0;
    while (off != len) : (off +%= 16) {
        if (!asm_sve_eql(a.ptr, b.ptr, off)) {
            return false;
        }
    }
    if (rem != 0) {
        if (!nosimd.eql_nocheck(u8, a.ptr[off..a.len], b.ptr[off..b.len])) {
            return false;
        }
    }

    return true;
}
/// Equality check of a and b using sve instructions (16 bytes at a time) without:
/// 1: Checking the length of a and b (ensure they're equal)
/// 2: Checking if a and b point to the same location
/// 3: Checking if the length of a and b are zero
/// 4: Checking if the first elements are equal without any special instruction (for faster unsuccessful checks)
pub fn eql_nocheck(comptime T: type, a: []const T, b: []const T) bool {
    @setRuntimeSafety(false);
    return @call(.always_inline, eql_byte_nocheck, .{
        @as([*]const u8, @ptrCast(a.ptr))[0 .. a.len *% @sizeOf(T)],
        @as([*]const u8, @ptrCast(b.ptr))[0 .. b.len *% @sizeOf(T)],
    });
}
/// Equality check of a and b using sve instructions (16 bytes at a time)
pub fn eql(comptime T: type, a: []const T, b: []const T) bool {
    @setRuntimeSafety(false);

    if (a.len != b.len) return false;
    if (a.ptr == b.ptr) return true;
    if (a.len == 0) return true;
    if (common.if_scalar_unequal(T, a[0], b[0])) return false;

    return @call(.always_inline, eql_nocheck, .{ T, a, b });
}
