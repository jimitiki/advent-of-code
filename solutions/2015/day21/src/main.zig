const std = @import("std");

const lib = @import("lib");
const Boilerplate = lib.Boilerplate;
const WordIterator = lib.parse.WordIterator;

const Item = struct {
    cost: u32,
    damage: u32,
    armor: u32,

    const Self = @This();

    fn costsLessThan(_: void, lhs: Self, rhs: Self) bool {
        return (lhs.cost < rhs.cost);
    }
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

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var bp = try Boilerplate.init(init, &stdout_buffer, &read_buffer);
    defer bp.deinit();

    // Read boss stats
    var stdout = &bp.stdout_writer.interface;
    var input = &bp.input_reader.interface;
    const boss: Fighter = .{
        .hp = try parseBossStat(try input.takeDelimiter('\n')),
        .damage = try parseBossStat(try input.takeDelimiter('\n')),
        .armor = try parseBossStat(try input.takeDelimiter('\n')),
    };

    // Read shop items
    const dir = try std.Io.Dir.openDirAbsolute(bp.io, bp.args[1], .{});
    defer dir.close(bp.io);
    var shop_file = try dir.openFile(bp.io, "data/shop.txt", .{});
    defer shop_file.close(bp.io);
    var r = shop_file.reader(bp.io, &read_buffer);
    const reader = &r.interface;
    var weapons = try parseItems(bp.arena, reader);
    defer weapons.deinit(bp.arena);
    var armor = try parseItems(bp.arena, reader);
    defer armor.deinit(bp.arena);
    var rings = try parseItems(bp.arena, reader);
    defer rings.deinit(bp.arena);

    // Add options for empty slots
    try armor.append(bp.arena, .{ .cost = 0, .damage = 0, .armor = 0 });
    try rings.append(bp.arena, .{ .cost = 0, .damage = 0, .armor = 0 });
    try rings.append(bp.arena, .{ .cost = 0, .damage = 0, .armor = 0 });

    // Sort the items from cheapest to most expensive. This will save a little bit of time.
    std.sort.pdq(Item, weapons.items, {}, Item.costsLessThan);
    std.sort.pdq(Item, armor.items, {}, Item.costsLessThan);
    std.sort.pdq(Item, rings.items, {}, Item.costsLessThan);

    const optimizer: *const fn (
        Fighter,
        []const Item,
        []const Item,
        []const Item,
    ) u32 = if (bp.part == .p1) minCost else maxCost;
    const answer = optimizer(boss, weapons.items, armor.items, rings.items);
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

fn parseItems(allocator: std.mem.Allocator, reader: *std.Io.Reader) !std.ArrayList(Item) {
    _ = try reader.takeDelimiter('\n');
    var item_list: std.ArrayList(Item) = .empty;
    while (try reader.takeDelimiter('\n')) |line| {
        if (line.len == 0) break;
        try item_list.append(allocator, try parseItem(line));
    }
    return item_list;
}

fn parseItem(string: []const u8) !Item {
    var it: WordIterator = .initRev(string);
    return .{
        .armor = try std.fmt.parseUnsigned(u32, it.next().?, 10),
        .damage = try std.fmt.parseUnsigned(u32, it.next().?, 10),
        .cost = try std.fmt.parseUnsigned(u32, it.next().?, 10),
    };
}

fn minCost(boss: Fighter, weapons: []const Item, armor: []const Item, rings: []const Item) u32 {
    var min_cost: u32 = std.math.maxInt(u32);
    for (rings, 0..) |lring, i| {
        for (rings[i + 1 ..]) |rring| {
            for (armor) |a| {
                for (weapons) |weapon| {
                    const cost = lring.cost + rring.cost + a.cost + weapon.cost;
                    if (cost >= min_cost) continue;
                    const dmg = lring.damage + rring.damage + a.damage + weapon.damage;
                    const def = lring.armor + rring.armor + a.armor + weapon.armor;
                    if (playerWins(.{ .hp = 100, .damage = dmg, .armor = def }, boss)) {
                        min_cost = cost;
                    }
                }
            }
        }
    }
    return min_cost;
}

fn maxCost(boss: Fighter, weapons: []const Item, armor: []const Item, rings: []const Item) u32 {
    var max_cost: u32 = 0;
    for (rings, 0..) |lring, i| {
        for (rings[i + 1 ..]) |rring| {
            for (armor) |a| {
                for (weapons) |weapon| {
                    const cost = lring.cost + rring.cost + a.cost + weapon.cost;
                    if (cost <= max_cost) continue;
                    const dmg = lring.damage + rring.damage + a.damage + weapon.damage;
                    const def = lring.armor + rring.armor + a.armor + weapon.armor;
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
