const builtin = @import("builtin");

comptime {
    if (builtin.cpu.arch != .aarch64 and builtin.cpu.arch != .aarch64_be and builtin.cpu.arch != .aarch64_32 and builtin.cpu.arch != .x86_64) {
        @compileError("This library only supports x86_64 and aarch64 processors!");
    }
}

pub const avx512 = @import("avx512.zig");
pub const avx = @import("avx.zig");
pub const nosimd = @import("nosimd.zig");
pub const sse2 = @import("sse2.zig");
pub const sse42 = @import("sse42.zig");
