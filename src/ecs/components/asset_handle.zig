pub const MAX_ASSET_KEY_LEN = 64;

pub const AssetHandle = struct {
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

    pub fn serialize(self: AssetHandle, writer: anytype) !void {
        try writer.writeInt(u8, self.len, .little);
        try writer.writeAll(self.key[0..self.len]);
        // optionally pad to fixed size for alignment
        const padding = MAX_ASSET_KEY_LEN - self.len;
        if (padding > 0) try writer.writeByteNTimes(0, padding);
    }

    pub fn deserialize(reader: anytype) !AssetHandle {
        var handle: AssetHandle = .{};
        handle.len = try reader.takeInt(u8, .little);
        if (handle.len > MAX_ASSET_KEY_LEN)
            return error.InvalidKeyLength;
        try reader.readNoEof(handle.key[0..handle.len]);
        // skip padding if present
        if (MAX_ASSET_KEY_LEN > handle.len) {
            var skip_buf: [MAX_ASSET_KEY_LEN]u8 = undefined;
            const skip = MAX_ASSET_KEY_LEN - handle.len;
            try reader.readNoEof(skip_buf[0..skip]);
        }
        return handle;
    }

    pub fn asSlice(self: *const AssetHandle) []const u8 {
        return self.key[0..self.len];
    }
};
