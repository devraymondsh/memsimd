const nosimd = @import("nosimd.zig");

extern fn asm_sse4_eql(arg1: *const anyopaque, arg2: *const anyopaque, len: usize, off: usize) bool;
comptime {
    asm (
        \\.intel_syntax noprefix
        \\asm_sse4_eql:
        \\  mov         rax, rdx
        \\  movdqu      xmm0, xmmword ptr [rdi + rcx]
        \\  movdqu      xmm1, xmmword ptr [rsi + rcx]
        \\  pcmpestri   xmm0, xmm1, 24
        \\  setae       al
        \\  ret
    );
}
pub fn eql_nocheck(comptime T: type, a: []const T, b: []const T) bool {
    const rem: usize = a.len & 0xf;
    const len: usize = a.len -% rem;

    var off: usize = 0;
    while (off != len) : (off +%= 16) {
        if (!asm_sse4_eql(a.ptr, b.ptr, 16, off)) {
            return false;
        }
    }
    if (rem != 0) {
        if (!nosimd.eql_nocheck(T, a.ptr[off..a.len], b.ptr[off..b.len])) {
            return false;
        }
        // if (!asm_sse4_eql(a.ptr, b.ptr, rem, off)) {
        //     return false;
        // }
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
