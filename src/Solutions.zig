const Solver = @import("solver.zig").Solver;

const solutions: []const []const Solver = &.{
    // 2015
    &.{
        @import("y15/d01.zig").solve,
        @import("y15/d02.zig").solve,
        @import("y15/d03.zig").solve,
        @import("y15/d04.zig").solve,
        @import("y15/d05.zig").solve,
        @import("y15/d06.zig").solve,
        @import("y15/d07.zig").solve,
        @import("y15/d08.zig").solve,
        @import("y15/d09.zig").solve,
        @import("y15/d10.zig").solve,
        @import("y15/d11.zig").solve,
        @import("y15/d12.zig").solve,
        @import("y15/d13.zig").solve,
        @import("y15/d14.zig").solve,
        @import("y15/d15.zig").solve,
        @import("y15/d16.zig").solve,
        @import("y15/d17.zig").solve,
        @import("y15/d18.zig").solve,
        @import("y15/d19.zig").solve,
        @import("y15/d20.zig").solve,
        @import("y15/d21.zig").solve,
        @import("y15/d22.zig").solve,
        @import("y15/d23.zig").solve,
        @import("y15/d24.zig").solve,
        @import("y15/d25.zig").solve,
    },
    // 2016
    &.{},
    // 2017
    &.{},
    // 2018
    &.{},
    // 2019
    &.{},
    // 2020
    &.{},
    // 2021
    &.{},
    // 2022
    &.{},
    // 2023
    &.{},
    // 2024
    &.{},
    // 2025
    &.{
        @import("y25/d01.zig").solve,
        @import("y25/d02.zig").solve,
        @import("y25/d03.zig").solve,
        @import("y25/d04.zig").solve,
        @import("y25/d05.zig").solve,
        @import("y25/d06.zig").solve,
        @import("y25/d07.zig").solve,
    },
};

pub fn get(year: u8, day: u8) !Solver {
    const yr_idx = year - 15;
    const day_idx = day - 1;
    if (yr_idx >= solutions.len or day_idx >= solutions[yr_idx].len) {
        return error.UnknownSolution;
    }
    return solutions[yr_idx][day_idx];
}
