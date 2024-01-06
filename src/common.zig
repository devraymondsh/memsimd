const builtin = @import("builtin");

// NOTE: x86_64 only
// POSIX register order: rdi, rsi, rdx, rcx
// Windows register order: rcx, rdx, r8, r9
pub const arg1_reg = if (builtin.target.os.tag != .windows) "rdi" else "rcx";
pub const arg2_reg = if (builtin.target.os.tag != .windows) "rsi" else "rdx";
pub const arg3_reg = if (builtin.target.os.tag != .windows) "rdx" else "r8";
pub const arg4_reg = if (builtin.target.os.tag != .windows) "rcx" else "r9";

// Make sure the prefix an underscore for names if the target is not Macos
pub fn underscore_prefix(comptime name: []const u8) []const u8 {
    comptime {
        if (builtin.target.os.tag != .macos) {
            return "_" ++ name;
        } else {
            return name;
        }
    }
}

/// Checks if two scalar types are uneqal. If two scalar types are unequal it'll return true.
/// if two scalar types are equal or if it's not a scalar type it'll return false.
pub inline fn if_scalar_unequal(comptime T: type, left: []const T, right: []const T) bool {
    if (@typeInfo(T) == .Float or @typeInfo(T) == .Int) {
        if (left[0] != right[0]) {
            return true;
        }
    }
    return false;
}
