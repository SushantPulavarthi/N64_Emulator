const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;

// 4MiB of RDRAM
// Uses 9 bits, 9th bit for parity checking
// All memory accesses must be aligned
const MEMORY = struct {
    pub const ram = []u8;
    pub const ramParity = []u1;

    // Memory accesses by main CPU, instruction fetched and load/store instructions use virtual addresses
    fn virtualToPhysical(address: u64) u64 {
        return switch (address) {
            // KUSEG
            0x0000_0000...0x7FFF_FFFF => undefined,
            // KSEG 0
            0x8000_0000...0x9FFF_FFFF => ram[address - 0x8000_0000],
            // KSEG 1
            0xA000_0000...0xBFFF_FFFF => ram[address - 0xA000_0000],
            // KSSEG
            0xC000_0000...0xDFFF_FFFF => undefined,
            // KSEG 3
            0xE000_0000...0xFFFF_FFFF => undefined,
        };
    }

    fn rdpRead(address: u32) u32 {
        const segmentID = (address >> 24) & 0x1111;
        const segmentOffset = address & (2 ^ 24 - 1);
        const physicalAddr = segmentOffset + segmentID;
        return ram[physicalAddr];
    }

    fn read8() u8 {}
    fn read16() u16 {}
    fn read32() u32 {}
    fn read64() u64 {}

    fn write8() !void {}
    fn write16() !void {}
    fn write32() !void {}
    fn write64() !void {}

    const allocator = std.heap.page_allocator;

    fn initMemory() !void {
        ram = try allocator.alloc(u8, 80000);
        ramParity = try allocator.alloc(u8, 80000);
    }

    fn deinitMemory() !void {
        allocator.free(ram);
        allocator.free(ramParity);
    }
};
