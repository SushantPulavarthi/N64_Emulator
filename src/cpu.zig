const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;

// 64 bit MIPS r4300i chip
pub const Cpu = struct {
    // R0 - R31
    gpr: []u64,
    // Floating Point Registers
    fpr: []f64,

    // Floating-point control registers
    // Implementation/Revision
    FCR0: f32 = 0,
    // Control / Status
    FCR31: f32 = 0,

    // Todo: Can be configured to use 32 or 64 bit addresses
    PC: u64 = 0,

    // Multiply and Divide registers
    HI: u64 = 0,
    LO: u64 = 0,
    loadDelay: u64 = 0,

    // Load / Link Register
    LLBit: u1 = 0,

    mode64: bool = true,

    allocator: std.mem.Allocator = undefined,

    pub fn init(allocator: std.mem.Allocator) !Cpu {
        const gpr = try allocator.alloc(u64, 32);
        @memset(gpr, 0);
        errdefer allocator.free(gpr);

        const fpr = try allocator.alloc(f64, 32);
        @memset(fpr, 0);
        errdefer allocator.free(fpr);

        return Cpu{
            .allocator = allocator,

            .gpr = gpr,
            .fpr = fpr,
        };
    }

    pub fn deinit(self: *Cpu) void {
        self.allocator.free(self.gpr);
        self.allocator.free(self.fpr);
    }

    // First Register, R0, is hardwired to 0
    pub fn readRegister(self: *Cpu, idx: usize) u64 {
        return if (idx == 0) 0 else self.gpr[idx];
    }
};
