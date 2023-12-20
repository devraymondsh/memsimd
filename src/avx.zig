const sse4 = @import("sse4.zig");
const builtin = @import("builtin");

extern fn asm_avx_eql(ptr1: *const anyopaque, ptr2: *const anyopaque, off: usize) bool;
comptime {
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
        if (!sse4.eql_nocheck(T, a.ptr[off..a.len], b.ptr[off..b.len])) {
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
