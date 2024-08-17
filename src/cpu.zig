const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;
const panic = std.debug.panic;

const Bus = @import("bus.zig").Bus;
const Cp0 = @import("cp0.zig").Cp0;
const Cp1 = @import("cp1.zig").Cp1;
const Instructions = @import("instructions.zig");

const Entry_lo = packed struct {
    pfn: u20,
    c: u3,
    d: u1,
    v: u1,
};

const TLBEntry = packed struct {
    pagemask: packed struct {
        mask: u12,
    },
    entry_hi: packed struct {
        r: u2,
        vpn2: u27,
        g: bool,
        asid: u8,
    },
    entry_lo0: Entry_lo,
    entry_lo1: Entry_lo,
};

// 64 bit MIPS r4300i chip
pub const Cpu = struct {
    // R0 - R31
    // General Purpose Registers
    // r0 = 0, r31 = link address
    reg_gpr: []u64,
    // Floating Point Registers
    // r0 = Implementation/Revision
    // r31 = Control/Status
    reg_fpr: []f64,

    // Todo: Can be configured to use 32 or 64 bit addresses
    PC: u64 = 0,
    nextPC: u64,

    // Multiply and Divide registers
    HI: u64 = 0,
    LO: u64 = 0,

    TLBEntries: [32]TLBEntry,

    // Load / Link Register
    LLBit: u1 = 0,

    mode64: bool = true,

    loadDelay: u64 = 0,

    bus: *Bus = undefined,
    cp0: *Cp0 = undefined,
    cp1: *Cp1 = undefined,

    pub fn init(allocator: std.mem.Allocator) !Cpu {
        const reg_gpr = try allocator.alloc(u64, 32);
        @memset(reg_gpr, 0);
        errdefer allocator.free(reg_gpr);

        const reg_fpr = try allocator.alloc(f64, 32);
        @memset(reg_fpr, 0);
        errdefer allocator.free(reg_fpr);

        // Simulating PIF Rom
        reg_gpr[11] = 0xFFFF_FFFF_A400_0040;
        reg_gpr[20] = 0x0000_0000_0000_0001;
        reg_gpr[22] = 0x0000_0000_0000_003F;
        reg_gpr[29] = 0xFFFF_FFFF_A400_1FF0;

        return Cpu{
            .reg_gpr = reg_gpr,
            .reg_fpr = reg_fpr,
            .PC = 0xA400_0040,
            .nextPC = 0xA400_0044,
            .TLBEntries = undefined,
        };
    }

    fn handleOpcode(self: *Cpu, opcode: u32) void {
        print("Opcode Recieved: {x:0>8}\n", .{opcode});
        Instructions.decodeInstruction(self, opcode);
        self.PC += 4;
    }

    // Memory accesses by main CPU, instruction fetched and load/store instructions use virtual addresses
    pub fn virtualToPhysical(self: *Cpu, address: u64) u64 {
        // 32 Bit mode address translation
        // const offset =

        return switch (address & 0xFFFF_FFFF) {
            // // KSEG0 Direct Map, cache
            // 0x8000_0000...0x9FFF_FFFF => address - 0x8000_0000,
            // // KSEG1 Direct Map, non cache
            // 0xA000_0000...0xBFFF_FFFF => address - 0xA000_0000,
            // // KUSEG TLB
            // 0x0000_0000...0x7FFF_FFFF => tlbTranslate(self, address),
            // // KSSEG TLB
            // 0xC000_0000...0xDFFF_FFFF => tlbTranslate(self, address),
            // // KSEG3 TLB
            // 0xE000_0000...0xFFFF_FFFF => tlbTranslate(self, address),
            0x8000_0000...0xBFFF_FFFF => address & 0x1FFF_FFFF,
            0x0000_0000...0x7FFF_FFFF, 0xC000_0000...0xFFFF_FFFF => tlbTranslate(self, address),
            else => panic("Unrecognized Virtual Address: {X}\n", .{address}),
        };
    }

    fn tlbTranslate(self: *Cpu, vAddr: u64) u64 {
        const asid = self.cp0.registers[10] & 0xFF;
        for (self.TLBEntries) |entry| {
            // Either ASID has to match or  global bit set
            if (!entry.entry_hi.g and entry.entry_hi.asid != asid) {
                continue;
            }

            // const bitCount = @popCount(entry.pagemask.mask);
            // const mask = (0xFFFFFFE >> bitCount) << (12 + bitCount);
            //
            // // VPN Comparison
            // if (entry.entry_hi.vpn2 != (vAddr & mask)) {
            //     continue;
            // }

            const vpnMask = 0xFFFE0000 | @as(u32, @intCast(~entry.pagemask.mask));

            if (entry.entry_hi.vpn2 & vpnMask != (vAddr >> 13) & vpnMask) {
                continue;
            }

            // R Comparison
            if (entry.entry_hi.r != (vAddr >> 62)) {
                continue;
            }

            const pageSize = (@as(u24, entry.pagemask.mask) << 12 | 0x0FFF) + 1;
            var entryLo: Entry_lo = undefined;
            if (vAddr & pageSize == 0) {
                entryLo = entry.entry_lo0;
            } else {
                entryLo = entry.entry_lo1;
            }

            if (entryLo.v == 1) {
                continue;
            }

            return entryLo.pfn << 6 | (vAddr & (@as(u24, entry.pagemask.mask) << 12 | 0xFFF));
        }
        return 0;
    }

    pub fn emulatorLoop(self: *Cpu) void {
        print("PC: {X}\n", .{self.PC});
        const opcode = self.read(self.PC, u32);
        self.PC = self.nextPC;
        self.nextPC +%= 4;
        self.handleOpcode(opcode);
    }

    pub fn deinit(self: *Cpu, allocator: std.mem.Allocator) void {
        allocator.free(self.reg_gpr);
        allocator.free(self.reg_fpr);
    }

    // First Register, R0, is hardwired to 0
    pub fn readRegister(self: *Cpu, idx: usize) u64 {
        return if (idx == 0) 0 else self.reg_gpr[idx];
    }

    pub fn read(self: *Cpu, vAddr: u64, comptime T: type) T {
        const pAddr = self.virtualToPhysical(vAddr);
        return self.bus.read(pAddr, T);
    }
};
