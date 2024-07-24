const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;

const RAM_SIZE = 4 * 1024 * 1024;

// 4MiB of RDRAM
// Uses 9 bits, 9th bit for parity checking
// All memory accesses must be aligned
pub const Bus = struct {
    ram: []u8,
    RAMParity: []u1,

    allocator: std.mem.Allocator,

    // Memory accesses by main CPU, instruction fetched and load/store instructions use virtual addresses
    fn virtualToPhysical(self: *Bus, address: u64) u64 {
        _ = self;
        return switch (address) {
            // KUSEG
            0x0000_0000...0x7FFF_FFFF => undefined,
            // KSEG 0
            0x8000_0000...0x9FFF_FFFF => address - 0x8000_0000,
            // KSEG 1
            0xA000_0000...0xBFFF_FFFF => address = 0xA000_0000,
            // KSSEG
            0xC000_0000...0xDFFF_FFFF => undefined,
            // KSEG 3
            0xE000_0000...0xFFFF_FFFF => undefined,
        };
    }

    fn rdpRead(self: *Bus, address: u32) u32 {
        const segmentID = (address >> 24) & 0x1111;
        const segmentOffset = address & (2 ^ 24 - 1);
        const physicalAddr = segmentOffset + segmentID;
        return self.ram[physicalAddr];
    }

    fn read8() u8 {}
    fn read16() u16 {}
    fn read32() u32 {}
    fn read64() u64 {}

    fn write8() !void {}
    fn write16() !void {}
    fn write32() !void {}
    fn write64() !void {}

    pub fn init(allocator: std.mem.Allocator) !Bus {
        const ram = try allocator.alloc(u8, RAM_SIZE);
        errdefer allocator.free(ram);
        const RAMParity = try allocator.alloc(u1, RAM_SIZE);
        errdefer allocator.free(RAMParity);
        return Bus{
            .allocator = allocator,
            .ram = ram,
            .RAMParity = RAMParity,
        };
    }

    pub fn deinit(self: *Bus) void {
        self.allocator.free(self.ram);
        self.allocator.free(self.RAMParity);
    }
};
