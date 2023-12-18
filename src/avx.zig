const sse4 = @import("sse4.zig");

extern fn asm_avx_eql(str1: *const anyopaque, str2: *const anyopaque, offset: usize) bool;
comptime {
    asm (
        \\.intel_syntax noprefix
        \\asm_avx_eql:
        \\        vmovups ymm0, [rdi + rdx]
        \\        vmovups ymm1, [rsi + rdx]
        \\        vpcmpeqb ymm0, ymm0, ymm1
        \\        vpmovmskb eax, ymm0
        \\        cmp     ax, -1
        \\        sete    al
        \\        movzx   eax, al
        \\        vzeroupper
        \\        ret
    );
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
