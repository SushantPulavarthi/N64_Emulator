const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;

const Cpu = @import("cpu.zig").Cpu;

const warn = std.log.warn;
const info = std.log.info;
const panic = std.debug.panic;
const logging = true;

fn log(comptime format: []const u8, args: anytype) void {
    if (logging) {
        info(format, args);
    }
}

pub fn decodeInstruction(cpu: *Cpu, instr: u32) void {
    const opcode: u6 = @truncate(instr >> 26);
    switch (opcode) {
        @intFromEnum(Opcode.Special) => {
            switch (opcode) {
                // @intFromEnum(Special.SLL) => {},
                // @intFromEnum(Special.SRL) => {},
                // @intFromEnum(Special.SRA) => {},
                // @intFromEnum(Special.SLLV) => {},
                // @intFromEnum(Special.SRLV) => {},
                // @intFromEnum(Special.SRAV) => {},
                // @intFromEnum(Special.JR) => {},
                // @intFromEnum(Special.JALR) => {},
                // @intFromEnum(Special.SYSCALL) => {},
                // @intFromEnum(Special.BREAK) => {},
                // @intFromEnum(Special.SYNC) => {},
                // @intFromEnum(Special.MFHI) => {},
                // @intFromEnum(Special.MTHI) => {},
                // @intFromEnum(Special.MFLO) => {},
                // @intFromEnum(Special.MTLO) => {},
                // @intFromEnum(Special.DSSLV) => {},
                // @intFromEnum(Special.DSRLV) => {},
                // @intFromEnum(Special.DSRAV) => {},
                // @intFromEnum(Special.MULT) => {},
                // @intFromEnum(Special.MULTU) => {},
                // @intFromEnum(Special.DIV) => {},
                // @intFromEnum(Special.DIVU) => {},
                // @intFromEnum(Special.DMULT) => {},
                // @intFromEnum(Special.DMULTU) => {},
                // @intFromEnum(Special.DDIV) => {},
                // @intFromEnum(Special.DDIVU) => {},
                // @intFromEnum(Special.ADD) => {},
                // @intFromEnum(Special.ADDU) => {},
                // @intFromEnum(Special.SUB) => {},
                // @intFromEnum(Special.SUBU) => {},
                // @intFromEnum(Special.AND) => {},
                // @intFromEnum(Special.OR) => {},
                // @intFromEnum(Special.XOR) => {},
                // @intFromEnum(Special.NOR) => {},
                // @intFromEnum(Special.SLT) => {},
                // @intFromEnum(Special.SLTU) => {},
                // @intFromEnum(Special.DADD) => {},
                // @intFromEnum(Special.DADDU) => {},
                // @intFromEnum(Special.DSUB) => {},
                // @intFromEnum(Special.DSUBU) => {},
                // @intFromEnum(Special.TGE) => {},
                // @intFromEnum(Special.TGEU) => {},
                // @intFromEnum(Special.TLT) => {},
                // @intFromEnum(Special.TLTU) => {},
                // @intFromEnum(Special.TEQ) => {},
                // @intFromEnum(Special.TNE) => {},
                // @intFromEnum(Special.DSLL) => {},
                // @intFromEnum(Special.DSRL) => {},
                // @intFromEnum(Special.DSRA) => {},
                // @intFromEnum(Special.DSLL32) => {},
                // @intFromEnum(Special.DSRL32) => {},
                // @intFromEnum(Special.DSRA32) => {},
                else => panic("Unhandled Special Opcode {X}\n", .{instr}),
            }
        },
        @intFromEnum(Opcode.REGIMM) => {
            switch (opcode) {
                // @intFromEnum(REGIMM.BLTZ) => {},
                // @intFromEnum(REGIMM.BGEZ) => {},
                // @intFromEnum(REGIMM.BLTZL) => {},
                // @intFromEnum(REGIMM.BGEZL) => {},
                // @intFromEnum(REGIMM.TGEI) => {},
                // @intFromEnum(REGIMM.TGEIU) => {},
                // @intFromEnum(REGIMM.TLTI) => {},
                // @intFromEnum(REGIMM.TLTIU) => {},
                // @intFromEnum(REGIMM.TEQI) => {},
                // @intFromEnum(REGIMM.TENI) => {},
                // @intFromEnum(REGIMM.BLTZAL) => {},
                // @intFromEnum(REGIMM.BGEZAL) => {},
                // @intFromEnum(REGIMM.BLTZALL) => {},
                // @intFromEnum(REGIMM.BGEZALL) => {},
                else => panic("Unhandled REGIMM Opcode {X}\n", .{instr}),
            }
        },
        // @intFromEnum(Opcode.J) => {},
        // @intFromEnum(Opcode.JAL) => {},
        // @intFromEnum(Opcode.BEQ) => {},
        // @intFromEnum(Opcode.BNE) => {},
        // @intFromEnum(Opcode.BLEZ) => {},
        // @intFromEnum(Opcode.BGTZ) => {},
        // @intFromEnum(Opcode.ADDI) => {},
        // @intFromEnum(Opcode.ADDIU) => {},
        // @intFromEnum(Opcode.SLTI) => {},
        // @intFromEnum(Opcode.SLTIU) => {},
        // @intFromEnum(Opcode.ANDI) => {},
        // @intFromEnum(Opcode.ORI) => {},
        // @intFromEnum(Opcode.XORI) => {},
        // @intFromEnum(Opcode.LUI) => {},
        @intFromEnum(Opcode.COP0) => {
            switch (getRs(instr)) {
                // @intFromEnum(COP.MF) => {},
                // @intFromEnum(COP.DM) => {},
                // @intFromEnum(COP.CF) => {},
                @intFromEnum(COP.MT) => MT(cpu, instr, 0),
                // @intFromEnum(COP.DM) => {},
                // @intFromEnum(COP.CT) => {},
                // @intFromEnum(COP.BC) => {},
                // @intFromEnum(COP.CO) => {},
                else => panic("Unhandled COP0 Opcode {X}\n", .{instr}),
            }
        },
        // @intFromEnum(Opcode.COP1) => {},
        // @intFromEnum(Opcode.COP2) => {},
        // @intFromEnum(Opcode.BEQL) => {},
        // @intFromEnum(Opcode.BNEL) => {},
        // @intFromEnum(Opcode.BLEZL) => {},
        // @intFromEnum(Opcode.BGTZL) => {},
        // @intFromEnum(Opcode.DADDI) => {},
        // @intFromEnum(Opcode.DADDIU) => {},
        // @intFromEnum(Opcode.LDL) => {},
        // @intFromEnum(Opcode.LDR) => {},
        // @intFromEnum(Opcode.LB) => {},
        // @intFromEnum(Opcode.LH) => {},
        // @intFromEnum(Opcode.LWL) => {},
        // @intFromEnum(Opcode.LW) => {},
        // @intFromEnum(Opcode.LBU) => {},
        // @intFromEnum(Opcode.LHU) => {},
        // @intFromEnum(Opcode.LWR) => {},
        // @intFromEnum(Opcode.LWU) => {},
        // @intFromEnum(Opcode.SB) => {},
        // @intFromEnum(Opcode.SH) => {},
        // @intFromEnum(Opcode.SWL) => {},
        // @intFromEnum(Opcode.SW) => {},
        // @intFromEnum(Opcode.SDL) => {},
        // @intFromEnum(Opcode.SDR) => {},
        // @intFromEnum(Opcode.SWR) => {},
        // @intFromEnum(Opcode.CACHE) => {},
        // @intFromEnum(Opcode.LL) => {},
        // @intFromEnum(Opcode.LWC1) => {},
        // @intFromEnum(Opcode.LWC2) => {},
        // @intFromEnum(Opcode.LLD) => {},
        // @intFromEnum(Opcode.LDC1) => {},
        // @intFromEnum(Opcode.LDC2) => {},
        // @intFromEnum(Opcode.LD) => {},
        // @intFromEnum(Opcode.SC) => {},
        // @intFromEnum(Opcode.SWC1) => {},
        // @intFromEnum(Opcode.SWC2) => {},
        // @intFromEnum(Opcode.SCD) => {},
        // @intFromEnum(Opcode.SDC1) => {},
        // @intFromEnum(Opcode.SDC2) => {},
        // @intFromEnum(Opcode.SD) => {},
        else => panic("Unhandled Opcode {X}\n", .{instr}),
    }
}

const Opcode = enum(u32) {
    Special = 0,
    REGIMM = 1,
    J = 2,
    JAL = 3,
    BEQ = 4,
    BNE = 5,
    BLEZ = 6,
    BGTZ = 7,
    ADDI = 8,
    ADDIU = 9,
    SLTI = 10,
    SLTIU = 11,
    ANDI = 12,
    ORI = 13,
    XORI = 14,
    LUI = 15,
    COP0 = 16,
    COP1 = 17,
    COP2 = 18,
    BEQL = 20,
    BNEL = 21,
    BLEZL = 22,
    BGTZL = 23,
    DADDI = 24,
    DADDIU = 25,
    LDL = 26,
    LDR = 27,
    LB = 32,
    LH = 33,
    LWL = 34,
    LW = 35,
    LBU = 36,
    LHU = 37,
    LWR = 38,
    LWU = 39,
    SB = 40,
    SH = 41,
    SWL = 42,
    SW = 43,
    SDL = 44,
    SDR = 45,
    SWR = 46,
    CACHE = 47,
    LL = 48,
    LWC1 = 49,
    LWC2 = 50,
    LLD = 52,
    LDC1 = 53,
    LDC2 = 54,
    LD = 55,
    SC = 56,
    SWC1 = 57,
    SWC2 = 58,
    SCD = 60,
    SDC1 = 61,
    SDC2 = 62,
    SD = 63,
};

const Special = enum(u32) {
    SLL = 0,
    SRL = 2,
    SRA = 3,
    SLLV = 4,
    SRLV = 6,
    SRAV = 7,
    JR = 8,
    JALR = 9,
    SYSCALL = 12,
    BREAK = 13,
    SYNC = 15,
    MFHI = 16,
    MTHI = 17,
    MFLO = 18,
    MTLO = 19,
    DSSLV = 20,
    DSRLV = 22,
    DSRAV = 23,
    MULT = 24,
    MULTU = 25,
    DIV = 26,
    DIVU = 27,
    DMULT = 28,
    DMULTU = 29,
    DDIV = 30,
    DDIVU = 31,
    ADD = 32,
    ADDU = 33,
    SUB = 34,
    SUBU = 35,
    AND = 36,
    OR = 37,
    XOR = 38,
    NOR = 39,
    SLT = 42,
    SLTU = 43,
    DADD = 44,
    DADDU = 45,
    DSUB = 46,
    DSUBU = 47,
    TGE = 48,
    TGEU = 49,
    TLT = 50,
    TLTU = 51,
    TEQ = 52,
    TNE = 54,
    DSLL = 56,
    DSRL = 58,
    DSRA = 59,
    DSLL32 = 60,
    DSRL32 = 62,
    DSRA32 = 63,
};
const REGIMM = enum(u32) {
    BLTZ = 0,
    BGEZ = 1,
    BLTZL = 2,
    BGEZL = 3,
    TGEI = 8,
    TGEIU = 9,
    TLTI = 10,
    TLTIU = 11,
    TEQI = 12,
    TENI = 14,
    BLTZAL = 16,
    BGEZAL = 17,
    BLTZALL = 18,
    BGEZALL = 19,
};

const COP = enum(u32) {
    MF = 0,
    DMF = 1,
    CF = 2,
    MT = 4,
    DMT = 5,
    CT = 6,
    BC = 8,
    CO = 16,
};

const COPrt = enum(u32) {
    // BCF = 1,
    // BCT = 2,
    // BCFL = 3,
    // BCTL = 4,
};

const CP0 = enum(u32) {
    // TLBR = 1,
    // TLBWI = 2,
    // TLBWR = 6,
    // TLBP = 8,
    // ERET = 24,
};

fn getRs(instr: u32) u5 {
    return @truncate(instr >> 21);
}

fn getRt(instr: u32) u5 {
    return @truncate(instr >> 16);
}

fn getRd(instr: u32) u5 {
    return @truncate(instr >> 11);
}

fn MT(cpu: *Cpu, instr: u32, copN: usize) void {
    const rt = getRt(instr);
    const rd = getRd(instr);
    const data: u32 = @truncate(cpu.readRegister(rt));
    if (copN == 0) {
        cpu.cp0.registers[rd] = data;
    }
    log("MTC0 {d} {d}; {d} = {X}\n", .{ rt, rd, rd, data });
}
//
//
// const opcodeNames = [_][]const u8{
//     "SPECIAL", "REGIMM",  "J",    "JAL",    "BEQ",  "BNE",  "BLEZ",  "BGTZ",
//     "ADDI",    "ADDIU",   "SLTI", "SLTIU",  "ANDI", "ORI",  "XORI",  "LUI",
//     "COP0",    "COP1",    "COP2", "*",      "BEQL", "BNEL", "BLEZL", "BGTZL",
//     "DADDIe",  "DADDIUe", "LDLe", "LDRe",   "*",    "*",    "*",     "*",
//     "LB",      "LH",      "LWL",  "LW",     "LBU",  "LHU",  "LWR",   "LWUe",
//     "SB",      "SH",      "SWL",  "SW",     "SDLe", "SDR",  "SWR",   "CACHEo",
//     "LL",      "LWC1",    "LWC2", "PREF/*", "LLDe", "LDC1", "LDC2",  "LDe",
//     "SC",      "SWC1",    "SWC2", "*",      "SCDe", "SDC1", "SDC2",  "SDe",
// };
//
// const specialNames = [_][]const u8{
//     "SLL",   "*",     "SRL",  "SRA",   "SLLV",    "*",       "SRLV",    "SRAV",
//     "JR",    "JALR",  "*",    "*",     "SYSCALL", "BREAK",   "*",       "SYNC",
//     "MFHI",  "MTHI",  "MFLO", "MTLO",  "DSLLVe",  "*",       "DSRLVe",  "DSRAVe",
//     "MULT",  "MULTU", "DIV",  "DIVU",  "DMULTe",  "DMULTUe", "DDIVe",   "DDIVUe",
//     "ADD",   "ADDU",  "SUB",  "SUBU",  "AND",     "OR",      "XOR",     "NOR",
//     "*",     "*",     "SLT",  "SLTU",  "DADDe",   "DADDUe",  "DSUBe",   "DSUBUe",
//     "TGE",   "TGEU",  "TLT",  "TLTU",  "TEQ",     "*",       "TNE",     "*",
//     "DSLLe", "*",     "DRLe", "DSRAe", "DSLL32e", "*",       "DSRL32e", "DSRA32e",
// };
//
// const regimmNames = [_][]const u8{
//     "BLTZ",   "BGEZ",   "BLTZL",   "BGEZL",   "*",    "*", "*",    "*",
//     "TGEI",   "TGEIU",  "TLTI",    "TLTIU",   "TEQI", "*", "TNEI", "*",
//     "BLTZAL", "BGEZAL", "BLTZALL", "BGEZALL", "*",    "*", "*",    "*",
//     "*",      "*",      "*",       "*",       "*",    "*", "*",    "*",
// };
//
// const copzNames = [_][]const u8{
//     "MF",  "DMFe", "CF",   "y",    "MT", "DMTe", "CT", "y",
//     "BC",  "y",    "y",    "y",    "y",  "y",    "y",  "y",
//     "BCF", "BCT",  "BCFL", "BCTL", "y",  "y",    "y",  "y",
//     "y",   "y",    "y",    "y",    "y",  "y",    "y",  "y",
//     "y",   "y",    "y",    "y",    "y",  "y",    "y",  "y",
//     "y",   "y",    "y",    "y",    "y",  "y",    "y",  "y",
// };
//
// const cp0Names = [_][]const u8{
//     "p",    "TLBR", "TLBWI", "p", "p", "p", "TLBWR", "p",
//     "TLBP", "p",    "p",     "p", "p", "p", "p",     "p",
//     "x",    "p",    "p",     "p", "p", "p", "p",     "p",
//     "p",    "p",    "p",     "p", "p", "p", "p",     "p",
//     "p",    "p",    "p",     "p", "p", "p", "p",     "p",
//     "p",    "p",    "p",     "p", "p", "p", "p",     "p",
// };
//

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
