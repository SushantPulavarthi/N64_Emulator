const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;

// 64 bit MIPS r4300i chip
const CPU = struct {
    // R0 - R31
    pub var registers: [32]u64 = undefined;

    // Floating Point Registers
    pub var FPregisters: [32]f64 = undefined;
    // Floating-point control registers
    // Implementation/Revision
    pub var FCR0: f32 = undefined;
    // Control / Status
    pub var FCR31: f32 = undefined;

    const allocator = std.heap.page_allocator;

    // Todo: Can be configured to use 32 or 64 bit addresses
    pub var PC: u64 = undefined;

    // Multiply and Divide registers
    pub var HI: u64 = undefined;
    pub var LO: u64 = undefined;

    // Load / Link Register
    pub var LLBit: u1 = undefined;

    var mode64: bool = undefined;

    pub fn initCPU() !void {
        registers = try allocator.allocate(u64, 32);
        FPregisters = try allocator.allocate(f64, 32);
    }

    pub fn deinitCPU() !void {
        allocator.free(registers);
        allocator.free(FPregisters);
    }

    // First Register, R0, is hardwired to 0
    pub fn readRegister(idx: usize) u64 {
        return if (idx == 0) 0 else registers[idx];
    }
};
