const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;

pub const Cp1 = struct {
    registers: []f64,

    pub fn init(allocator: std.mem.Allocator) !Cp1 {
        return Cp1{
            .registers = try allocator.alloc(f64, 32),
        };
    }

    pub fn deinit(self: *Cp1, allocator: std.mem.Allocator) void {
        allocator.free(self.registers);
    }
};
