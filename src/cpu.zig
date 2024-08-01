const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;
const panic = std.debug.panic;

const Bus = @import("bus.zig").Bus;

const TLBEntry = struct {};

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

    // Multiply and Divide registers
    HI: u64 = 0,
    LO: u64 = 0,

    TLBEntries: [32]TLBEntry = undefined,

    // Load / Link Register
    LLBit: u1 = 0,

    mode64: bool = true,

    loadDelay: u64 = 0,

    bus: *Bus = undefined,

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
            // .TLBEntries = [32]TLBEntry{},
        };
    }

    fn handleOpcode(self: *Cpu, opcode: u32) void {
        print("Opcode Recieved: {x:0>8}\n", .{opcode});
        switch (opcode) {
            else => {
                print("Unhandled Opcode {x:0>8}\n", .{opcode});
                panic("Unhandled Opcode {b:0>32}\n", .{opcode});
            },
        }
        self.PC += 4;
    }

    // Memory accesses by main CPU, instruction fetched and load/store instructions use virtual addresses
    fn virtualToPhysical(self: *Cpu, address: u64) u64 {
        _ = self;
        // 32 Bit mode address translation
        // const offset =

        return switch (address) {
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
            else => panic("Unrecognized Virtual Address: {x}\n", .{address}),
        };
    }

    pub fn emulator_loop(self: *Cpu) void {
        print("PC: {x}\n", .{self.PC});
        const physAddr = self.virtualToPhysical(self.PC);
        print("PhysAddr: {x}\n", .{physAddr});
        const opcode = self.bus.read(physAddr, u32);
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
};
