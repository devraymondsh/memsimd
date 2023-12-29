const sse42 = @import("sse42.zig");
const builtin = @import("builtin");
const common = @import("common.zig");

extern fn asm_avx_check() bool;
extern fn asm_avx_eql(ptr1: [*]const u8, ptr2: [*]const u8, off: usize) bool;
comptime {
    asm (
        \\.intel_syntax noprefix
        \\asm_avx_check:
        \\        push    1
        \\        pop     rax
        \\        xchg    edi, ebx
        \\        cpuid
        \\        xchg    edi, ebx
        \\        mov     eax, ecx
        \\        not     ecx
        \\        test    ecx, 402653184
        \\        jne    osxsave
        \\        xor     ecx, ecx
        \\        xgetbv
        \\        not     eax
        \\        test    al, 6
        \\        sete    al
        \\        ret
        \\osxsave:
        \\        shr     eax, 28
        \\        and     al, 1
        \\        ret
    );
    if (builtin.os.tag == .windows) {
        // rcx, rdx, r8, r9
        asm (
            \\.intel_syntax noprefix
            \\asm_avx_eql:
            \\        vmovups ymm0, [rcx + r8]
            \\        vmovups ymm1, [rdx + r8]
            \\        vpcmpeqb ymm0, ymm0, ymm1
            \\        vpmovmskb rax, ymm0
            \\        cmp     ax, -1
            \\        sete    al
            \\        movzx   rax, al
            \\        vzeroupper
            \\        ret
        );
    } else {
        // rdi, rsi, rdx, rcx
        asm (
            \\.intel_syntax noprefix
            \\asm_avx_eql:
            \\        vmovups ymm0, [rdi + rdx]
            \\        vmovups ymm1, [rsi + rdx]
            \\        vpcmpeqb ymm0, ymm0, ymm1
            \\        vpmovmskb rax, ymm0
            \\        cmp     ax, -1
            \\        sete    al
            \\        movzx   rax, al
            \\        vzeroupper
            \\        ret
        );
    }
}

/// AVX support check
pub fn check() bool {
    @setRuntimeSafety(false);
    return asm_avx_check();
}

/// Equality check of a and b (a, b are bytes) using AVX instructions (32 bytes at a time) without:
/// 1: Checking the length of a and b (ensure they're equal)
/// 2: Checking if a and b point to the same location
/// 3: Checking if the length of a and b are zero
/// 4: Checking if the first elements are equal without any special instruction (for faster unsuccessful checks)
pub fn eql_byte_nocheck(a: []const u8, b: []const u8) bool {
    @setRuntimeSafety(false);

    const rem: usize = a.len & 0x1f;
    const len: usize = a.len -% rem;

    var off: usize = 0;
    while (off < len) : (off +%= 32) {
        if (!asm_avx_eql(a.ptr, b.ptr, off)) {
            return false;
        }
    }
    if (rem != 0) {
        if (!sse42.eql_byte_nocheck(a.ptr[off..a.len], b.ptr[off..b.len])) {
            return false;
        }
    }

    return true;
}
/// Equality check of a and b using AVX instructions (32 bytes at a time) without:
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
/// Equality check of a and b using AVX instructions (32 bytes at a time)
pub fn eql(comptime T: type, a: []const T, b: []const T) bool {
    @setRuntimeSafety(false);

    if (a.len != b.len) return false;
    if (a.ptr == b.ptr) return true;
    if (a.len == 0) return true;
    if (common.if_scalar_unequal(T, a[0], b[0])) return false;

    return @call(.always_inline, eql_nocheck, .{ T, a, b });
}
