const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;
const panic = std.debug.panic;

const Cpu = @import("cpu.zig").Cpu;
const Bus = @import("bus.zig").Bus;
const Cop0 = @import("cop0.zig").Cop0;
const Cop1 = @import("cop1.zig").Cop1;

fn bootProcess(cpu: *Cpu, cop0: *Cop0) !void {
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

const ROM_SIZE = 80000;

const N64 = struct {
    cpu: Cpu = undefined,
    bus: Bus = undefined,
    alloc: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !N64 {
        print("Initializing N64!\n", .{});
        return N64{
            .alloc = allocator,
            .bus = try Bus.init(allocator),
            .cpu = try Cpu.init(allocator),
        };
    }

    pub fn run(self: *N64) !void {
        print("{d}\n", .{self.cpu.gpr});

        print("{d}\n", .{self.cpu.readRegister(0)});
        print("{d}\n", .{self.cpu.readRegister(10)});
    }

    pub fn deinit(self: *N64) void {
        self.cpu.deinit();
        self.bus.deinit();
    }
};

pub fn main() !void {
    // Loading specified rom
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var argsIterator = try std.process.argsWithAllocator(allocator);
    defer argsIterator.deinit();

    // Ignore executable
    _ = argsIterator.next();

    const romPath = argsIterator.next();
    assert(romPath != null);
    print("Path: {s}\n", .{romPath.?});

    // Rom files are in big endian
    const romFile = try std.fs.cwd().openFile(romPath.?, .{});
    defer romFile.close();

    var buffer: [ROM_SIZE]u8 = undefined;
    const bytes_read = try romFile.readAll(&buffer);
    assert(bytes_read == ROM_SIZE);

    // for (buffer, 0..) |byte, i| {
    //     print("{d}: {x:0>4}\n", .{ i, byte });
    //     if (i == 100) {
    //         break;
    //     }
    // }

    var n64 = try N64.init(allocator);
    defer n64.deinit();
    n64.run() catch |err| {
        print("{}\n", .{err});
    };
}
