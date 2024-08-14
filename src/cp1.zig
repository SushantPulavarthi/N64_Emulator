const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;

const Cp0 = @import("cp0.zig").Cp0;

pub const Cp1 = struct {
    registers: []f64,
    condition_signal: bool = false,

    cp0: Cp0 = undefined,

    pub fn init(allocator: std.mem.Allocator) !Cp1 {
        return Cp1{
            .registers = try allocator.alloc(f64, 32),
        };
    }

    pub fn deinit(self: *Cp1, allocator: std.mem.Allocator) void {
        allocator.free(self.registers);
    }

    pub fn set32(self: *Cp1, index: usize, value: u32) void {
        const val64: u64 = @intCast(value);
        if ((self.cp0.registers[12] >> 26) & 1 == 1) {
            self.registers[index] = @as(f64, @bitCast(val64));
        } else {
            if ((index & 1) == 0) {
                self.registers[index] = @as(f64, @bitCast(val64));
            } else {
                self.registers[index - 1] = @as(f64, @bitCast(val64 << 32));
            }
        }
    }

    pub fn get32(self: *Cp1, index: usize) u32 {
        var data: u32 = undefined;
        if ((self.cp0.registers[12] >> 26) & 1 == 1) {
            data = @truncate(@as(u64, @bitCast(self.registers[index])));
        } else {
            if ((index & 1) == 0) {
                data = @truncate(@as(u64, @bitCast(self.registers[index])));
            } else {
                data = @truncate(@as(u64, @bitCast(self.registers[index])) >> 32);
            }
        }
        return data;
    }
};
