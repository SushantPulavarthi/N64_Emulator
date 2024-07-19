const COP0 = struct {
    pub var registers: [32]u32 = undefined;
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
