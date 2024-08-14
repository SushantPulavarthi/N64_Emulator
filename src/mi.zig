const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;
const panic = std.debug.panic;

const Mi = struct {
    MI_INTR_REG: u64,
    MI_INTR_MASK_REG: u64,
};
