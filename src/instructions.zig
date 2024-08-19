const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;

const Cpu = @import("cpu.zig").Cpu;
const TLBEntry = @import("cpu.zig").TLBEntry;

const warn = std.log.warn;
const info = std.log.info;
const panic = std.debug.panic;
const logging = true;

fn log(comptime format: []const u8, args: anytype) void {
    if (logging) {
        info(format, args);
    }
}

const MIN_I64 = 0x8000000000000000;
const MIN_I32 = 0x80000000;

const MAX_U64: u64 = 0xFFFFFFFF_FFFFFFFF;
const MAX_U32: u32 = 0xFFFFFFFF;
const MASK_1: u64 = @as(u64, 1);

pub fn decodeInstruction(cpu: *Cpu, instr: u32) void {
    const opcode: u6 = @truncate(instr >> 26);
    switch (opcode) {
        @intFromEnum(Opcode.Special) => {
            switch (opcode) {
                @intFromEnum(Special.SLL) => iSLL(cpu, instr),
                @intFromEnum(Special.SRL) => iSRL(cpu, instr),
                @intFromEnum(Special.SRA) => iSRA(cpu, instr),
                @intFromEnum(Special.SLLV) => iSLLV(cpu, instr),
                @intFromEnum(Special.SRLV) => iSRLV(cpu, instr),
                @intFromEnum(Special.SRAV) => iSRAV(cpu, instr),
                @intFromEnum(Special.JR) => iJR(cpu, instr),
                @intFromEnum(Special.JALR) => iJALR(cpu, instr),
                @intFromEnum(Special.SYSCALL) => {
                    // TODO System call exception
                    log("SYSCALL", .{});
                },
                @intFromEnum(Special.BREAK) => {
                    // TODO Breakpoint Exception
                    log("BREAK", .{});
                },
                @intFromEnum(Special.SYNC) => {
                    log("SYNC", .{});
                },
                @intFromEnum(Special.MFHI) => iMFHI(cpu, instr),
                @intFromEnum(Special.MTHI) => iMTHI(cpu, instr),
                @intFromEnum(Special.MFLO) => iMFLO(cpu, instr),
                @intFromEnum(Special.MTLO) => iMTLO(cpu, instr),
                @intFromEnum(Special.DSLLV) => iDSLLV(cpu, instr),
                @intFromEnum(Special.DSRLV) => iDSRAV(cpu, instr),
                @intFromEnum(Special.DSRAV) => iDSRAV(cpu, instr),
                @intFromEnum(Special.MULT) => iMULT(cpu, instr),
                @intFromEnum(Special.MULTU) => iMULTU(cpu, instr),
                @intFromEnum(Special.DIV) => iDIV(cpu, instr),
                @intFromEnum(Special.DIVU) => iDIVU(cpu, instr),
                @intFromEnum(Special.DMULT) => iDMULT(cpu, instr),
                @intFromEnum(Special.DMULTU) => iDMULTU(cpu, instr),
                @intFromEnum(Special.DDIV) => iDDIV(cpu, instr),
                @intFromEnum(Special.DDIVU) => iDDIVU(cpu, instr),
                @intFromEnum(Special.ADD) => iADD(cpu, instr),
                @intFromEnum(Special.ADDU) => iADDU(cpu, instr),
                @intFromEnum(Special.SUB) => iSUB(cpu, instr),
                @intFromEnum(Special.SUBU) => iSUBU(cpu, instr),
                @intFromEnum(Special.AND) => iAND(cpu, instr),
                @intFromEnum(Special.OR) => iOR(cpu, instr),
                @intFromEnum(Special.XOR) => iXOR(cpu, instr),
                @intFromEnum(Special.NOR) => iNOR(cpu, instr),
                @intFromEnum(Special.SLT) => iSLT(cpu, instr),
                @intFromEnum(Special.SLTU) => iSLTU(cpu, instr),
                @intFromEnum(Special.DADD) => iDADD(cpu, instr),
                @intFromEnum(Special.DADDU) => iDADDU(cpu, instr),
                @intFromEnum(Special.DSUB) => iDSUB(cpu, instr),
                @intFromEnum(Special.DSUBU) => iDSUBU(cpu, instr),
                @intFromEnum(Special.TGE) => iTGE(cpu, instr),
                @intFromEnum(Special.TGEU) => iTGEU(cpu, instr),
                @intFromEnum(Special.TLT) => iTLT(cpu, instr),
                @intFromEnum(Special.TLTU) => iTLTU(cpu, instr),
                @intFromEnum(Special.TEQ) => iTEQ(cpu, instr),
                @intFromEnum(Special.TNE) => iTNE(cpu, instr),
                @intFromEnum(Special.DSLL) => iDSLL(cpu, instr),
                @intFromEnum(Special.DSRL) => iDSRL(cpu, instr),
                @intFromEnum(Special.DSRA) => iDSRA(cpu, instr),
                @intFromEnum(Special.DSLL32) => iDSLL32(cpu, instr),
                // @intFromEnum(Special.DSRL32) => iDSRL32(cpu, instr),
                @intFromEnum(Special.DSRA32) => iDSRA32(cpu, instr),
                else => panic("Unhandled Special Opcode {X}\n", .{instr}),
            }
        },
        @intFromEnum(Opcode.REGIMM) => {
            switch (opcode) {
                @intFromEnum(REGIMM.BLTZ) => iBLTZ(cpu, instr),
                @intFromEnum(REGIMM.BGEZ) => iBGEZ(cpu, instr),
                @intFromEnum(REGIMM.BLTZL) => iBLTZL(cpu, instr),
                @intFromEnum(REGIMM.BGEZL) => iBGEZL(cpu, instr),
                @intFromEnum(REGIMM.TGEI) => iTGEI(cpu, instr),
                @intFromEnum(REGIMM.TGEIU) => iTGEIU(cpu, instr),
                @intFromEnum(REGIMM.TLTI) => iTLTI(cpu, instr),
                @intFromEnum(REGIMM.TLTIU) => iTLTIU(cpu, instr),
                @intFromEnum(REGIMM.TEQI) => iTEQI(cpu, instr),
                @intFromEnum(REGIMM.TNEI) => iTNEI(cpu, instr),
                @intFromEnum(REGIMM.BLTZAL) => iBLTZAL(cpu, instr),
                @intFromEnum(REGIMM.BGEZAL) => iBGEZAL(cpu, instr),
                @intFromEnum(REGIMM.BLTZALL) => iBLTZALL(cpu, instr),
                @intFromEnum(REGIMM.BGEZALL) => iBGEZALL(cpu, instr),
                else => panic("Unhandled REGIMM Opcode {X}\n", .{instr}),
            }
        },
        @intFromEnum(Opcode.J) => iJ(cpu, instr),
        @intFromEnum(Opcode.JAL) => iJAL(cpu, instr),
        @intFromEnum(Opcode.BEQ) => iBEQ(cpu, instr),
        @intFromEnum(Opcode.BNE) => iBNE(cpu, instr),
        @intFromEnum(Opcode.BLEZ) => iBLEZ(cpu, instr),
        @intFromEnum(Opcode.BGTZ) => iBGTZ(cpu, instr),
        @intFromEnum(Opcode.ADDI) => iADDI(cpu, instr),
        @intFromEnum(Opcode.ADDIU) => iADDIU(cpu, instr),
        @intFromEnum(Opcode.SLTI) => iSLTI(cpu, instr),
        @intFromEnum(Opcode.SLTIU) => iSLTIU(cpu, instr),
        @intFromEnum(Opcode.ANDI) => iANDI(cpu, instr),
        @intFromEnum(Opcode.ORI) => iORI(cpu, instr),
        @intFromEnum(Opcode.XORI) => iXORI(cpu, instr),
        @intFromEnum(Opcode.LUI) => iLUI(cpu, instr),
        @intFromEnum(Opcode.COP0) => {
            switch (getRs(instr)) {
                @intFromEnum(COP.MF) => iMFC(cpu, instr, 0),
                @intFromEnum(COP.DMF) => iDMFC(cpu, instr),
                @intFromEnum(COP.MT) => iMTC(cpu, instr, 0),
                // @intFromEnum(COP.DMT) => {},
                @intFromEnum(COP.CO) => {
                    switch (instr & 0x3F) {
                        @intFromEnum(CP0.TLBR) => iTLBR(cpu),
                        @intFromEnum(CP0.TLBWI) => iTLBWI(cpu),
                        @intFromEnum(CP0.TLBWR) => iTLBWR(cpu),
                        @intFromEnum(CP0.TLBP) => iTLBP(cpu),
                        @intFromEnum(CP0.ERET) => iERET(cpu),
                    }
                },
                else => panic("Unhandled COP0 Opcode {X}\n", .{instr}),
            }
        },
        @intFromEnum(Opcode.COP1) => {
            // TODO: Exception if not enabled / unusable
            switch (getRs(instr)) {
                @intFromEnum(COP.MF) => iMFC(cpu, instr, 1),
                // @intFromEnum(COP.DMF) => iDMFC(cpu, instr, 1),
                // @intFromEnum(COP.CF) => {},
                @intFromEnum(COP.MT) => iMTC(cpu, instr, 0),
                // @intFromEnum(COP.DMT) => {},
                // @intFromEnum(COP.CT) => {},
                @intFromEnum(COP.BC) => iBC(cpu, instr),
                else => panic("Unhandled COP1 Opcode {X}\n", .{instr}),
            }
        },
        // @intFromEnum(Opcode.COP2) => {
        //     // TODO: Exception if not enabled / unusable
        //     switch (getRs(instr)) {
        //         @intFromEnum(COP.MF) => iMFC(cpu, instr, 1),
        //         // @intFromEnum(COP.DMF) => iDMFC(cpu, instr, 1),
        //         // @intFromEnum(COP.CF) => {},
        //         @intFromEnum(COP.MT) => iMTC(cpu, instr, 0),
        //         // @intFromEnum(COP.DMT) => {},
        //         // @intFromEnum(COP.CT) => {},
        //         else => panic("Unhandled COP2 Opcode {X}\n", .{instr}),
        //     }
        // },
        @intFromEnum(Opcode.BEQL) => iBEQL(cpu, instr),
        @intFromEnum(Opcode.BNEL) => iBNEL(cpu, instr),
        @intFromEnum(Opcode.BLEZL) => iBLEZL(cpu, instr),
        @intFromEnum(Opcode.BGTZL) => iBGTZL(cpu, instr),
        @intFromEnum(Opcode.DADDI) => iDADDI(cpu, instr),
        @intFromEnum(Opcode.DADDIU) => iDADDIU(cpu, instr),
        @intFromEnum(Opcode.LDL) => iLDL(cpu, instr),
        @intFromEnum(Opcode.LDR) => iLDR(cpu, instr),
        @intFromEnum(Opcode.LB) => iLB(cpu, instr),
        @intFromEnum(Opcode.LH) => iLH(cpu, instr),
        @intFromEnum(Opcode.LWL) => iLWL(cpu, instr),
        @intFromEnum(Opcode.LW) => iLW(cpu, instr),
        @intFromEnum(Opcode.LBU) => iLBU(cpu, instr),
        @intFromEnum(Opcode.LHU) => iLHU(cpu, instr),
        @intFromEnum(Opcode.LWR) => iLWR(cpu, instr),
        @intFromEnum(Opcode.LWU) => iLWU(cpu, instr),
        @intFromEnum(Opcode.SB) => iSB(cpu, instr),
        @intFromEnum(Opcode.SH) => iSH(cpu, instr),
        @intFromEnum(Opcode.SWL) => iSWL(cpu, instr),
        @intFromEnum(Opcode.SW) => iSW(cpu, instr),
        @intFromEnum(Opcode.SDL) => iSDL(cpu, instr),
        @intFromEnum(Opcode.SDR) => iSDR(cpu, instr),
        @intFromEnum(Opcode.SWR) => iSWR(cpu, instr),
        @intFromEnum(Opcode.CACHE) => iCACHE(cpu, instr),
        @intFromEnum(Opcode.LL) => iLL(cpu, instr),
        @intFromEnum(Opcode.LWC1) => iLWC(cpu, instr),
        // @intFromEnum(Opcode.LWC2) => {},
        @intFromEnum(Opcode.LLD) => iLLD(cpu, instr),
        @intFromEnum(Opcode.LDC1) => iLDC(cpu, instr),
        // @intFromEnum(Opcode.LDC2) => {},
        @intFromEnum(Opcode.LD) => iLD(cpu, instr),
        @intFromEnum(Opcode.SC) => iSC(cpu, instr),
        @intFromEnum(Opcode.SWC1) => iSWC(cpu, instr),
        // @intFromEnum(Opcode.SWC2) => {},
        @intFromEnum(Opcode.SCD) => iSCD(cpu, instr),
        @intFromEnum(Opcode.SDC1) => iSDC(cpu, instr),
        // @intFromEnum(Opcode.SDC2) => {},
        @intFromEnum(Opcode.SD) => iSD(cpu, instr),
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
    DSLLV = 20,
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
    TNEI = 14,
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
    BCF = 0,
    BCT = 1,
    BCFL = 2,
    BCTL = 3,
};

const CP0 = enum(u32) {
    TLBR = 1,
    TLBWI = 2,
    TLBWR = 6,
    TLBP = 8,
    ERET = 24,
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

fn getSa(instr: u32) u5 {
    return @truncate(instr >> 6);
}

fn getTarget(instr: u32) u26 {
    return @truncate(instr);
}

fn getL16(instr: u32) u16 {
    return @truncate(instr);
}

fn iADD(cpu: *Cpu, instr: u32) void {
    const rt = getRt(instr);
    const rd = getRd(instr);
    const rs = getRs(instr);
    log("ADD {d} {d} {d}", .{ rd, rs, rt });
    const result = @addWithOverflow(@as(u32, @truncate(cpu.readRegister(rt))), @as(u32, @truncate(cpu.readRegister(rs))));
    if (result[1] != 0) {
        // Overflowed
        // TODO: Integer overflow exception
        log("ADD: Integer overflow exception", .{});
    } else {
        cpu.reg_gpr[rd] = ext32(result[0]);
        // cpu.write32(rd, @truncate(result[0]));
    }
}

fn ext8(val: u8) u64 {
    return @bitCast(@as(i64, @intCast(@as(i8, @bitCast(val)))));
}

fn ext16(val: u16) u64 {
    return @bitCast(@as(i64, @intCast(@as(i16, @bitCast(val)))));
}

fn ext32(val: u32) u64 {
    return @bitCast(@as(i64, @intCast(@as(i32, @bitCast(val)))));
}

// Better name for test case
test "ext16Negative" {
    const val: u16 = 0x8000;
    const result = ext16(val);
    const expected: u64 = 0xFFFFFFFFFFFF8000;
    try std.testing.expect(result == expected);
}

test "ext16NonNegative" {
    const val: u16 = 0x0800;
    const result = ext16(val);
    try std.testing.expect(result == val);
}

test "ext32Negative" {
    const val: u32 = 0x80000000;
    const result = ext32(val);
    const expected: u64 = 0xFFFFFFFF80000000;
    try std.testing.expect(result == expected);
}
test "ext32NonNegative" {
    const val: u32 = 0x800;
    const result = ext32(val);
    try std.testing.expect(result == val);
}

fn iADDI(cpu: *Cpu, instr: u32) void {
    const rt: u5 = getRt(instr);
    const rs: u5 = getRs(instr);
    const imm: u32 = @truncate(ext16(getL16(instr)));
    log("ADDI {d} {d} {d}", .{ rt, rs, imm });
    const result = @addWithOverflow(imm, @as(u32, @truncate(cpu.readRegister(rs))));
    if (result[1] != 0) {
        // Overflowed
        // TODO: Integer overflow exception
        log("ADD: Integer overflow exception", .{});
    } else {
        cpu.reg_gpr[rt] = ext32(result[0]);
        // cpu.write32(rt, @truncate(result[0]));
    }
}

fn iADDIU(cpu: *Cpu, instr: u32) void {
    const rt: u5 = getRt(instr);
    const rs: u5 = getRs(instr);
    const imm: u32 = @truncate(ext16(getL16(instr)));
    const result = @addWithOverflow(imm, @as(u32, @truncate(cpu.readRegister(rs))));
    log("ADDIU {d} {d} {d}", .{ rt, rs, imm });
    // cpu.write32(rt, @truncate(result[0]));
    cpu.reg_gpr[rt] = ext32(result[0]);
}

fn iADDU(cpu: *Cpu, instr: u32) void {
    const rt: u5 = getRt(instr);
    const rs: u5 = getRs(instr);
    const rd: u5 = getRd(instr);
    log("ADDU {d} {d} {d}", .{ rd, rs, rt });
    const result = @addWithOverflow(cpu.readRegister(rt), cpu.readRegister(rs));
    cpu.reg_gpr[rd] = result[0];
}

fn iAND(cpu: *Cpu, instr: u32) void {
    const rt: u5 = getRt(instr);
    const rs: u5 = getRs(instr);
    const rd: u5 = getRd(instr);
    log("AND {d} {d} {d}", .{ rd, rs, rt });
    const result = cpu.readRegister(rt) & cpu.readRegister(rs);
    cpu.reg_gpr[rd] = result;
}

fn iANDI(cpu: *Cpu, instr: u32) void {
    const rt: u5 = getRt(instr);
    const rs: u5 = getRs(instr);
    const imm: u16 = getL16(instr);
    log("ANDI {d} {d} {d}", .{ rt, rs, imm });
    const result = imm & cpu.readRegister(rs);
    cpu.reg_gpr[rt] = result;
}

fn iBC(cpu: *Cpu, instr: u32) void {
    const offset = ext16(getL16(instr)) << 2;
    log("BC {X}", .{offset});
    const branchAddr = cpu.PC +% offset;
    const branchType = instr >> 15 & 0x1F;
    const cond = branchType % 2 != 0;
    const likely = branchType > 1;
    if (cpu.cp1.condition_signal == cond) {
        cpu.nextPC = branchAddr;
    } else {
        if (likely) {
            cpu.PC = cpu.nextPC;
            cpu.nextPC += 4;
        }
    }
}

fn iBEQ(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    const rt = getRt(instr);
    log("BEQ {X} {X} {X}", .{ rs, rt, getL16(instr) });
    branch(cpu, instr, cpu.readRegister(rs) == cpu.readRegister(rt));
}

fn iBEQL(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    const rt = getRt(instr);
    log("BEQL {X} {X} {X}", .{ rs, rt, getL16(instr) });
    branchLikely(cpu, instr, cpu.readRegister(rs) == cpu.readRegister(rt));
}

fn iBGEZ(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    log("BGEZ {X} {X}", .{ rs, getL16(instr) });
    branch(cpu, instr, cpu.readRegister(rs) >= 0);
}

fn iBGEZAL(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    log("BGEZAL {X} {X}", .{ rs, getL16(instr) });
    cpu.reg_gpr[31] = cpu.nextPC;
    branch(cpu, instr, cpu.readRegister(rs) >= 0);
}

fn iBGEZALL(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    log("BGEZALL {X} {X}", .{ rs, getL16(instr) });
    cpu.reg_gpr[31] = cpu.nextPC;
    branchLikely(cpu, instr, cpu.readRegister(rs) >= 0);
}

fn iBGEZL(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    log("BGEZL {X} {X}", .{ rs, getL16(instr) });
    branchLikely(cpu, instr, cpu.readRegister(rs) >= 0);
}

fn iBGTZ(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    log("BGTZ {X} {X}", .{ rs, getL16(instr) });
    branch(cpu, instr, cpu.readRegister(rs) > 0);
}

fn iBGTZL(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    log("BGTZL {X} {X}", .{ rs, getL16(instr) });
    branchLikely(cpu, instr, cpu.readRegister(rs) > 0);
}

fn iBLEZ(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    log("BLEZ {X} {X}", .{ rs, getL16(instr) });
    branch(cpu, instr, cpu.readRegister(rs) <= 0);
}

fn iBLEZL(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    log("BLEZL {X} {X}", .{ rs, getL16(instr) });
    branchLikely(cpu, instr, cpu.readRegister(rs) <= 0);
}

fn iBLTZ(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    log("BLTZ {X} {X}", .{ rs, getL16(instr) });
    branch(cpu, instr, cpu.readRegister(rs) < 0);
}

fn iBLTZAL(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    log("BLTZAL {X} {X}", .{ rs, getL16(instr) });
    cpu.reg_gpr[31] = cpu.nextPC;
    branch(cpu, instr, cpu.readRegister(rs) < 0);
}

fn iBLTZALL(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    log("BLTZALL {X} {X}", .{ rs, getL16(instr) });
    cpu.reg_gpr[31] = cpu.nextPC;
    branchLikely(cpu, instr, cpu.readRegister(rs) < 0);
}

fn iBLTZL(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    log("BLTZL {X} {X}", .{ rs, getL16(instr) });
    branchLikely(cpu, instr, cpu.readRegister(rs) < 0);
}

fn iBNE(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    const rt = getRt(instr);
    log("BNE {X} {X} {X}", .{ rs, rt, getL16(instr) });
    branch(cpu, instr, cpu.readRegister(rs) != cpu.readRegister(rt));
}

fn iBNEL(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    const rt = getRt(instr);
    log("BNEL {X} {X} {X}", .{ rs, rt, getL16(instr) });
    branchLikely(cpu, instr, cpu.readRegister(rs) != cpu.readRegister(rt));
}

fn iCACHE(cpu: *Cpu, instr: u32) void {
    // TODO
    _ = cpu; // autofix
    const op = getRs(instr);
    _ = op; // autofix
    const offset = ext16(getL16(instr));
    _ = offset; // autofix
}

fn branch(cpu: *Cpu, instr: u32, cond: bool) void {
    const offset = ext16(getL16(instr)) << 2;
    const branchAddr = cpu.PC +% offset;
    if (cond) {
        cpu.nextPC = branchAddr;
    }
}

fn branchLikely(cpu: *Cpu, instr: u32, cond: bool) void {
    const offset = ext16(getL16(instr)) << 2;
    const branchAddr = cpu.PC +% offset;
    if (cond) {
        cpu.nextPC = branchAddr;
    } else {
        // Skip next instruction
        cpu.PC = cpu.nextPC;
        cpu.nextPC += 4;
    }
}

fn iDADD(cpu: *Cpu, instr: u32) void {
    const rt = getRt(instr);
    const rd = getRd(instr);
    const rs = getRs(instr);
    log("DADD {d} {d} {d}", .{ rd, rs, rt });
    const result = @addWithOverflow(cpu.readRegister(rt), cpu.readRegister(rs));
    if (result[1] != 0) {
        // Overflowed
        // TODO: Integer overflow exception
    } else {
        cpu.reg_gpr[rd] = result[0];
    }
}

fn iDADDI(cpu: *Cpu, instr: u32) void {
    const rt = getRt(instr);
    const rs = getRs(instr);
    const imm = ext16(getL16(instr));
    log("DADDI {d} {d} {d}", .{ rt, rs, getL16(instr) });
    const result = @addWithOverflow(cpu.readRegister(rs), imm);
    if (result[1] != 0) {
        // Overflowed
        // TODO: Integer overflow exception
    } else {
        cpu.reg_gpr[rt] = result[0];
    }
}

fn iDADDIU(cpu: *Cpu, instr: u32) void {
    const rt = getRt(instr);
    const rs = getRs(instr);
    const imm = ext16(getL16(instr));
    log("DADDI {d} {d} {d}", .{ rt, rs, getL16(instr) });
    const result = @addWithOverflow(cpu.readRegister(rs), imm);
    cpu.reg_gpr[rt] = result[0];
}

fn iDADDU(cpu: *Cpu, instr: u32) void {
    const rt = getRt(instr);
    const rs = getRs(instr);
    const rd = getRd(instr);
    log("DADDI {d} {d} {d}", .{ rt, rs, getL16(instr) });
    const result = @addWithOverflow(cpu.readRegister(rs), cpu.readRegister(rt));
    cpu.reg_gpr[rd] = result[0];
}

fn iDDIV(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    const rt = getRt(instr);
    log("DDIV {X} {X}", .{ rs, rt });
    const reg_rt: i64 = @bitCast(cpu.readRegister(rt));
    const reg_rs: i64 = @bitCast(cpu.readRegister(rs));
    if (reg_rt == 0) {
        // Undefined
        cpu.LO = MIN_I64;
        cpu.HI = 0;
    } else {
        cpu.LO = @as(u64, @bitCast(@divTrunc(reg_rs, reg_rt)));
        cpu.HI = @as(u64, @bitCast(@rem(reg_rs, reg_rt)));
    }
}

fn iDDIVU(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    const rt = getRt(instr);
    log("DDIV {X} {X}", .{ rs, rt });
    const reg_rt = cpu.readRegister(rt);
    const reg_rs = cpu.readRegister(rs);
    if (reg_rt == 0) {
        // Undefined
        cpu.LO = MIN_I64;
        cpu.HI = 0;
    } else {
        cpu.LO = @as(u64, @bitCast(@divTrunc(reg_rs, reg_rt)));
        cpu.HI = @as(u64, @bitCast(@rem(reg_rs, reg_rt)));
    }
}

fn iDIV(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    const rt = getRt(instr);
    log("DIV {X} {X}", .{ rs, rt });
    const reg_rt: i32 = @as(i32, @intCast(cpu.readRegister(rt)));
    const reg_rs: i32 = @as(i32, @intCast(cpu.readRegister(rs)));
    if (reg_rt == 0) {
        // Undefined
        cpu.LO = MIN_I32;
        cpu.HI = 0;
    } else {
        cpu.LO = ext32(@bitCast(@divTrunc(reg_rs, reg_rt)));
        cpu.HI = ext32(@bitCast(@rem(reg_rs, reg_rt)));
    }
}

fn iDIVU(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    const rt = getRt(instr);
    log("DIVU {X} {X}", .{ rs, rt });
    const reg_rt: u32 = @truncate(cpu.readRegister(rt));
    const reg_rs: u32 = @truncate(cpu.readRegister(rs));
    if (reg_rt == 0) {
        // Undefined
        cpu.LO = MIN_I32;
        cpu.HI = 0;
    } else {
        cpu.LO = ext32(@bitCast(@divTrunc(reg_rs, reg_rt)));
        cpu.HI = ext32(@bitCast(@rem(reg_rs, reg_rt)));
    }
}

fn iDMFC(cpu: *Cpu, instr: u32, copN: usize) void {
    // TODO: NEED TO IMPLEMENT PROPERLY
    const rd = getRd(instr);
    const rt = getRt(instr);
    log("DMFC{d} {X} {X}", .{ copN, rd, rt });
    if (copN == 0) {
        cpu.reg_gpr[rt] = cpu.cp0.registers[rd];
    } else {
        if ((cpu.cp0.registers[12] >> 26) == 0) {
            if (rd & 1 == 0) {
                // Undefined
            } else {
                cpu.reg_gpr[rt] = ext32(@as(u32, @truncate(@as(u64, cpu.cp1.registers[rd - 1]) >> 32)));
            }
        } else {
            cpu.reg_gpr[rt] = ext32(@as(u32, @truncate(@as(u64, cpu.cp1.registers[rd - 1]))));
        }
    }
}

fn iDMULT(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    const rt = getRt(instr);
    log("DMULT {X} {X}", .{ rs, rt });
    const reg_rt: i128 = @intCast(cpu.readRegister(rt));
    const reg_rs: i128 = @intCast(cpu.readRegister(rs));
    const result = @mulWithOverflow(reg_rt, reg_rs)[0];
    cpu.LO = @truncate(@as(u128, @bitCast(result & std.math.maxInt(u64))));
    cpu.HI = @truncate(@as(u128, @bitCast(result >> 64)));
}

fn iDMULTU(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    const rt = getRt(instr);
    log("DMULTU {X} {X}", .{ rs, rt });
    const reg_rt: u128 = @intCast(cpu.readRegister(rt));
    const reg_rs: u128 = @intCast(cpu.readRegister(rs));
    const result = @mulWithOverflow(reg_rt, reg_rs)[0];
    cpu.LO = @truncate(result);
    cpu.LO = @truncate(result >> 64);
}

fn iDSLL(cpu: *Cpu, instr: u32) void {
    const rd = getRd(instr);
    const rt = getRt(instr);
    const sa = getSa(instr);
    log("DSLL {d} {d} {d}", .{ rd, rt, sa });
    cpu.reg_gpr[rd] = cpu.readRegister(rt) << sa;
}

fn iDSLLV(cpu: *Cpu, instr: u32) void {
    const rd = getRd(instr);
    const rt = getRt(instr);
    const rs = getRs(instr);
    log("DSLLV {d} {d} {d}", .{ rd, rt, rs });
    const scale: u6 = @truncate(cpu.readRegister(rs) & 0x3F);
    cpu.reg_gpr[rd] = cpu.readRegister(rt) << scale;
}

fn iDSLL32(cpu: *Cpu, instr: u32) void {
    const rd = getRd(instr);
    const rt = getRt(instr);
    const sa: u6 = @intCast(getSa(instr));
    log("DSLL32 {d} {d} {d}", .{ rd, rt, sa });
    const scale: u6 = @truncate(32 + sa);
    cpu.reg_gpr[rd] = cpu.readRegister(rt) << scale;
}

fn iDSRA(cpu: *Cpu, instr: u32) void {
    const rd = getRd(instr);
    const rt = getRt(instr);
    const sa = getSa(instr);
    log("DSRA {d} {d} {d}", .{ rd, rt, sa });
    const reg_rt = @as(i64, @bitCast(cpu.readRegister(rt)));
    cpu.reg_gpr[rd] = @as(u64, @bitCast(reg_rt >> sa));
}

fn iDSRAV(cpu: *Cpu, instr: u32) void {
    const rd = getRd(instr);
    const rt = getRt(instr);
    const rs = getRs(instr);
    log("DSRAV {d} {d} {d}", .{ rd, rt, rs });
    const reg_rt = @as(i64, @bitCast(cpu.readRegister(rt)));
    const scale: u6 = @truncate(cpu.readRegister(rs) & 0x3F);
    cpu.reg_gpr[rd] = @as(u64, @bitCast(reg_rt >> scale));
}

fn iDSRA32(cpu: *Cpu, instr: u32) void {
    const rd = getRd(instr);
    const rt = getRt(instr);
    const sa: u6 = @intCast(getSa(instr));
    log("DSRA32 {d} {d} {d}", .{ rd, rt, sa });
    const reg_rt = @as(i64, @bitCast(cpu.readRegister(rt)));
    const scale: u6 = @truncate(sa + 32);
    cpu.reg_gpr[rd] = @as(u64, @bitCast(reg_rt >> scale));
}

fn iDSRL(cpu: *Cpu, instr: u32) void {
    const rd = getRd(instr);
    const rt = getRt(instr);
    const sa = getSa(instr);
    log("DSRL {d} {d} {d}", .{ rd, rt, sa });
    cpu.reg_gpr[rd] = cpu.readRegister(rt) >> sa;
}

fn iDSRLV(cpu: *Cpu, instr: u32) void {
    const rd = getRd(instr);
    const rt = getRt(instr);
    const rs = getRs(instr);
    log("DSRLV {d} {d} {d}", .{ rd, rt, rs });
    cpu.reg_gpr[rd] = cpu.readRegister(rt) >> (cpu.readRegister(rs) & 0x3F);
}

fn iDSUB(cpu: *Cpu, instr: u32) void {
    const rd = getRd(instr);
    const rs = getRs(instr);
    const rt = getRt(instr);
    log("DSUB {X} {X} {X}", .{ rd, rs, rt });
    const result = @subWithOverflow(cpu.readRegister(rs), cpu.readRegister(rt));
    if (result[1] != 0) {
        // Overflowed
        // TODO: Integer overflow exception
    } else {
        cpu.reg_gpr[rd] = result[0];
    }
}

fn iDSUBU(cpu: *Cpu, instr: u32) void {
    const rd = getRd(instr);
    const rs = getRs(instr);
    const rt = getRt(instr);
    log("DSUBU {X} {X} {X}", .{ rd, rs, rt });
    const result = @subWithOverflow(cpu.readRegister(rs), cpu.readRegister(rt));
    if (result[1] != 0) {
        // Overflowed
        // TODO: Integer overflow exception
    } else {
        cpu.reg_gpr[rd] = result[0];
    }
}

// fn iDSRL32(cpu: *Cpu, instr: u32) void {
//     const rd = getRd(instr);
//     const rt = getRt(instr);
//     const sa = getSa(instr);
//     const scale: u6 = @truncate(32 + sa);
//     cpu.reg_gpr[rd] = cpu.readRegister(rt) >> scale;
//     log("DSRL32 {d} {d} {d}", .{ rd, rt, sa });
// }

fn iERET(cpu: *Cpu) void {
    log("ERET", .{});
    if (((cpu.cp0.registers[12] >> 2) & 1) == 1) {
        cpu.PC = cpu.cp0.registers[30];
        cpu.cp0.registers[12] &= 0xFFFFFFFD;
    } else {
        cpu.PC = cpu.cp0.registers[14];
        cpu.cp0.registers[12] &= 0xFFFFFFFE;
    }
}

fn iJ(cpu: *Cpu, instr: u32) void {
    const target: u28 = getTarget(instr) << 2;
    log("J {X}", .{target});
    cpu.PC = (cpu.PC & 0xFFFFFFFFF0000000) | target;
}

fn iJAL(cpu: *Cpu, instr: u32) void {
    const target = getTarget(instr) << 2;
    log("JAL {X}", .{target});
    cpu.reg_gpr[31] = cpu.nextPC;
    cpu.PC = (cpu.PC & 0xFFFFFFFFF0000000) | target;
}

fn iJALR(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    const rd = getRd(instr);
    log("JALR {X} {X}", .{ rd, rs });
    cpu.reg_gpr[rd] = cpu.nextPC;
    cpu.nextPC = rs;
}

fn iJR(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    log("JR {X}", .{rs});
    cpu.PC = rs;
}

fn iLB(cpu: *Cpu, instr: u32) void {
    const rt = getRt(instr);
    const offset = ext16(getL16(instr));
    const base = getRs(instr);
    log("LB {X} {X}({X})", .{ rt, offset, base });
    const vAddr = offset + cpu.readRegister(base);
    cpu.reg_gpr[rt] = ext8(cpu.read(vAddr, u8));
}

fn iLBU(cpu: *Cpu, instr: u32) void {
    const rt = getRt(instr);
    const offset = ext16(getL16(instr));
    const base = getRs(instr);
    log("LBU {X} {X}({X})", .{ rt, offset, base });
    const vAddr = offset + cpu.readRegister(base);
    cpu.reg_gpr[rt] = cpu.read(vAddr, u8);
}

fn iLD(cpu: *Cpu, instr: u32) void {
    const rt = getRt(instr);
    const offset = ext16(getL16(instr));
    const base = getRs(instr);
    log("LD {X} {X}({X})", .{ rt, offset, base });
    const vAddr = offset + cpu.readRegister(base);
    if ((vAddr & 7) != 0) {
        // TODO: Address error exception
    }
    cpu.reg_gpr[rt] = cpu.read(vAddr, u64);
}

fn iLDC(cpu: *Cpu, instr: u32) void {
    const base = getRs(instr);
    const rt = getRt(instr);
    const offset = ext16(getL16(instr));
    log("LDC {X} {X}({X})", .{ rt, offset, base });
    const vAddr = offset + cpu.readRegister(base);
    if ((vAddr & 7) != 0) {
        // TODO: Address error exception
    }
    if ((((cpu.cp0.registers[12] >> 26) & 1) == 0) and ((rt & 1) != 0)) {
        // UNDEFINED
    }
    cpu.cp1.registers[rt] = @bitCast(cpu.read(vAddr, u64));
}

fn iLDL(cpu: *Cpu, instr: u32) void {
    const base = getRs(instr);
    const offset = ext16(getL16(instr));
    const vAddr = offset + cpu.readRegister(base);
    const rt = getRt(instr);
    log("LDL {X} {X}({X})", .{ rt, offset, base });
    const mem = cpu.read(vAddr & 0xFFFFFFFF_FFFFFFF8, u64);
    const shift: u6 = @truncate((vAddr & 7) * 8);
    cpu.reg_gpr[rt] = (mem << shift) | (cpu.readRegister(rt) & ((MASK_1 << shift) - 1));
}

fn iLDR(cpu: *Cpu, instr: u32) void {
    const base = getRs(instr);
    const offset = ext16(getL16(instr));
    const vAddr = offset + cpu.readRegister(base);
    const rt = getRt(instr);
    log("LDR {X} {X}({X})", .{ rt, offset, base });
    const mem = cpu.read(vAddr & 0xFFFFFFFF_FFFFFFF8, u64);
    const shift: u6 = @truncate((vAddr & 7) * 8);
    cpu.reg_gpr[rt] = (mem >> (56 - shift)) | (cpu.readRegister(rt) & (MAX_U64 << (shift + 8)));
}

fn iLH(cpu: *Cpu, instr: u32) void {
    const base = getRs(instr);
    const offset = ext16(getL16(instr));
    const vAddr = offset + cpu.readRegister(base);
    if ((vAddr & 1) != 0) {
        // TODO: Address error exception
    }
    const rt = getRt(instr);
    log("LH {X}, {X}({X})", .{ rt, offset, base });
    cpu.reg_gpr[rt] = ext16(cpu.read(vAddr, u16));
}

fn iLHU(cpu: *Cpu, instr: u32) void {
    const base = getRs(instr);
    const offset = ext16(getL16(instr));
    const vAddr = offset + cpu.readRegister(base);
    if ((vAddr & 1) != 0) {
        // TODO: Address error exception
    }
    const rt = getRt(instr);
    log("LHU {X}, {X}({X})", .{ rt, offset, base });
    cpu.reg_gpr[rt] = cpu.read(vAddr, u16);
}

fn iLL(cpu: *Cpu, instr: u32) void {
    const base = getRs(instr);
    const offset = ext16(getL16(instr));
    const vAddr = offset + cpu.readRegister(base);
    if ((vAddr & 3) != 0) {
        // TODO: Address error exception
    }
    const rt = getRt(instr);
    log("LL {X}, {X}({X})", .{ rt, offset, base });
    const pAddr = cpu.virtualToPhysical(vAddr);
    cpu.reg_gpr[rt] = ext32(cpu.bus.read(pAddr, u32));
    cpu.cp1.registers[17] = @bitCast(pAddr);
    cpu.LLBit = 1;
}

fn iLLD(cpu: *Cpu, instr: u32) void {
    const base = getRs(instr);
    const offset = ext16(getL16(instr));
    const vAddr = offset + cpu.readRegister(base);
    if ((vAddr & 3) != 0) {
        // TODO: Address error exception
    }
    const rt = getRt(instr);
    log("LLD {X}, {X}({X})", .{ rt, offset, base });
    const pAddr = cpu.virtualToPhysical(vAddr);
    cpu.reg_gpr[rt] = cpu.bus.read(pAddr, u64);
    cpu.cp1.registers[17] = @bitCast(pAddr);
    cpu.LLBit = 1;
}

fn iLUI(cpu: *Cpu, instr: u32) void {
    const rt = getRt(instr);
    const imm = ext32(@as(u32, @intCast(getL16(instr))) << 16);
    log("LUI {X} {X}", .{ rt, imm });
    cpu.reg_gpr[rt] = imm;
}

fn iLW(cpu: *Cpu, instr: u32) void {
    const rt = getRt(instr);
    const offset = ext16(getL16(instr));
    const base = getRs(instr);
    log("LW {X} {X}({X})", .{ rt, offset, base });
    const vAddr = cpu.readRegister(base) + offset;
    if ((vAddr & 7) != 0) {
        // TODO Address error exception
    }
    cpu.reg_gpr[rt] = ext32(cpu.read(vAddr, u32));
}

fn iLWC(cpu: *Cpu, instr: u32) void {
    const rt = getRt(instr);
    const offset = ext16(getL16(instr));
    const base = getRs(instr);
    log("LWC {X} {X}({X}", .{ rt, offset, base });
    const vAddr = cpu.readRegister(base) + offset;
    if ((vAddr & 3) != 0) {
        // TODO Address error exception
    }
    if ((((cpu.cp0.registers[12] >> 26) & 1) == 0) and ((rt & 1) != 0)) {
        // UNDEFINED
    }
    cpu.cp1.set32(rt, @intCast(cpu.read(vAddr, u32)));
}

fn iLWL(cpu: *Cpu, instr: u32) void {
    const offset = ext16(getL16(instr));
    const rt = getRt(instr);
    const base = getRs(instr);
    log("LWL {X} {X}({X})", .{ rt, offset, base });
    const vAddr = cpu.readRegister(base) + offset;
    const mem = cpu.read(vAddr & 0xFFFFFFFF_FFFFFFFC, u32);
    const shift: u5 = @truncate((vAddr & 3) * 8);
    cpu.reg_gpr[rt] = ext32((mem << shift) |
        (@as(u32, @truncate(cpu.readRegister(rt))) & ~(MAX_U32 << shift)));
}

fn iLWR(cpu: *Cpu, instr: u32) void {
    const rt = getRt(instr);
    const offset = ext16(getL16(instr));
    const base = getRs(instr);
    log("LWR {X} {X}({X})", .{ rt, offset, base });
    const vAddr = cpu.readRegister(base) + offset;
    const mem = cpu.read(vAddr & 0xFFFFFFFF_FFFFFFFC, u32);
    const shift: u5 = @truncate((vAddr & 3) * 8);
    if (shift == 24) {
        cpu.reg_gpr[rt] = ext32(mem);
    } else {
        cpu.reg_gpr[rt] = (mem >> (24 - shift)) |
            (cpu.readRegister(rt) & (MAX_U32 << (shift + 8)));
    }
}

fn iLWU(cpu: *Cpu, instr: u32) void {
    const rt = getRt(instr);
    const offset = ext16(getL16(instr));
    const base = getRs(instr);
    log("LWU {X} {X}({X})", .{ rt, offset, base });
    const vAddr = cpu.readRegister(base) + offset;
    if ((vAddr & 3) != 0) {
        // TODO Address error exception
    }
    cpu.reg_gpr[rt] = cpu.read(vAddr, u32);
}

fn iMFC(cpu: *Cpu, instr: u32, copN: usize) void {
    const rt = getRt(instr);
    const rd = getRd(instr);
    log("MFC{d} {X} {X}", .{ copN, rt, rd });
    if (copN == 0) {
        cpu.reg_gpr[rt] = ext32(cpu.cp0.registers[rd]);
    } else {
        if ((cpu.cp0.registers[12] >> 26) == 0) {
            if (rd & 1 == 0) {
                cpu.reg_gpr[rt] = ext32(@as(u32, @truncate(@as(u64, cpu.cp1.registers[rd]))));
            } else {
                cpu.reg_gpr[rt] = ext32(@as(u32, @truncate(@as(u64, cpu.cp1.registers[rd - 1]) >> 32)));
            }
        } else {
            cpu.reg_gpr[rt] = ext32(@as(u32, @truncate(@as(u64, cpu.cp1.registers[rd - 1]))));
        }
    }
}

fn iMFHI(cpu: *Cpu, instr: u32) void {
    const rd = getRd(instr);
    log("MFHI {X}", .{rd});
    cpu.reg_gpr[rd] = cpu.HI;
}

fn iMFLO(cpu: *Cpu, instr: u32) void {
    const rd = getRd(instr);
    log("MFHI {X}", .{rd});
    cpu.reg_gpr[rd] = cpu.LO;
}

fn iMTC(cpu: *Cpu, instr: u32, copN: usize) void {
    const rt = getRt(instr);
    const rd = getRd(instr);
    log("MTC{d} {d} {X}", .{ copN, rt, rd });
    const data = cpu.readRegister(rt);
    if (copN == 0) {
        cpu.cp0.registers[rd] = @truncate(data);
    } else {
        cpu.cp1.registers[rd] = @bitCast(data);
    }
}

fn iMTHI(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    log("MTHI {X}", .{rs});
    cpu.HI = cpu.readRegister(rs);
}

fn iMTLO(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    log("MTLO {X}", .{rs});
    cpu.LO = cpu.readRegister(rs);
}

fn iMULT(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    const rt = getRt(instr);
    log("MULT {X} {X}", .{ rs, rt });
    const reg_rt: i64 = @bitCast(ext32(@as(u32, @truncate(cpu.readRegister(rt)))));
    const reg_rs: i64 = @bitCast(ext32(@as(u32, @truncate(cpu.readRegister(rs)))));
    const result = @mulWithOverflow(reg_rt, reg_rs)[0];
    cpu.LO = @truncate(@as(u64, @bitCast(result & MAX_U32)));
    cpu.HI = @truncate(@as(u64, @bitCast(result >> 32)));
}

fn iMULTU(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    const rt = getRt(instr);
    log("MULTU {X} {X}", .{ rs, rt });
    const reg_rt: u64 = @intCast(@as(u32, @truncate(cpu.readRegister(rt))));
    const reg_rs: u64 = @intCast(@as(u32, @truncate(cpu.readRegister(rs))));
    const result = @mulWithOverflow(reg_rt, reg_rs)[0];
    cpu.LO = @truncate(@as(u64, @bitCast(result & MAX_U32)));
    cpu.HI = @truncate(@as(u64, @bitCast(result >> 32)));
}

fn iNOR(cpu: *Cpu, instr: u32) void {
    const rd = getRd(instr);
    const rs = getRs(instr);
    const rt = getRt(instr);
    log("NOR {X} {X} {X}", .{ rd, rs, rt });
    cpu.reg_gpr[rd] = ~(cpu.readRegister(rs) | cpu.readRegister(rt));
}

fn iOR(cpu: *Cpu, instr: u32) void {
    const rd = getRd(instr);
    const rs = getRs(instr);
    const rt = getRt(instr);
    log("OR {X} {X} {X}", .{ rd, rs, rt });
    cpu.reg_gpr[rd] = cpu.readRegister(rs) | cpu.readRegister(rt);
}

fn iORI(cpu: *Cpu, instr: u32) void {
    const rt = getRt(instr);
    const rs = getRs(instr);
    const imm = getL16(instr);
    log("ORI {X} {X} {X}", .{ rt, rs, imm });
    cpu.reg_gpr[rt] = cpu.readRegister(rs) | imm;
}

fn iSB(cpu: *Cpu, instr: u32) void {
    const rt = getRt(instr);
    const offset = ext16(getL16(instr));
    const base = getRs(instr);
    log("SB {X} {X}({X})", .{ rt, offset, base });
    const vAddr = offset + cpu.readRegister(base);
    cpu.bus.write8(vAddr, @as(u8, @truncate(cpu.readRegister(rt))));
}

fn iSC(cpu: *Cpu, instr: u32) void {
    const rt = getRt(instr);
    const offset = ext16(getL16(instr));
    const base = getRs(instr);
    log("SC {X} {X}({X})", .{ rt, offset, base });
    const vAddr = offset + cpu.readRegister(base);
    if ((vAddr & 3) != 0) {
        // TODO Address exception error
    }
    if (cpu.LLBit == 1) {
        cpu.bus.write32(vAddr, @as(u32, @truncate(cpu.readRegister(rt))));
    }
    cpu.reg_gpr[rt] = cpu.LLBit;
}

fn iSCD(cpu: *Cpu, instr: u32) void {
    const rt = getRt(instr);
    const offset = ext16(getL16(instr));
    const base = getRs(instr);
    log("SCD {X} {X}({X})", .{ rt, offset, base });
    const vAddr = offset + cpu.readRegister(base);
    if ((vAddr & 7) != 0) {
        // TODO Address exception error
    }
    if (cpu.LLBit == 1) {
        cpu.bus.write64(vAddr, cpu.readRegister(rt));
    }
    cpu.reg_gpr[rt] = cpu.LLBit;
}

fn iSD(cpu: *Cpu, instr: u32) void {
    const rt = getRt(instr);
    const offset = ext16(getL16(instr));
    const base = getRs(instr);
    log("SD {X} {X}({X})", .{ rt, offset, base });
    const vAddr = offset + cpu.readRegister(base);
    if ((vAddr & 7) != 0) {
        // TODO Address exception error
    }
    cpu.bus.write64(vAddr, cpu.readRegister(rt));
}

fn iSDC(cpu: *Cpu, instr: u32) void {
    const rt = getRt(instr);
    const offset = ext16(getL16(instr));
    const base = getRs(instr);
    log("SDC {X} {X}({X})", .{ rt, offset, base });
    const vAddr = offset + cpu.readRegister(base);
    if ((vAddr & 7) != 0) {
        // TODO Address exception error
    }
    if ((((cpu.cp0.registers[12] >> 26) & 1) == 0) and ((rt & 1) != 0)) {
        // UNDEFINED
    }
    cpu.bus.write64(vAddr, @bitCast(cpu.cp1.registers[rt]));
}

fn iSDL(cpu: *Cpu, instr: u32) void {
    const rt = getRt(instr);
    const offset = ext16(getL16(instr));
    const base = getRs(instr);
    log("SDL {X} {X}({X})", .{ rt, offset, base });
    const vAddr = offset + cpu.readRegister(base);
    const mem = cpu.read(vAddr & 0xFFFFFFFF_FFFFFFF8, u64);
    const shift: u6 = @truncate((vAddr & 7) * 8);
    cpu.bus.write64(vAddr, (cpu.readRegister(rt) >> shift) |
        (mem & (MAX_U64 << (56 - shift + 8))));
}

fn iSDR(cpu: *Cpu, instr: u32) void {
    const rt = getRt(instr);
    const offset = ext16(getL16(instr));
    const base = getRs(instr);
    log("SDR {X} {X}({X})", .{ rt, offset, base });
    const vAddr = offset + cpu.readRegister(base);
    const mem = cpu.read(vAddr & 0xFFFFFFFF_FFFFFFF8, u64);
    const shift: u6 = @truncate((vAddr & 7) * 8);
    cpu.bus.write64(vAddr, (cpu.readRegister(rt) << shift) |
        (mem & (MAX_U64 >> (56 - shift + 8))));
}

fn iSH(cpu: *Cpu, instr: u32) void {
    const rt = getRt(instr);
    const offset = ext16(getL16(instr));
    const base = getRs(instr);
    log("SH {X} {X}({X})", .{ rt, offset, base });
    const vAddr = offset + cpu.readRegister(base);
    if ((vAddr & 1) != 0) {
        // TODO Address exception error
    }
    cpu.bus.write16(vAddr, @as(u16, @truncate(cpu.readRegister(rt))));
}

fn iSLL(cpu: *Cpu, instr: u32) void {
    const rd = getRd(instr);
    const rt = getRt(instr);
    const sa = getSa(instr);
    log("SLL {d} {d} {d}", .{ rd, rt, sa });
    cpu.reg_gpr[rd] = @as(u32, @truncate(cpu.readRegister(rt))) << sa;
}

fn iSLLV(cpu: *Cpu, instr: u32) void {
    const rd = getRd(instr);
    const rt = getRt(instr);
    const rs = getRs(instr);
    log("SLLV {d} {d} {d}", .{ rd, rt, rs });
    const shift: u5 = @truncate(cpu.readRegister(rs));
    cpu.reg_gpr[rd] = ext32(@as(u32, @truncate(cpu.readRegister(rd))) << shift);
}

fn iSLT(cpu: *Cpu, instr: u32) void {
    const rd = getRd(instr);
    const rs = getRs(instr);
    const rt = getRt(instr);
    log("SLT {X} {X} {X}", .{ rd, rs, rt });
    const reg_rs: i64 = @bitCast(cpu.readRegister(rs));
    const reg_rt: i64 = @bitCast(cpu.readRegister(rt));
    if (reg_rs < reg_rt) {
        cpu.reg_gpr[rd] = 1;
    } else {
        cpu.reg_gpr[rd] = 0;
    }
}

fn iSLTI(cpu: *Cpu, instr: u32) void {
    const rt = getRt(instr);
    const rs = getRs(instr);
    const imm = ext16(getL16(instr));
    log("SLTI {X} {X} {X}", .{ rt, rs, imm });
    const reg_rs: i64 = @bitCast(cpu.readRegister(rs));
    if (reg_rs < imm) {
        cpu.reg_gpr[rt] = 1;
    } else {
        cpu.reg_gpr[rt] = 0;
    }
}

fn iSLTIU(cpu: *Cpu, instr: u32) void {
    const rt = getRt(instr);
    const rs = getRs(instr);
    const imm = ext16(getL16(instr));
    log("SLTIU {X} {X} {X}", .{ rt, rs, imm });
    const reg_rs = cpu.readRegister(rs);
    if (reg_rs < imm) {
        cpu.reg_gpr[rt] = 1;
    } else {
        cpu.reg_gpr[rt] = 0;
    }
}

fn iSLTU(cpu: *Cpu, instr: u32) void {
    const rt = getRt(instr);
    const rs = getRs(instr);
    const rd = getRd(instr);
    log("SLTU {X} {X} {X}", .{ rd, rt, rs });
    if (cpu.readRegister(rs) < cpu.readRegister(rt)) {
        cpu.reg_gpr[rd] = 1;
    } else {
        cpu.reg_gpr[rd] = 0;
    }
}

fn iSRA(cpu: *Cpu, instr: u32) void {
    const rd = getRd(instr);
    const rt = getRt(instr);
    const sa = getSa(instr);
    log("SRA {d} {d} {d}", .{ rd, rt, sa });
    const reg_rt: i32 = @bitCast(@as(u32, @truncate(cpu.readRegister(rt))));
    cpu.reg_gpr[rd] = ext32(@as(u32, @bitCast(reg_rt >> sa)));
}

fn iSRAV(cpu: *Cpu, instr: u32) void {
    const rd = getRd(instr);
    const rt = getRt(instr);
    const rs = getRs(instr);
    log("SRAV {d} {d} {d}", .{ rd, rt, rs });
    const scale: u5 = @truncate(cpu.readRegister(rs));
    const reg_rt: u32 = @truncate(cpu.readRegister(rt));
    cpu.reg_gpr[rd] = ext32(reg_rt >> scale);
}

fn iSRL(cpu: *Cpu, instr: u32) void {
    const rd = getRd(instr);
    const rt = getRt(instr);
    const sa = getSa(instr);
    log("SRL {d} {d} {d}", .{ rd, rt, sa });
    const reg_rt: u32 = @truncate(cpu.readRegister(rt));
    cpu.reg_gpr[rd] = ext32(reg_rt >> sa);
}

fn iSRLV(cpu: *Cpu, instr: u32) void {
    const rd = getRd(instr);
    const rt = getRt(instr);
    const rs = getRs(instr);
    log("SRLV {d} {d} {d}", .{ rd, rt, rs });
    const shift: u5 = @truncate(cpu.readRegister(rs));
    cpu.reg_gpr[rd] = ext32(@as(u32, @truncate(cpu.readRegister(rt))) >> shift);
}

fn iSUB(cpu: *Cpu, instr: u32) void {
    const rd = getRd(instr);
    const rs = getRs(instr);
    const rt = getRt(instr);
    log("SUB {X} {X} {X}", .{ rd, rs, rt });
    const reg_rt: i32 = @bitCast(@as(u32, @truncate(cpu.readRegister(rt))));
    const reg_rs: i32 = @bitCast(@as(u32, @truncate(cpu.readRegister(rs))));
    const result = @subWithOverflow(reg_rs, reg_rt);
    if (result[1] != 0) {
        // Overflowed
    } else {
        cpu.reg_gpr[rd] = ext32(@bitCast(result[0]));
    }
}

fn iSUBU(cpu: *Cpu, instr: u32) void {
    const rd = getRd(instr);
    const rs = getRs(instr);
    const rt = getRt(instr);
    log("SUBU {X} {X} {X}", .{ rd, rs, rt });
    const reg_rt: u32 = @truncate(cpu.readRegister(rt));
    const reg_rs: u32 = @truncate(cpu.readRegister(rs));
    const result = @subWithOverflow(reg_rs, reg_rt);
    cpu.reg_gpr[rd] = ext32(result[0]);
}

fn iSW(cpu: *Cpu, instr: u32) void {
    const rt = getRt(instr);
    const base = getRs(instr);
    const offset = ext16(getL16(instr));
    log("SW {X} {X}({X})", .{ rt, offset, base });
    const vAddr = offset + cpu.readRegister(base);
    if ((vAddr & 3) != 0) {
        // TODO Address error exception
    }
    cpu.bus.write32(vAddr, @truncate(cpu.readRegister(rt)));
}

fn iSWC(cpu: *Cpu, instr: u32) void {
    const rt = getRt(instr);
    const base = getRs(instr);
    const offset = ext16(getL16(instr));
    log("SWC {X} {X}({X})", .{ rt, offset, base });
    const vAddr = offset + cpu.readRegister(base);
    if ((vAddr & 3) != 0) {
        // TODO Address error exception
    }
    cpu.bus.write32(vAddr, cpu.cp1.get32(rt));
    // @bitCast(@as(u32, @truncate(cpu.cp1.registers[rt]))));
}

fn iSWL(cpu: *Cpu, instr: u32) void {
    const rt = getRt(instr);
    const base = getRs(instr);
    const offset = ext16(getL16(instr));
    log("SWL {X} {X}({X})", .{ rt, offset, base });
    const vAddr = offset + cpu.readRegister(base);
    const mem = cpu.read(vAddr & 0xFFFFFFFF_FFFFFFFC, u32);
    const shift: u5 = @truncate((vAddr & 3) * 8);
    cpu.bus.write32(
        vAddr & 0xFFFFFFFF_FFFFFFFC,
        (@as(u32, @truncate(cpu.readRegister(rt))) >> shift) |
            (mem & ~(MAX_U32 >> shift)),
    );
}

fn iSWR(cpu: *Cpu, instr: u32) void {
    const rt = getRt(instr);
    const base = getRs(instr);
    const offset = ext16(getL16(instr));
    log("SWR {X} {X}({X})", .{ rt, offset, base });
    const vAddr = offset + cpu.readRegister(base);
    const mem = cpu.read(vAddr & 0xFFFFFFFF_FFFFFFFC, u32);
    const shift: u5 = @truncate((vAddr & 3) * 8);
    cpu.bus.write32(
        vAddr & 0xFFFFFFFF_FFFFFFFC,
        (@as(u32, @truncate(cpu.readRegister(rt))) << (24 - shift)) |
            (mem & (MAX_U32 >> (8 + shift))),
    );
}

fn iTEQ(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    const rt = getRt(instr);
    log("TEQ {X} {X}", .{ rs, rt });
    if (@as(i64, @bitCast(cpu.readRegister(rs))) == @as(i64, @bitCast(cpu.readRegister(rt)))) {
        // TODO: Trap Exception
    }
}

fn iTEQI(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    const imm: i64 = @bitCast(ext16(getL16(instr)));
    log("TEQI {X} {X}", .{ rs, imm });
    if (@as(i64, @bitCast(cpu.readRegister(rs))) == imm) {
        // TODO: Trap Exception
    }
}

fn iTGE(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    const rt = getRt(instr);
    log("TGE {X} {X}", .{ rs, rt });
    if (@as(i64, @bitCast(cpu.readRegister(rs))) >= @as(i64, @bitCast(cpu.readRegister(rt)))) {
        // TODO: Trap Exception
    }
}

fn iTGEI(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    const imm: i64 = @bitCast(ext16(getL16(instr)));
    log("TGEI {X} {X}", .{ rs, imm });
    if (@as(i64, @bitCast(cpu.readRegister(rs))) >= imm) {
        // TODO: Trap Exception
    }
}

fn iTGEIU(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    const imm = ext16(getL16(instr));
    log("TGEIU {X} {X}", .{ rs, imm });
    if (cpu.readRegister(rs) >= imm) {
        // TODO: Trap Exception
    }
}

fn iTGEU(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    const rt = getRt(instr);
    log("TGEU {X} {X}", .{ rs, rt });
    if (cpu.readRegister(rs) >= cpu.readRegister(rt)) {
        // TODO: Trap Exception
    }
}

fn iTLBP(cpu: *Cpu) void {
    log("TLBP", .{});
    const entryHi = cpu.cp0.registers[10];
    for (0..32) |i| {
        const entry = cpu.TLBEntries[i];
        if (entry.entry_hi.vpn2 != (entryHi >> 13 & 0xFFFFFFE)) {
            continue;
        }

        if (!entry.entry_hi.g and entry.entry_hi.asid != (entryHi & 0xFF)) {
            continue;
        }

        cpu.cp0.registers[0] = i;
        return;
    }
    cpu.cp0.registers[0] = 1 << 31;
}

fn iTLBR(cpu: *Cpu) void {
    log("TLBP", .{});
    const entry: TLBEntry = cpu.tlbEntries[cpu.cp1.registers[0]];
    cpu.cp0.registers[5] = entry.pagemask.mask << 13;
    var g: u64 = 0;
    if (entry.entry_hi.g) g = 1;
    cpu.cp0.registers[10] =
        (@as(u64, entry.entry_hi.asid) | g << 12 |
        @as(u64, entry.entry_hi.vpn2) << 13 | @as(u64, entry.entry_hi.r) << 62) &
        ~(@as(u64, entry.pagemask.mask) << 13);
    cpu.cp0.registers[3] = @as(u64, entry.entry_lo1.pfn) << 6 |
        @as(u64, entry.entry_lo1.c) << 3 |
        @as(u64, entry.entry_lo1.d) << 2 |
        @as(u64, entry.entry_lo1.v) < 1 |
        g;
    cpu.cp0.registers[2] = @as(u64, entry.entry_lo0.pfn) << 6 |
        @as(u64, entry.entry_lo0.c) << 3 |
        @as(u64, entry.entry_lo0.d) << 2 |
        @as(u64, entry.entry_lo0.v) < 1 |
        g;
}

fn iTLBWI(cpu: *Cpu) void {
    log("TLBWI", .{});
    const entry: TLBEntry = cpu.tlbEntries[cpu.cp1.registers[0]];
    const g = 1 == @as(u1, @truncate(cpu.cp0.registers[2] & cpu.cp0.registers[3]));
    entry.pagemask.mask = @truncate(cpu.cp0.registers[5] >> 13);
    entry.entry_hi.g = g;
    entry.entry_hi.r = @truncate(cpu.cp0.registers[10] >> 62);
    entry.entry_hi.vpn2 = @truncate(cpu.cp0.registers[10] >> 13);
    entry.entry_hi.asid = @truncate(cpu.cp0.registers[10]);
    entry.entry_lo1.d = @truncate(cpu.cp0.registers[3] >> 2);
    entry.entry_lo1.v = @truncate(cpu.cp0.registers[3] >> 1);
    entry.entry_lo1.c = @truncate(cpu.cp0.registers[3] >> 3);
    entry.entry_lo1.pfn = @truncate(cpu.cp0.registers[3] >> 6);
    entry.entry_lo0.d = @truncate(cpu.cp0.registers[3] >> 2);
    entry.entry_lo0.v = @truncate(cpu.cp0.registers[3] >> 1);
    entry.entry_lo0.c = @truncate(cpu.cp0.registers[3] >> 3);
    entry.entry_lo0.pfn = @truncate(cpu.cp0.registers[3] >> 6);
}

fn iTLBWR(cpu: *Cpu) void {
    log("TLBWI", .{});
    const entry: TLBEntry = cpu.tlbEntries[cpu.cp1.registers[1]];
    const g = 1 == @as(u1, @truncate(cpu.cp0.registers[2] & cpu.cp0.registers[3]));
    entry.pagemask.mask = @truncate(cpu.cp0.registers[5] >> 13);
    entry.entry_hi.g = g;
    entry.entry_hi.r = @truncate(cpu.cp0.registers[10] >> 62);
    entry.entry_hi.vpn2 = @truncate(cpu.cp0.registers[10] >> 13);
    entry.entry_hi.asid = @truncate(cpu.cp0.registers[10]);
    entry.entry_lo1.d = @truncate(cpu.cp0.registers[3] >> 2);
    entry.entry_lo1.v = @truncate(cpu.cp0.registers[3] >> 1);
    entry.entry_lo1.c = @truncate(cpu.cp0.registers[3] >> 3);
    entry.entry_lo1.pfn = @truncate(cpu.cp0.registers[3] >> 6);
    entry.entry_lo0.d = @truncate(cpu.cp0.registers[3] >> 2);
    entry.entry_lo0.v = @truncate(cpu.cp0.registers[3] >> 1);
    entry.entry_lo0.c = @truncate(cpu.cp0.registers[3] >> 3);
    entry.entry_lo0.pfn = @truncate(cpu.cp0.registers[3] >> 6);
}

fn iTLT(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    const rt = getRt(instr);
    log("TLT {X} {X}", .{ rs, rt });
    if (@as(i64, @bitCast(cpu.readRegister(rs))) < @as(i64, @bitCast(cpu.readRegister(rt)))) {
        // TODO Trap Exception
    }
}

fn iTLTI(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    const imm: i64 = @bitCast(ext16(getL16(instr)));
    log("TLTI {X} {X}", .{ rs, imm });
    if (@as(i64, @bitCast(cpu.readRegister(rs))) < imm) {
        // TODO Trap Exception
    }
}

fn iTLTIU(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    const imm = ext16(getL16(instr));
    log("TLTIU {X} {X}", .{ rs, imm });
    if (cpu.readRegister(rs) < imm) {
        // TODO Trap Exception
    }
}

fn iTLTU(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    const rt = getRt(instr);
    log("TLTU {X} {X}", .{ rs, rt });
    if (cpu.readRegister(rs) < cpu.readRegister(rt)) {
        // TODO Trap Exception
    }
}

fn iTNE(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    const rt = getRt(instr);
    log("TNE {X} {X}", .{ rs, rt });
    if (@as(i64, @bitCast(cpu.readRegister(rs))) != @as(i64, @bitCast(cpu.readRegister(rt)))) {
        // TODO Trap Exception
    }
}

fn iTNEI(cpu: *Cpu, instr: u32) void {
    const rs = getRs(instr);
    const imm: i64 = @bitCast(ext16(getL16(instr)));
    log("TNEI {X} {X}", .{ rs, imm });
    if (@as(i64, @bitCast(cpu.readRegister(rs))) != imm) {
        // TODO Trap Exception
    }
}

fn iXOR(cpu: *Cpu, instr: u32) void {
    const rd = getRd(instr);
    const rs = getRs(instr);
    const rt = getRt(instr);
    log("XOR {X} {X} {X}", .{ rd, rs, rt });
    cpu.reg_gpr[rd] = cpu.readRegister(rs) ^ cpu.readRegister(rt);
}

fn iXORI(cpu: *Cpu, instr: u32) void {
    const rt = getRt(instr);
    const rs = getRs(instr);
    const imm: u64 = @intCast(getL16(instr));
    log("XORI {X} {X} {X}", .{ rt, rs, imm });
    cpu.reg_gpr[rt] = cpu.readRegister(rs) ^ imm;
}

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
