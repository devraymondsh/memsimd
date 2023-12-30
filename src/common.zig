fn is_scalar(comptime T: type) bool {
    if (@typeInfo(T) == .Float or @typeInfo(T) == .Int) {
        return true;
    } else {
        false;
    }
}

/// Checks if two scalar types are uneqal. If two scalar types are unequal it'll return true.
/// if two scalar types are equal or if it's not a scalar type it'll return false.
pub inline fn if_scalar_unequal(comptime T: type, left: []const T, right: []const T) bool {
    if (is_scalar(T)) {
        if (left[0] != right[0]) {
            return true;
        }
    }
    return false;
}
