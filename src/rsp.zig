const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;
const panic = std.debug.panic;

pub const Rsp = struct {
    registers: []u32,

    // Vector Unit (VU) available as COP2
    // Memory accesses are physical (no virtual)
    // Memory access onoly to DMEM
    // Can access unaligned values

    PC: u12 = 0,
    DMEM: []u8,
    IMEM: []u8,

    pub fn init(allocator: std.mem.Allocator) !Rsp {
        return Rsp{
            .registers = try allocator.alloc(u32, 32),
            .DMEM = try allocator.alloc(u8, 4 * 1024),
            .IMEM = try allocator.alloc(u8, 4 * 1024),
        };
    }

    pub fn deinit(self: *Rsp, allocator: std.mem.Allocator) void {
        allocator.free(self.registers);
        allocator.free(self.DMEM);
        allocator.free(self.IMEM);
    }

    pub fn read_registers(self: *Rsp, idx: usize) u32 {
        return switch (idx) {
            0 => 0,
            else => self.registers[idx],
        };
    }

    pub fn read(self: *Rsp, addr: u64, comptime T: type) T {
        const count = switch (T) {
            u8 => 0,
            u16 => 1,
            u32 => 3,
            u64 => 7,
            else => panic("Non valid type {}", .{type}),
        };
        const relAddr = if (addr > 1000) addr - 1000 else addr;
        // for (0..4) |i| {
        //     print("{X}\n", .{self.DMEM[relAddr + i]});
        // }
        return std.mem.readInt(T, @ptrCast(self.DMEM[relAddr .. relAddr + count]), .big);
    }
};
