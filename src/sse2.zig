const nosimd = @import("nosimd.zig");
const builtin = @import("builtin");
const common = @import("common.zig");

extern fn asm_sse2_check() bool;
extern fn asm_sse2_eql(ptr1: [*]const u8, ptr2: [*]const u8, off: usize) bool;
comptime {
    asm (
        \\.intel_syntax noprefix
        \\asm_sse2_check:
        \\        push    1
        \\        pop     rax
        \\        xchg    edi, ebx
        \\        cpuid
        \\        xchg    edi, ebx
        \\        mov     eax, edx
        \\        shr     eax, 26
        \\        and     eax, 1
        \\        ret
    );
    if (builtin.os.tag == .windows) {
        // rcx, rdx, r8, r9
        asm (
            \\.intel_syntax noprefix
            \\asm_sse2_eql:
            \\        movups  xmm0, [rcx + r8]
            \\        movups  xmm1, [rdx + r8]
            \\        pcmpeqb xmm0, xmm1
            \\        pmovmskb rax, xmm0
            \\        cmp     ax, -1
            \\        sete    al
            \\        movzx   rax, al
            \\        ret
        );
    } else {
        // rdi, rsi, rdx, rcx
        asm (
            \\.intel_syntax noprefix
            \\asm_sse2_eql:
            \\        movups  xmm0, [rdi + rdx]
            \\        movups  xmm1, [rsi + rdx]
            \\        pcmpeqb xmm0, xmm1
            \\        pmovmskb rax, xmm0
            \\        cmp     ax, -1
            \\        sete    al
            \\        movzx   rax, al
            \\        ret
        );
    }
}

/// SSE2 support check
pub fn check() bool {
    @setRuntimeSafety(false);
    return asm_sse2_check();
}

/// Equality check of a and b (a, b are bytes) using SSE2 instructions (16 bytes at a time) without:
/// 1: Checking the length of a and b (ensure they're equal)
/// 2: Checking if a and b point to the same location
/// 3: Checking if the length of a and b are zero
/// 4: Checking if the first elements are equal without any special instruction (for faster unsuccessful checks)
pub fn eql_byte_nocheck(a: []const u8, b: []const u8) bool {
    @setRuntimeSafety(false);

    const rem: usize = a.len & 0xf;
    const len: usize = a.len -% rem;

    var off: usize = 0;
    while (off < len) : (off +%= 16) {
        if (!asm_sse2_eql(a.ptr, b.ptr, off)) {
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
/// Equality check of a and b using SSE2 instructions (16 bytes at a time) without:
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
/// Equality check of a and b using SSE2 instructions (16 bytes at a time)
pub fn eql(comptime T: type, a: []const T, b: []const T) bool {
    @setRuntimeSafety(false);

    if (a.len != b.len) return false;
    if (a.ptr == b.ptr) return true;
    if (a.len == 0) return true;
    if (common.if_scalar_unequal(T, a[0], b[0])) return false;

    return @call(.always_inline, eql_nocheck, .{ T, a, b });
}
