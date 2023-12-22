const nosimd = @import("nosimd.zig");
const builtin = @import("builtin");

extern fn asm_sse42_check() bool;
extern fn asm_sse42_eql(ptr1: [*]const u8, ptr2: [*]const u8, len: usize, off: usize) bool;
comptime {
    asm (
        \\.intel_syntax noprefix
        \\asm_sse42_check:
        \\        push    1
        \\        pop     rax
        \\        xchg    edi, ebx
        \\        cpuid
        \\        xchg    edi, ebx
        \\                mov     eax, ecx
        \\        shr     eax, 20
        \\        and     eax, 1
        \\        ret
    );
    if (builtin.os.tag == .windows) {
        // rcx, rdx, r8, r9
        asm (
            \\.intel_syntax noprefix
            \\asm_sse42_eql:
            \\  mov         rax, r8
            \\  movdqu      xmm0, xmmword ptr [rcx + r9]
            \\  movdqu      xmm1, xmmword ptr [rdx + r9]
            \\  pcmpestri   xmm0, xmm1, 24
            \\  setae       al
            \\  ret
        );
    } else {
        // rdi, rsi, rdx, rcx
        asm (
            \\.intel_syntax noprefix
            \\asm_sse42_eql:
            \\  mov         rax, rdx
            \\  movdqu      xmm0, xmmword ptr [rdi + rcx]
            \\  movdqu      xmm1, xmmword ptr [rsi + rcx]
            \\  pcmpestri   xmm0, xmm1, 24
            \\  setae       al
            \\  ret
        );
    }
}

/// SSE4.2 support check
pub fn check() bool {
    @setRuntimeSafety(false);
    return asm_sse42_check();
}

/// Equality check of a and b (a, b are bytes) using SSE4.2 instructions without without:
/// 1: Checking the length of a and b (ensure they're equal)
/// 2: Checking if a and b point to the same location
/// 3: Checking if the length of a and b are zero
/// 4: Checking if the first elements are equal without any special instruction (for faster unsuccessful checks)
pub fn eql_byte(a: []const u8, b: []const u8) bool {
    @setRuntimeSafety(false);

    const rem: usize = a.len & 0xf;
    const len: usize = a.len -% rem;

    var off: usize = 0;
    while (off != len) : (off +%= 16) {
        if (!asm_sse42_eql(a.ptr, b.ptr, 16, off)) {
            return false;
        }
    }
    if (rem != 0) {
        if (!asm_sse42_eql(a.ptr, b.ptr, rem, off)) {
            return false;
        }
    }

    return true;
}
/// Equality check of a and b using SSE4.2 instructions without:
/// 1: Checking the length of a and b (ensure they're equal)
/// 2: Checking if a and b point to the same location
/// 3: Checking if the length of a and b are zero
/// 4: Checking if the first elements are equal without any special instruction (for faster unsuccessful checks)
pub fn eql_nocheck(comptime T: type, a: []const T, b: []const T) bool {
    @setRuntimeSafety(false);
    return @call(.always_inline, eql_byte, .{
        @as([*]const u8, @ptrCast(a.ptr))[0 .. a.len *% @sizeOf(T)],
        @as([*]const u8, @ptrCast(b.ptr))[0 .. b.len *% @sizeOf(T)],
    });
}
/// Equality check of a and b using SSE4.2 instructions
pub fn eql(comptime T: type, a: []const T, b: []const T) bool {
    @setRuntimeSafety(false);

    if (a.len != b.len) return false;
    if (a.ptr == b.ptr) return true;
    if (a.len == 0 or b.len == 0) return true;
    if (a[0] != b[0]) return false;

    return @call(.always_inline, eql_nocheck, .{ T, a, b });
}
