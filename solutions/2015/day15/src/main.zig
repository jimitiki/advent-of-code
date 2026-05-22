const std = @import("std");

const lib = @import("lib");
const Boilerplate = lib.Boilerplate;

const Ingredient = struct {
    calories: i64,
    capacity: i64,
    durability: i64,
    flavor: i64,
    texture: i64,
};

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var bp = try Boilerplate.init(init, &stdout_buffer, &read_buffer);
    defer bp.deinit();

    var stdout = &bp.stdout_writer.interface;
    var input = &bp.input_reader.interface;
    var ingredients: std.ArrayList(Ingredient) = .empty;
    while (try input.takeDelimiter('\n')) |line| {
        try ingredients.append(bp.arena, try parseIngredient(line));
    }

    const quantities = try bp.arena.alloc(u8, ingredients.items.len);
    defer bp.arena.free(quantities);
    try stdout.print("{}\n", .{maxScore(ingredients.items, quantities, 0, 0, bp.part == .p2)});
    try stdout.flush();
}

fn parseIngredient(string: []const u8) !Ingredient {
    var it: lib.parse.WordIterator = .{ .string = string, .omit_punctuation = true };
    _ = it.next();
    return .{
        .capacity = try parseProperty(&it),
        .durability = try parseProperty(&it),
        .flavor = try parseProperty(&it),
        .texture = try parseProperty(&it),
        .calories = try parseProperty(&it),
    };
}

fn parseProperty(it: *lib.parse.WordIterator) !i64 {
    _ = it.next();
    return try std.fmt.parseInt(i64, it.next().?, 10);
}

fn maxScore(ingredients: []const Ingredient, quantities: []u8, count: usize, amount_used: usize, calorie_target: bool) i64 {
    if (count == ingredients.len - 1) {
        quantities[count] = @truncate(100 - amount_used);
        return computeScore(ingredients, quantities, calorie_target);
    }
    var max: i64 = 0;
    for (0..100 - amount_used) |amount| {
        quantities[count] = @truncate(amount);
        max = @max(max, maxScore(ingredients, quantities, count + 1, amount_used + amount, calorie_target));
    }
    return max;
}

fn computeScore(ingredients: []const Ingredient, quantities: []const u8, calorie_target: bool) i64 {
    var capacity: i64 = 0;
    var durability: i64 = 0;
    var flavor: i64 = 0;
    var texture: i64 = 0;
    var calories: i64 = 0;
    for (ingredients, quantities) |ingredient, quantity| {
        capacity += quantity * ingredient.capacity;
        durability += quantity * ingredient.durability;
        flavor += quantity * ingredient.flavor;
        texture += quantity * ingredient.texture;
        calories += quantity * ingredient.calories;
    }
    if (calorie_target and calories != 500) {
        return 0;
    } else {
        return @max(0, capacity) * @max(0, durability) * @max(0, flavor) * @max(0, texture);
    }
}
