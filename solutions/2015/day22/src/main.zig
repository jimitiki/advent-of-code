const std = @import("std");

const lib = @import("lib");
const Boilerplate = lib.Boilerplate;

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

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var bp = try Boilerplate.init(init, &stdout_buffer, &read_buffer);
    defer bp.deinit();

    var input = &bp.input_reader.interface;
    const boss_hp = try parseBossStat(try input.takeDelimiter('\n'));
    const boss_atk = try parseBossStat(try input.takeDelimiter('\n'));

    const answer = minMana(boss_atk, boss_hp, .{ .hp = 50, .mana = 500 }, 0, std.math.maxInt(u32));
    var stdout = &bp.stdout_writer.interface;
    try stdout.print("{}\n", .{answer});
    try stdout.flush();
}

fn parseBossStat(input: ?[]const u8) !u32 {
    if (input) |string| {
        return for (string[0 .. string.len - 2], 0..) |char, i| {
            if (char == ':') {
                break try std.fmt.parseUnsigned(u32, string[i + 2 ..], 10);
            }
        } else error.InvalidInput;
    } else {
        return error.InvalidInput;
    }
}

fn minMana(boss_atk: u32, boss_hp: u32, wizard: Wizard, mana_spent: u32, min_spent: u32) u32 {
    if (mana_spent >= min_spent) return std.math.maxInt(u32);
    if (boss_hp == 0) {
        return mana_spent;
    }
    var min: u32 = min_spent;
    for (spells) |spell| {
        const hp_new, const wizard_new, const cost = doTurn(boss_atk, boss_hp, wizard, spell) orelse continue;
        min = @min(min, minMana(boss_atk, hp_new, wizard_new, mana_spent + cost, min));
    }
    return min;
}

fn doTurn(attack: u32, boss_hp_init: u32, wizard_init: Wizard, spell: Spell) ?struct { u32, Wizard, u32 } {
    var boss_hp = boss_hp_init;
    var wizard = wizard_init;
    const cost: u32, const spell_fn: *const fn (*u32, *Wizard) bool = switch (spell) {
        .magic_missile => .{ 53, magicMissile },
        .drain => .{ 73, drain },
        .shield => .{ 113, shield },
        .poison => .{ 173, poison },
        .recharge => .{ 229, recharge },
    };
    if (cost > wizard.mana or !spell_fn(&boss_hp, &wizard)) return null;
    wizard.mana -= cost;
    wizard.armor = 0;
    applyEffects(&boss_hp, &wizard);
    if (boss_hp > 0) {
        wizard.hp -|= @max(1, attack -| wizard.armor);
        if (wizard.hp == 0) {
            return null;
        } else {
            applyEffects(&boss_hp, &wizard);
        }
    }
    return .{ boss_hp, wizard, cost };
}

fn applyEffects(boss_hp: *u32, wizard: *Wizard) void {
    if (wizard.shield > 0) {
        wizard.armor = 7;
        wizard.shield -= 1;
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
