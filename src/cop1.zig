const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;

const COP1 = struct {
    pub var registers: [32]u32 = undefined;
};
