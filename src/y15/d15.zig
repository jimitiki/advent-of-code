const std = @import("std");

const solver = @import("../solver.zig");
const WordIterator = @import("../parse.zig").WordIterator;

const Ingredient = struct {
    calories: i64,
    capacity: i64,
    durability: i64,
    flavor: i64,
    texture: i64,
};

fn solveInt(tools: solver.Tools) solver.Error!struct { ?i64, ?i64 } {
    var ingredients: std.ArrayList(Ingredient) = .empty;
    defer ingredients.deinit(tools.gpa);
    while (try tools.input.takeDelimiter('\n')) |line| {
        ingredients.append(tools.gpa, try parseIngredient(line)) catch unreachable;
    }

    const quantities = tools.gpa.alloc(u8, ingredients.items.len) catch unreachable;
    defer tools.gpa.free(quantities);
    return .{
        maxScore(ingredients.items, quantities, 0, 0, null),
        maxScore(ingredients.items, quantities, 0, 0, 500),
    };
}

pub const solve = solver.intSolver(i64, solveInt);

fn parseIngredient(string: []const u8) error{InvalidInput}!Ingredient {
    var it: WordIterator = .{ .string = string, .omit_punctuation = true };
    _ = it.next();
    return .{
        .capacity = try parseProperty(&it),
        .durability = try parseProperty(&it),
        .flavor = try parseProperty(&it),
        .texture = try parseProperty(&it),
        .calories = try parseProperty(&it),
    };
}

fn parseProperty(it: *WordIterator) error{InvalidInput}!i64 {
    _ = it.next();
    return std.fmt.parseInt(i64, it.next().?, 10) catch error.InvalidInput;
}

fn maxScore(ingredients: []const Ingredient, quantities: []u8, count: usize, amount_used: usize, calorie_target: ?i64) i64 {
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

fn computeScore(ingredients: []const Ingredient, quantities: []const u8, calorie_target: ?i64) i64 {
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
    if (calorie_target) |target| {
        if (calories != target) return 0;
    }
    return @max(0, capacity) * @max(0, durability) * @max(0, flavor) * @max(0, texture);
}
