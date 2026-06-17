const std = @import("std");
const Alignment = std.mem.Alignment;
const Allocator = std.mem.Allocator;

const Self = @This();

backing_allocator: Allocator,
current: usize = 0,
peak: usize = 0,
total: usize = 0,

pub fn init(backing_allocator: Allocator) Self {
    return .{ .backing_allocator = backing_allocator };
}

pub fn allocator(self: *Self) Allocator {
    return .{
        .ptr = self,
        .vtable = &.{
            .alloc = alloc,
            .resize = resize,
            .remap = remap,
            .free = free,
        },
    };
}

fn alloc(ctx: *anyopaque, len: usize, alignment: Alignment, ret_addr: usize) ?[*]u8 {
    const self: *Self = @ptrCast(@alignCast(ctx));
    if (self.backing_allocator.rawAlloc(len, alignment, ret_addr)) |ptr| {
        self.total += len;
        self.current += len;
        self.peak = @max(self.peak, self.current);
        return ptr;
    } else {
        return null;
    }
}

fn resize(ctx: *anyopaque, memory: []u8, alignment: Alignment, new_len: usize, ret_addr: usize) bool {
    const self: *Self = @ptrCast(@alignCast(ctx));
    if (self.backing_allocator.rawResize(memory, alignment, new_len, ret_addr)) {
        self.total += new_len -| memory.len;
        self.current -= memory.len;
        self.current += new_len;
        self.peak = @max(self.peak, self.current);
        return true;
    } else {
        return false;
    }
}

fn remap(ctx: *anyopaque, memory: []u8, alignment: Alignment, new_len: usize, ret_addr: usize) ?[*]u8 {
    const self: *Self = @ptrCast(@alignCast(ctx));
    if (self.backing_allocator.rawRemap(memory, alignment, new_len, ret_addr)) |ptr| {
        self.total += new_len;
        self.current -= memory.len;
        self.current += new_len;
        self.peak = @max(self.peak, self.current);
        return ptr;
    } else {
        return null;
    }
}

fn free(ctx: *anyopaque, memory: []u8, alignment: Alignment, ret_addr: usize) void {
    const self: *Self = @ptrCast(@alignCast(ctx));
    self.backing_allocator.rawFree(memory, alignment, ret_addr);
    self.current -= memory.len;
}
