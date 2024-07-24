const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;

pub const Cop1 = struct {
    registers: [32]u32,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !Cop1 {
        const registers = allocator.alloc(u32, 32);
        errdefer allocator.free(registers);

        return Cop1{
            .registers = registers,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Cop1) void {
        self.allocator.free(self.registers);
    }
};
