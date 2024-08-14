const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;
const panic = std.debug.panic;

const Bus = @import("bus.zig").Bus;
const Cp0 = @import("cp0.zig").Cp0;
const Cp1 = @import("cp1.zig").Cp1;
const Instructions = @import("instructions.zig");

const TLBEntry = packed struct {
    pagemask: packed struct {
        mask: u12,
    },
    entry_hi: packed struct {
        r: u2,
        vpn2: u27,
        g: u1,
        asid: u8,
    },
    entry_lo0: packed struct {
        pfn: u20,
        c: u3,
        d: u1,
        v: u1,
    },
    entry_lo1: packed struct {
        pfn: u20,
        c: u3,
        d: u1,
        v: u1,
    },
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
        _ = self;
        // 32 Bit mode address translation
        // const offset =

        return switch (address & 0xFFFF_FFFF) {
            // KUSEG TLB
            0x0000_0000...0x7FFF_FFFF => undefined,
            // KSEG0 Direct Map, cache
            0x8000_0000...0x9FFF_FFFF => address - 0x8000_0000,
            // KSEG1 Direct Map, non cache
            0xA000_0000...0xBFFF_FFFF => address - 0xA000_0000,
            // KSSEG TLB
            0xC000_0000...0xDFFF_FFFF => undefined,
            // KSEG3 TLB
            0xE000_0000...0xFFFF_FFFF => undefined,
            else => panic("Unrecognized Virtual Address: {X}\n", .{address}),
        };
    }

    // fn tlbTranslate(self: *Cpu, vAddr: u64) u64 {
    //     const cp0Index = self.cp0.registers[]
    //     for (self.TLBEntries) |entry| {
    //         if (!entry.entry_hi.g or entry.entry_hi.vpn2 != (vAddr >> 13)) {
    //             continue;
    //         }
    //
    //
    //
    //         switch (entry.pagemask.mask) {
    //             0x000 => {
    //                 // 4KB Page
    //             },
    //             0x003 => {
    //                 // 16KB Page
    //             },
    //             0x00F => {
    //                 // 64KB Page
    //             },
    //             0x03F => {
    //                 // 256KB Page
    //             },
    //             0x0FF => {
    //                 // 1MB Page
    //             },
    //             0x03FF => {
    //                 // 4MB Page
    //             },
    //             0x0FFF => {
    //                 // 16MB Page
    //             },
    //             else => {
    //                 panic("Undefined page size");
    //             },
    //         }
    //     }
    // }

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
