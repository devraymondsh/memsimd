const sse42 = @import("sse42.zig");
const builtin = @import("builtin");

extern fn asm_avx_check() bool;
extern fn asm_avx_eql(ptr1: *const anyopaque, ptr2: *const anyopaque, off: usize) bool;
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
    return asm_avx_check();
}

/// Equality check of a and b using AVX instructions without:
/// 1: Checking the length of a and b (ensure they're equal)
/// 2: Checking if a and b point to the same location
/// 3: Checking if the length of a and b are zero
/// 4: Checking if the first elements are equal without any special instruction (for faster unsuccessful checks)
pub fn eql_nocheck(comptime T: type, a: []const T, b: []const T) bool {
    const rem: usize = a.len & 0x1f;
    const len: usize = a.len -% rem;

    var off: usize = 0;
    while (off < len) : (off +%= 32) {
        if (!asm_avx_eql(a.ptr, b.ptr, off)) {
            return false;
        }
    }
    if (rem != 0) {
        if (!sse42.eql_nocheck(T, a.ptr[off..a.len], b.ptr[off..b.len])) {
            return false;
        }
    }

    return true;
}
/// Equality check of a and b using AVX instructions
pub fn eql(comptime T: type, a: []const T, b: []const T) bool {
    if (a.len != b.len) return false;
    if (a.ptr == b.ptr) return true;
    if (a.len == 0 or b.len == 0) return true;
    if (a[0] != b[0]) return false;

    return eql_nocheck(T, a, b);
}
