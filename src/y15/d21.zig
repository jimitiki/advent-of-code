const std = @import("std");

const solver = @import("../solver.zig");
const Parser = @import("../Parser.zig");

// TODO: Generalize the algorithm so that it could work for any combination of "gear slots"

const Item = struct {
    cost: u32,
    damage: u32,
    armor: u32,

    const Self = @This();

    fn init(cost: u32, damage: u32, armor: u32) Self {
        return .{ .cost = cost, .damage = damage, .armor = armor };
    }

    fn costsLessThan(_: void, lhs: Self, rhs: Self) bool {
        return (lhs.cost < rhs.cost);
    }
};

const weapons = [_]Item{
    .init(8, 4, 0),
    .init(10, 5, 0),
    .init(25, 6, 0),
    .init(40, 7, 0),
    .init(74, 8, 0),
};

const armors = [_]Item{
    .init(0, 0, 0),
    .init(13, 0, 1),
    .init(31, 0, 2),
    .init(53, 0, 3),
    .init(75, 0, 4),
    .init(102, 0, 5),
};

const rings = [_]Item{
    .init(0, 0, 0),
    .init(0, 0, 0),
    .init(20, 0, 1),
    .init(25, 1, 0),
    .init(40, 0, 2),
    .init(50, 2, 0),
    .init(80, 0, 3),
    .init(100, 3, 0),
};

const Fighter = struct {
    hp: u32,
    damage: u32,
    armor: u32,

    const Self = @This();

    fn turnsSurvived(self: Self, attacker: Self) u32 {
        const dmg_taken = if (self.armor >= attacker.damage) 1 else attacker.damage - self.armor;
        return std.math.divCeil(u32, self.hp, dmg_taken) catch unreachable;
    }
};

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    _ = tools;
    const boss: Fighter = .{
        .hp = try parseBossStat(try input.reader.takeDelimiter('\n') orelse return error.InvalidInput),
        .damage = try parseBossStat(try input.reader.takeDelimiter('\n') orelse return error.InvalidInput),
        .armor = try parseBossStat(try input.reader.takeDelimiter('\n') orelse return error.InvalidInput),
    };

    return .{ minCost(boss), maxCost(boss) };
}

pub const solve = solver.intSolver(u32, solveInt);

fn parseBossStat(input: []const u8) Parser.Error!u32 {
    var parser: Parser = .init(input, .{});
    var stat_name = try parser.take();
    while (stat_name[stat_name.len - 1] != ':') : (stat_name = try parser.take()) {}
    return parser.takeInt(u32);
}

fn minCost(boss: Fighter) u32 {
    var min_cost: u32 = std.math.maxInt(u32);
    for (rings, 0..) |lring, i| {
        for (rings[i + 1 ..]) |rring| {
            for (armors) |armor| {
                for (weapons) |weapon| {
                    const cost = lring.cost + rring.cost + armor.cost + weapon.cost;
                    if (cost >= min_cost) continue;
                    const dmg = lring.damage + rring.damage + armor.damage + weapon.damage;
                    const def = lring.armor + rring.armor + armor.armor + weapon.armor;
                    if (playerWins(.{ .hp = 100, .damage = dmg, .armor = def }, boss)) {
                        min_cost = cost;
                    }
                }
            }
        }
    }
    return min_cost;
}

fn maxCost(boss: Fighter) u32 {
    var max_cost: u32 = 0;
    for (rings, 0..) |lring, i| {
        for (rings[i + 1 ..]) |rring| {
            for (armors) |armor| {
                for (weapons) |weapon| {
                    const cost = lring.cost + rring.cost + armor.cost + weapon.cost;
                    if (cost <= max_cost) continue;
                    const dmg = lring.damage + rring.damage + armor.damage + weapon.damage;
                    const def = lring.armor + rring.armor + armor.armor + weapon.armor;
                    if (!playerWins(.{ .hp = 100, .damage = dmg, .armor = def }, boss)) {
                        max_cost = cost;
                    }
                }
            }
        }
    }
    return max_cost;
}

fn playerWins(player: Fighter, boss: Fighter) bool {
    return player.turnsSurvived(boss) >= boss.turnsSurvived(player);
}
