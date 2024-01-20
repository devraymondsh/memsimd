const builtin = @import("builtin");
const common = @import("common.zig");

/// SSE4.2 support check
pub fn check() bool {
    @setRuntimeSafety(false);
    return asm (
        \\.att_syntax
        \\mov    $0, %ecx
        \\mov    $1, %eax
        \\cpuid  
        \\mov    %ecx, %eax
        \\shr    $20, %eax
        \\and    $1, %eax
        : [ret] "={eax}" (-> bool),
    );
}

extern fn _sse42_asm_eql(ptr1: [*]const u8, ptr2: [*]const u8, len: usize, off: usize) bool;
comptime {
    asm (
        \\.intel_syntax noprefix
        \\
        ++ common.underscore_prefix("sse42_asm_eql:\n") ++
            " movdqu  xmm0, xmmword ptr [" ++ common.arg1_reg ++ " + " ++ common.arg4_reg ++ "]\n" ++
            " movdqu  xmm1, xmmword ptr [" ++ common.arg2_reg ++ " + " ++ common.arg4_reg ++ "]\n" ++
            " mov rax, " ++ common.arg3_reg ++ "\n" ++
            " mov rdx, " ++ common.arg3_reg ++ "\n" ++
            \\ pcmpestri  xmm0, xmm1, 24
            \\ setae      al
            \\ ret
    );
}

/// Equality check of a and b (a, b are bytes) using SSE4.2 instructions (16 bytes at a time) without:
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
        if (!_sse42_asm_eql(a.ptr, b.ptr, 16, off)) {
            return false;
        }
    }
    if (rem != 0) {
        if (!_sse42_asm_eql(a.ptr, b.ptr, rem, off)) {
            return false;
        }
    }

    return true;
}
/// Equality check of a and b using SSE4.2 instructions (16 bytes at a time) without:
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
/// Equality check of a and b using SSE4.2 instructions (16 bytes at a time)
pub fn eql(comptime T: type, a: []const T, b: []const T) bool {
    @setRuntimeSafety(false);

    if (a.len != b.len) return false;
    if (a.ptr == b.ptr) return true;
    if (a.len == 0) return true;
    if (common.if_scalar_unequal(T, a, b)) return false;

    return @call(.always_inline, eql_nocheck, .{ T, a, b });
}
