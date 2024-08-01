const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;

const RANDOM_UPPER_LIMIT = 31;

pub const Cp0 = struct {
    registers: []u32 = undefined,

    // 0-5 - index of TLB entry, TLB entry affected by TLB read or write index instructions
    // 6-30 - Written and read as zeroes
    // 31 - success(0)/failure(1) of TLB Probe instruction
    reg_index: u32 = 0,
    // Todo: might be better to model as
    // u1: reg_index_p
    // u6: reg_index_index

    // 0-5 TLB Entry
    // Bit 5 is readable and writable (ignored during TLB operations)
    // Decrements as each instruction executes and range between Wired register and 31
    // Upon cold reset set to value of upper bound
    reg_random: u32 = 0,

    // Used to rewrite TLB or check coincidence of TLB entry when addresses are converted
    // If TLB exception occurs, address loaded onto these registers
    reg_entry_hi: u32 = 0,
    // Even Virtual Pages
    reg_entry_lo0: u32 = 0,
    // Odd Virtual Pages
    reg_entry_lo1: u32 = 0,
    reg_page_mask: u32 = 0,

    // Boundary between wired and random entries of TLB
    // 0-5 - Used in TLB operations
    // Bit 5 ignored during TLB operations
    reg_wired: u32 = 0,

    // 0-7 - Processor Revision Number (Rev)
    // 8-15 - Processor ID Number (Imp) - 0x0B
    // 16-31 - 0
    // In format yx
    // y major revision number 7-4
    // x minor revision number 3-0
    reg_PRId: u32 = 0,

    // Set various processor statuses
    // 0-2 K0
    // 3 CU
    // 4-14 11001000110
    // 15 BE
    // 16-23 00000110
    // 24-27 EP
    // 28-30 EC
    // 31 0
    reg_config: u32 = 0,

    // Contains physical address read by most recent Load Linked Instruction
    // For diagnostics
    reg_ll_addr: u32 = 0,

    reg_TagLo: u32 = 0,
    reg_TagHi: u32 = 0,

    pub fn init(allocator: std.mem.Allocator) !Cp0 {
        const registers = try allocator.alloc(u32, 32);
        @memset(registers, 0);

        // Simulating PIF Rom
        registers[1] = 0x1F;
        registers[12] = 0x34000000;
        // registers[12] = 0x70400004;
        registers[15] = 0x00000B00;
        registers[16] = 0x0006E463;

        return Cp0{
            .registers = registers,
        };
    }

    pub fn deinit(self: *Cp0, allocator: std.mem.Allocator) void {
        allocator.free(self.registers);
    }

    fn coldReset(self: *Cp0) void {
        self.reg_random = RANDOM_UPPER_LIMIT;
        self.reg_wired = 0;
        // TODO: might need to change
        self.reg_config = 0b00000000000011100110010001100000;
    }

    // Generate random number in range wired <= value <= 31 every time random is read
    // Wired - lower bound for random value held in random

    // Timing
    // Count - incremented every other cycle
    // Compared to value in compare and fire an interrupt when count == compare
    // Compare - Fire interrupt when count equals this value, sets ip7 bit in Cause to 1
    // Writes to this register clear said interrupt, and sets the ip7 bit in Cause to 0.

    // Cache
    // TagLo
    // TagHi

    // Exception/Interrupt Registers
    // BadVAddr - when TLB exception is thrown the register is loaded with the address of failed translation
    // Cause - Contains details on exception / interrupt that cocured. Only low 2 bits of interrupt pending field can be written to using MTC0. Rest are read only and set when an exception is thrown.
    // 0-1 unused always 0
    // 2-6 exception code - which exception occurred
    // 7 unused always 0
    // 8-15 interrupt pending (which interrupts are waiting to be serviced) used with interrupt mask on $status
    // 16-27 unused (always 0)
    // 28-29 coprocessor error (which coprocessor threw the exception) - often not used
    // 30 unused always 0
    // 31 branch delay (did exception occur in a branch delay slot)
    //
    // EPC
    // ErrorEPC
    // WatchLo
    // WatchHi
    // XContext
    // Parity Error - N64 doesnt generate parity error so never written to by hardware
    // Cache Error - N64 doesnt generate cahce error, so never written by hardware

    // Other registers
    // PRId
    // Config
    // LLAddr
    // Status
    // 0 	ie - global interrupt enable (should interrupts be handled?)
    // 1 	exl - exception level (are we currently handling an exception?)
    // 2 	erl - error level (are we currently handling an error?)
    // 3-4 	ksu - execution mode (00 = kernel, 01 = supervisor, 10 = user)
    // 5 	ux - 64 bit addressing enabled in user mode
    // 6 	sx - 64 bit addressing enabled in supervisor mode
    // 7 	kx - 64 bit addressing enabled in kernel mode
    // 8-15 	im - interrupt mask (&’d against interrupt pending in $Cause)
    // 16-24 	ds - diagnostic status (described below)
    // 25 	re - reverse endianness (0 = big endian, 1 = little endian)
    // 26 	fr - enables additional floating point registers (0 = 16 regs, 1 = 32 regs)
    // 27 	rp - enable low power mode. Run the CPU at 1/4th clock speed
    // 28 	cu0 - Coprocessor 0 enabled (this bit is ignored by the N64, COP0 is always enabled!)
    // 29 	cu1 - Coprocessor 1 enabled - if this bit is 0, all COP1 instructions throw exceptions
    // 30 	cu2 - Coprocessor 2 enabled (this bit is ignored by the N64, there is no COP2!)
    // 31 	cu3 - Coprocessor 3 enabled (this bit is ignored by the N64, there is no COP3!)
};
