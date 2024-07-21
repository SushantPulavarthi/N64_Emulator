const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;

pub fn decodeInstruction(instruction: u32) void {
    const op: u5 = instruction >> 26;
    switch (op) {
        0 => decodeSpecial(instruction),
        1 => REGIMM(instruction),
    }
}

const opcodeNames = []u8{
    "SPECIAL", "REGIMM",  "J",    "JAL",    "BEQ",  "BNE",  "BLEZ",  "BGTZ",
    "ADDI",    "ADDIU",   "SLTI", "SLTIU",  "ANDI", "ORI",  "XORI",  "LUI",
    "COP0",    "COP1",    "COP2", "*",      "BEQL", "BNEL", "BLEZL", "BGTZL",
    "DADDIe",  "DADDIUe", "LDLe", "LDRe",   "*",    "*",    "*",     "*",
    "LB",      "LH",      "LWL",  "LW",     "LBU",  "LHU",  "LWR",   "LWUe",
    "SB",      "SH",      "SWL",  "SW",     "SDLe", "SDR",  "SWR",   "CACHEo",
    "LL",      "LWC1",    "LWC2", "PREF/*", "LLDe", "LDC1", "LDC2",  "LDe",
    "SC",      "SWC1",    "SWC2", "*",      "SCDe", "SDC1", "SDC2",  "SDe",
};

const specialNames = []u8{
    "SLL",   "*",     "SRL",  "SRA",   "SLLV",    "*",       "SRLV",    "SRAV",
    "JR",    "JALR",  "*",    "*",     "SYSCALL", "BREAK",   "*",       "SYNC",
    "MFHI",  "MTHI",  "MFLO", "MTLO",  "DSLLVe",  "*",       "DSRLVe",  "DSRAVe",
    "MULT",  "MULTU", "DIV",  "DIVU",  "DMULTe",  "DMULTUe", "DDIVe",   "DDIVUe",
    "ADD",   "ADDU",  "SUB",  "SUBU",  "AND",     "OR",      "XOR",     "NOR",
    "*",     "*",     "SLT",  "SLTU",  "DADDe",   "DADDUe",  "DSUBe",   "DSUBUe",
    "TGE",   "TGEU",  "TLT",  "TLTU",  "TEQ",     "*",       "TNE",     "*",
    "DSLLe", "*",     "DRLe", "DSRAe", "DSLL32e", "*",       "DSRL32e", "DSRA32e",
};

const regimmNames = []u8{
    "BLTZ",   "BGEZ",   "BLTZL",   "BGEZL",   "*",    "*", "*",    "*",
    "TGEI",   "TGEIU",  "TLTI",    "TLTIU",   "TEQI", "*", "TNEI", "*",
    "BLTZAL", "BGEZAL", "BLTZALL", "BGEZALL", "*",    "*", "*",    "*",
    "*",      "*",      "*",       "*",       "*",    "*", "*",    "*",
};

const copzNames = []u8{
    "MF",  "DMFe", "CF",   "y",    "MT", "DMTe", "CT", "y",
    "BC",  "y",    "y",    "y",    "y",  "y",    "y",  "y",
    "BCF", "BCT",  "BCFL", "BCTL", "y",  "y",    "y",  "y",
    "y",   "y",    "y",    "y",    "y",  "y",    "y",  "y",
    "y",   "y",    "y",    "y",    "y",  "y",    "y",  "y",
    "y",   "y",    "y",    "y",    "y",  "y",    "y",  "y",
};

const cp0Names = []u8{
    "p",    "TLBR", "TLBWI", "p", "p", "p", "TLBWR", "p",
    "TLBP", "p",    "p",     "p", "p", "p", "p",     "p",
    "x",    "p",    "p",     "p", "p", "p", "p",     "p",
    "p",    "p",    "p",     "p", "p", "p", "p",     "p",
    "p",    "p",    "p",     "p", "p", "p", "p",     "p",
    "p",    "p",    "p",     "p", "p", "p", "p",     "p",
};

fn decodeSpecial(instruction: u32) void {
    _ = instruction;
}

fn REGIMM(instruction: u32) void {
    _ = instruction;
}

const MASK5 = 0x11111;

// Load and Store - move data between memory and general purpose registers
// Addressing mode - base register + 16 bit signed immediate offset
// Immediate

// Computational - arithmetical, logical, shift, multiply and divide on registers
// Register (operand and result in registers) and Immediate (one operand is 16 bit signed immediate)

// Jump and Branch
// Jumps - 26 bit target address and high order bits of Program counter (J-Type) or register address (R-type)
// Branch - performed to 16 bit offset address relative to program counter (I-Type)
// Jump and Link save return address in R31

// Coprocessor Instructions (CPz)
// Load and store instructions are I-type.
// Not specific to coprocessor

// Coprocessor0
// operations on CP0 registers to control memory-management and exception handling

// Special Instructions
// System Call exception and breakpoint exception operations,
// Or cause branch to general exception handling vector based on comparison
// Both R-type (operand and result in registers) and I-type (on operate is 16-bit immediate value)

fn decodeImmediate(instruction: u32) void {
    const op: u5 = instruction >> 26;
    const rs: u5 = (instruction >> 21) & MASK5;
    const rt: u5 = (instruction >> 16) & MASK5;
    const immediate: i5 = instruction & 0xFFFF;
    _ = op;
    _ = rs;
    _ = rt;
    _ = immediate;
}

fn decodeJump(instruction: u32) void {
    const op: u5 = instruction >> 26;
    const target: u26 = instruction & 0x3FFFFFF;
    _ = op;
    _ = target;
}

fn decodeRegister(instruction: u32) void {
    const op: u5 = instruction >> 26;
    const rs: u5 = (instruction >> 21) & MASK5;
    const rt: u5 = (instruction >> 16) & MASK5;
    const rd: u5 = (instruction >> 11) & MASK5;
    const sa: u5 = (instruction >> 6) & MASK5;
    const funct: u5 = instruction & 0x3F;
    _ = op;
    _ = rs;
    _ = rt;
    _ = rd;
    _ = sa;
    _ = funct;
}
