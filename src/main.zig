const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;
const panic = std.debug.panic;

const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const Cpu = @import("cpu.zig").Cpu;
const Bus = @import("bus.zig").Bus;
const Cp0 = @import("cp0.zig").Cp0;
const Cp1 = @import("cp1.zig").Cp1;
const Rsp = @import("rsp.zig").Rsp;

const WIDTH = 320;
const HEIGHT = 240;
const SCREEN_SCALE = 2;
const WINDOWFLAGS = c.SDL_WINDOW_SHOWN | c.SDL_WINDOW_RESIZABLE;

const N64 = struct {
    cpu: Cpu,
    bus: Bus,
    alloc: std.mem.Allocator,

    cp0: Cp0,
    cp1: Cp1,
    rsp: Rsp,

    screen: *c.SDL_Window,
    renderer: *c.SDL_Renderer,

    pub fn init(allocator: std.mem.Allocator, screen: *c.SDL_Window, renderer: *c.SDL_Renderer, romPath: []const u8) !N64 {
        print("Initializing N64!\n", .{});
        return N64{
            .alloc = allocator,
            .bus = try Bus.init(allocator, romPath),
            .cpu = try Cpu.init(allocator),
            .cp0 = try Cp0.init(allocator),
            .cp1 = try Cp1.init(allocator),
            .rsp = try Rsp.init(allocator),
            .screen = screen,
            .renderer = renderer,
        };
    }

    pub fn run(self: *N64) !void {
        print("{d}\n", .{self.cpu.reg_gpr});

        print("{d}\n", .{self.cpu.readRegister(0)});
        print("{d}\n", .{self.cpu.readRegister(10)});

        // for (0..80000) |i| {
        //     print("{d}: {x:0>4}\n", .{ i, self.bus.rom[i] });
        //     if (i == 100) {
        //         break;
        //     }
        // }

        const running = true;
        while (running) {
            // var event: c.SDL_Event = undefined;
            // while (c.SDL_PollEvent(&event) != 0) {
            //     switch (event.type) {
            //         c.SDL_QUIT => running = false,
            //         else => {},
            //     }
            // }

            self.cpu.emulator_loop();

            // c.SDL_RenderPresent(self.renderer);
        }
    }

    fn bootProcess(self: *N64) void {
        self.cpu.bus = &self.bus;
        self.cpu.cp0 = &self.cp0;

        self.bus.rsp = &self.rsp;

        @memcpy(self.rsp.DMEM, self.bus.rom[0..0x1000]);
    }

    pub fn deinit(self: *N64, allocator: std.mem.Allocator) void {
        self.cpu.deinit(allocator);
        self.bus.deinit(allocator);
        self.cp0.deinit(allocator);
        self.cp1.deinit(allocator);
        self.rsp.deinit(allocator);
    }
};

pub fn main() !void {
    // Loading specified rom
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var argsIterator = try std.process.argsWithAllocator(allocator);
    defer argsIterator.deinit();

    // Ignore executable
    _ = argsIterator.next();

    const romPath = argsIterator.next();
    assert(romPath != null);
    print("Path: {s}\n", .{romPath.?});

    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        c.SDL_Log("Unable to initialise SDL: %s", c.SDL_GetError());
    }
    const screen = c.SDL_CreateWindow(
        "N64 Emulator",
        c.SDL_WINDOWPOS_UNDEFINED,
        c.SDL_WINDOWPOS_UNDEFINED,
        WIDTH * SCREEN_SCALE,
        HEIGHT * SCREEN_SCALE,
        WINDOWFLAGS,
    ) orelse {
        c.SDL_Log("Unable to create window: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };

    const renderer = c.SDL_CreateRenderer(screen, -1, c.SDL_RENDERER_ACCELERATED) orelse {
        c.SDL_Log("Unable to create renderer: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };

    var n64 = try N64.init(allocator, screen, renderer, romPath.?);
    n64.bootProcess();
    n64.cp0.registers[3] = 3;

    // for (0..1000) |i| {
    //     print("{X} ", .{n64.rsp.DMEM[i]});
    //     if (i % 8 == 0) {
    //         print("\n", .{});
    //     }
    // }

    defer n64.deinit(allocator);
    n64.run() catch |err| {
        print("{}\n", .{err});
    };

    print("Reg {d} {X} \n", .{ 22, n64.cpu.readRegister(22) });
    print("Reg {d} {X} \n", .{ 29, n64.cpu.readRegister(29) });

    print("{d}\n", .{n64.bus.rom[100]});
    print("{d}\n", .{n64.cpu.bus.rom[100]});

    n64.bus.ram[100] = 10;
    print("{d}\n", .{n64.bus.ram[100]});
    print("{d}\n", .{n64.cpu.bus.ram[100]});

    print("{d}\n", .{n64.cp0.registers[3]});
    print("{d}\n", .{n64.cp0.registers[12]});
    print("{d}\n", .{n64.cp0.registers[27]});

    c.SDL_DestroyRenderer(renderer);
    c.SDL_DestroyWindow(screen);
    c.SDL_Quit();
}
