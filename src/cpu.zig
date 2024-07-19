const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;

// 64 bit MIPS r4300i chip
const CPU = struct {
    pub var registers: [32]u64 = undefined;
    const allocator = std.heap.page_allocator;

    // Todo: Can be configured to use 32 or 64 bit addresses
    pub var PC: u64 = undefined;

    pub fn initCPU() !void {
        registers = try allocator.allocate(u64, 32);
    }

    pub fn deinitCPU() !void {
        allocator.free(registers);
    }

    // First Register, R0, is hardwired to 0
    pub fn readRegister(idx: usize) u64 {
        return if (idx == 0) 0 else registers[idx];
    }
};
