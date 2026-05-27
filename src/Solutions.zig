const Solver = @import("solver.zig").Solver;

const solutions: []const []const Solver = &.{
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
