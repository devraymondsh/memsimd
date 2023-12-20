const nosimd = @import("nosimd.zig");
const builtin = @import("builtin");

extern fn asm_sse2_eql(ptr1: *const anyopaque, ptr2: *const anyopaque, off: usize) bool;
comptime {
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

pub fn eql_nocheck(comptime T: type, a: []const T, b: []const T) bool {
    const rem: usize = a.len & 0xf;
    const len: usize = a.len -% rem;

    var off: usize = 0;
    while (off < len) : (off +%= 16) {
        if (!asm_sse2_eql(a.ptr, b.ptr, off)) {
            return false;
        }
    }
    if (rem != 0) {
        if (!nosimd.eql_nocheck(T, a.ptr[off..a.len], b.ptr[off..b.len])) {
            return false;
        }
    }

    return true;
}
pub fn eql(comptime T: type, a: []const T, b: []const T) bool {
    if (a.len != b.len) return false;
    if (a.ptr == b.ptr) return true;
    if (a.len == 0 or b.len == 0) return true;
    if (a[0] != b[0]) return false;

    return eql_nocheck(T, a, b);
}
