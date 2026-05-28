const std = @import("std");

const solver = @import("../solver.zig");

// TODO: Stop relying on a global mutable variable
// TODO: Improve handling of hard mode so that the initial HP doesn't have to be set to 49 for
//       part 2 to work

const Wizard = struct {
    hp: u32,
    mana: u32,
    armor: u32 = 0,
    shield: u32 = 0,
    poison: u32 = 0,
    recharge: u32 = 0,
};

const Spell = enum { magic_missile, drain, shield, poison, recharge };
const spells = [_]Spell{ .magic_missile, .drain, .shield, .poison, .recharge };

fn solveInt(_: std.mem.Allocator, input: *std.Io.Reader) solver.Error!struct { ?u32, ?u32 } {
    const boss_hp = try parseBossStat(try input.takeDelimiter('\n'));
    const boss_atk = try parseBossStat(try input.takeDelimiter('\n'));

    std.debug.print("{} - {}\n", .{ boss_hp, boss_atk });

    const answer1 = minMana(boss_atk, boss_hp, .{ .hp = 50, .mana = 500 }, 0, false, 0);
    min_spent = std.math.maxInt(u32);
    const answer2 = minMana(boss_atk, boss_hp, .{ .hp = 49, .mana = 500 }, 0, true, 0);
    return .{ answer1, answer2 };
}

pub const solve = solver.intSolver(u32, solveInt);

fn parseBossStat(input: ?[]const u8) error{InvalidInput}!u32 {
    if (input) |string| {
        return for (string[0 .. string.len - 2], 0..) |char, i| {
            if (char == ':') {
                break std.fmt.parseUnsigned(u32, string[i + 2 ..], 10) catch error.InvalidInput;
            }
        } else error.InvalidInput;
    } else {
        return error.InvalidInput;
    }
}

var min_spent: u32 = std.math.maxInt(u32);

fn minMana(boss_atk: u32, boss_hp: u32, wizard: Wizard, mana_spent: u32, hard_mode: bool, depth: usize) u32 {
    if (mana_spent >= min_spent) return std.math.maxInt(u32);
    if (boss_hp == 0) {
        min_spent = mana_spent;
        return mana_spent;
    }
    var min: u32 = std.math.maxInt(u32);
    for (spells) |spell| {
        const hp_new, const wizard_new, const cost = doTurn(boss_atk, boss_hp, wizard, spell, hard_mode) orelse continue;
        const m = minMana(boss_atk, hp_new, wizard_new, mana_spent + cost, hard_mode, depth + 1);
        min = @min(min, m);
    }
    return min;
}

fn doTurn(attack: u32, boss_hp_init: u32, wizard_init: Wizard, spell: Spell, hard_mode: bool) ?struct { u32, Wizard, u32 } {
    var boss_hp = boss_hp_init;
    var wizard = wizard_init;

    // Wizard's turn
    if (hard_mode) {
        wizard.hp -|= 1;
    }
    if (wizard.hp == 0) {
        return null;
    }
    applyEffects(&boss_hp, &wizard);
    if (boss_hp == 0) {
        return .{ boss_hp, wizard, 0 };
    }
    const cost: u32, const spell_fn: *const fn (*u32, *Wizard) bool = switch (spell) {
        .magic_missile => .{ 53, magicMissile },
        .drain => .{ 73, drain },
        .shield => .{ 113, shield },
        .poison => .{ 173, poison },
        .recharge => .{ 229, recharge },
    };
    if (cost > wizard.mana or !spell_fn(&boss_hp, &wizard)) return null;
    wizard.mana -= cost;

    // Boss' turn
    applyEffects(&boss_hp, &wizard);
    if (boss_hp > 0) {
        wizard.hp -|= @max(1, attack -| wizard.armor);
    }
    return .{ boss_hp, wizard, cost };
}

fn applyEffects(boss_hp: *u32, wizard: *Wizard) void {
    if (wizard.shield > 0) {
        wizard.armor = 7;
        wizard.shield -= 1;
    } else {
        wizard.armor = 0;
    }
    if (wizard.poison > 0) {
        boss_hp.* -|= 3;
        wizard.poison -= 1;
    }
    if (wizard.recharge > 0) {
        wizard.mana += 101;
        wizard.recharge -= 1;
    }
}

fn magicMissile(boss_hp: *u32, _: *Wizard) bool {
    boss_hp.* -|= 4;
    return true;
}
fn drain(boss_hp: *u32, wizard: *Wizard) bool {
    boss_hp.* -|= 2;
    wizard.hp += 2;
    return true;
}
fn shield(_: *u32, wizard: *Wizard) bool {
    if (wizard.shield > 0) {
        return false;
    }
    wizard.shield = 6;
    return true;
}
fn poison(_: *u32, wizard: *Wizard) bool {
    if (wizard.poison > 0) {
        return false;
    }
    wizard.poison = 6;
    return true;
}
fn recharge(_: *u32, wizard: *Wizard) bool {
    if (wizard.recharge > 0) {
        return false;
    }
    wizard.recharge = 5;
    return true;
}
