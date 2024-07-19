const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;

const CPU = @import("cpu.zig").CPU;
const MEMORY = @import("memory.zig").MEMORY;
const COP0 = @import("cop0.zig").COP0;
const COP1 = @import("cop1.zig").COP1;

fn bootProcess(cpu: *CPU, cop0: *COP0) !void {
    // PIF Rom Simulation - used to initialize hardware and boot program on cartridge
    cpu.registers[11] = 0xFFFF_FFFF_A400_0040;
    cpu.registers[20] = 0x0000_0000_0000_0001;
    cpu.registers[22] = 0x0000_0000_0000_003F;
    cpu.registers[29] = 0xFFFF_FFFF_A400_1FF0;

    cop0.registers[1] = 0x0000001F;
    cop0.registers[12] = 0x34000000;
    cop0.registers[15] = 0x00000B00;
    cop0.registers[16] = 0x0006E463;

    // TODO: First 0x1000 bytes from cartridge copied into SP DMEM
    // Copy of first 0x1000 bytes from 0xB000_0000 to 0xA400_0000

    cpu.PC = 0xA400_0040;
}

pub fn main() !void {}
