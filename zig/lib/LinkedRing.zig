const Self = @This();

first: *Node,

pub const Node = struct {
    prev: *Node = undefined,
    next: *Node = undefined,
};

pub fn init(node: *Node) Self {
    node.next = node;
    node.prev = node;
    return .{ .first = node };
}

pub fn insertAfter(_: Self, existing_node: *Node, new_node: *Node) void {
    new_node.next = existing_node.next;
    new_node.prev = existing_node;
    new_node.prev.next = new_node;
    new_node.next.prev = new_node;
}

pub fn remove(self: *Self, node: *Node) void {
    node.prev.next = node.next;
    node.next.prev = node.prev;
    if (node == self.first) {
        self.first = node.next;
    }
}
