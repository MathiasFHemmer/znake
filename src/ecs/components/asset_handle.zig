const std = @import("std");
const Writer = std.io.Writer;

pub const MAX_ASSET_KEY_LEN = 64;

pub const AssetHandle = struct {
    pub const Error = error{
        InvalidKeyLength,
    };
    key: [MAX_ASSET_KEY_LEN]u8 = undefined,
    len: u8 = 0,

    pub fn init(key: []const u8) AssetHandle {
        var handle: AssetHandle = .{};
        const copy_len = @min(key.len, MAX_ASSET_KEY_LEN);
        @memcpy(handle.key[0..copy_len], key[0..copy_len]);
        handle.len = @intCast(copy_len);
        return handle;
    }

    pub fn deinit(self: *AssetHandle) void {
        // no allocations, nothing to free
        _ = self;
    }

    pub fn serialize(self: AssetHandle, writer: *std.io.Writer) !void {
        try writer.writeInt(u8, self.len, .little);
        try writer.writeAll(self.key[0..self.len]);
    }

    pub fn deserialize(reader: *std.io.Reader, allocator: std.mem.Allocator) !AssetHandle {
        _ = allocator;
        var handle: AssetHandle = .{};
        handle.len = try reader.takeInt(u8, .little);
        if (handle.len > MAX_ASSET_KEY_LEN)
            return error.InvalidKeyLength;
        const key_slice = try reader.take(handle.len);
        @memcpy(handle.key[0..handle.len], key_slice);
        return handle;
    }

    pub fn asSlice(self: *const AssetHandle) []const u8 {
        return self.key[0..self.len];
    }
};
