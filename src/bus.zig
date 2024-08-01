const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;
const panic = std.debug.panic;

const RAM_SIZE = 4 * 1024 * 1024;
const ROM_SIZE = 80000;

const Rsp = @import("rsp.zig").Rsp;

// 4MiB of RDRAM
// Uses 9 bits, 9th bit for parity checking
// All memory accesses must be aligned
pub const Bus = struct {
    ram: []u8,
    RAMParity: []u1,

    rom: [ROM_SIZE]u8,
    rsp: *Rsp = undefined,

    fn rdpRead(self: *Bus, address: u32) u32 {
        const segmentID = (address >> 24) & 0x1111;
        const segmentOffset = address & (2 ^ 24 - 1);
        const physicalAddr = segmentOffset + segmentID;
        return self.ram[physicalAddr];
    }

    // From n64.readthedocs.io
    // 0x0000_0000 0x003F_FFFF RDRAM built in
    // 0x0040_0000 0x007F_FFFF RDRAM expansion pak (if inserted)
    // 0x0080_0000 0x003E_FFFF Unused Unused
    // 0x03F0_0000 0x003F_FFFF RDRAM MMIO (timings, etc) - irrelevant
    //
    // 0x0400_0000 0x0400_0FFF SP DMEM RSP Data Memory
    // 0x0400_1000 0x0400_1FFF SP DMEM RSP Instruction Memory
    // 0x0400_2000 0x0400_3FFF Unused Unused
    //
    // 0x0404_0000 0x040F_FFFF SP Registers Control RSP DMA engine, status, PC
    // 0x0410_0000 0x041F_FFFF DP Command Registers Send Commands to RDP
    // 0x0420_0000 0x042F_FFFF DP Span Registers Unknown?
    // 0x0430_0000 0x043F_FFFF MIPS Interface (MI) System information, interrupts
    // 0x0440_0000 0x044F_FFFF Video Interface (VI) Screen resolution, framebuffer settings
    // 0x0450_0000 0x045F_FFFF Audio Interface (AI) Control Audio Subsystem
    // 0x0460_0000 0x046F_FFFF Peripheral Interface (PI) Control cartridge interface, set up DMAs Cart <==> RDRAM
    // 0x0470_0000 0x047F_FFFF RDRAM Interface (RI) Control RDRAM settings (timings)? - Irrelevant
    // 0x0480_0000 0x048F_FFFF Serial Interface (SI) Control PIF RAM <==> RDRAM DMA engined
    // 0x0490_0000 0x049F_FFFF Unused Unused
    // 0x0500_0000 0x05FF_FFFF Cartridge Domain 2 Address 1 N64DDD Control registers (returns open bus (all 0xFF) when not present)
    // 0x0600_0000 0x07FF_FFFF Cartridge Domain 1 Address 1 SRAM is mapped here
    // 0x0800_0000 0x0FFF_FFFF Cartridge Domain 2 Address 2 ROM is mapped here
    // 0x1FC0_0000 0x1FC0_07BF PIF Boot Rom
    // 0x1FC0_07C0 0x1FC0_07BF PIF Ram Used to communicate with PIF Chip (controllers, memory cards)
    // 0x1FC0_0800 0x1FCF_FFFF Reserved
    // 0x1FD0_0000 0x7FFF_FFFF Cartridge Domain 1 Address 3
    // 0x8000_0000 0xFFFF_FFFF Unknown Unknown?

    pub fn read32(self: *Bus, address: u64) u32 {
        switch (address) {
            0x0400_0000...0x0400_0FFF => return self.rsp.read(address - 0x0400_0000, u32),
            else => panic("Unhandled address: {x}\n", .{address}),
        }
    }

    pub fn read(self: *Bus, address: u64, comptime T: type) T {
        switch (address) {
            // Both rsp DMEM and IMEM
            0x0400_0000...0x0400_1FFF => return self.rsp.read(address - 0x0400_0000, T),
            else => panic("Unhandled address: {x}\n", .{address}),
        }
    }

    pub fn write8() !void {}
    pub fn write16() !void {}
    pub fn write32() !void {}
    pub fn write64() !void {}

    pub fn init(allocator: std.mem.Allocator, romPath: []const u8) !Bus {
        const ram = try allocator.alloc(u8, RAM_SIZE);
        errdefer allocator.free(ram);
        const RAMParity = try allocator.alloc(u1, RAM_SIZE);
        errdefer allocator.free(RAMParity);

        // Rom files are in big endian
        const romFile = try std.fs.cwd().openFile(romPath, .{});
        defer romFile.close();

        var rom: [ROM_SIZE]u8 = undefined;
        const bytes_read = try romFile.readAll(&rom);
        print("Read {d} bytes", .{bytes_read});
        assert(bytes_read == ROM_SIZE);

        return Bus{
            .ram = ram,
            .RAMParity = RAMParity,
            .rom = rom,
        };
    }

    pub fn deinit(self: *Bus, allocator: std.mem.Allocator) void {
        allocator.free(self.ram);
        allocator.free(self.RAMParity);
    }
};
