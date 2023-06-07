const std = @import("std");
const builtin = @import("builtin");

const c = @cImport(@cInclude("bass.h"));

pub const InitFlags = packed struct {
    ///Unused, would limit output to 8-bit
    bits_8: bool = false,
    ///Limit output to mono
    mono: bool = false,
    ///Unused, would enable 3d audio(?)
    three_dimensional: bool = false,
    ///Limit output to 16-bit
    bits_16: bool = false,
    ///Reinitialize
    reinit: bool = false,
    ///Unused, calculates latency?
    latency: bool = false,
    ///Unused, unknown reason
    cp_speakers: bool = false,
    ///Force enabling of speaker assignment
    speakers: bool = false,
    ///Ignore speaker arrangement
    no_speaker: bool = false,
    ///Use ALSA "dmix" plugin
    dmix: bool = false,
    ///Set device sample rate
    frequency: bool = false,
    ///Limit output to stereo
    stereo: bool = false,
    ///Hog/Exclusive mode
    hog: bool = false,
    ///Use AudioTrack output
    audiotrack: bool = false,
    ///Use DirectSound output
    dsound: bool = false,
    ///Disable hardware/fastpath output
    software: bool = false,
    _padding: u16 = 0,
};

const ErrorInt = enum(c_int) {
    Ok = 0, // all is OK
    Memory = 1, // memory error
    FileOpen = 2, // can't open the file
    Driver = 3, // can't find a free/valid driver
    BufferLost = 4, // the sample buffer was lost
    Handle = 5, // invalid handle
    Format = 6, // unsupported sample format
    Position = 7, // invalid position
    Init = 8, // BASS_Init has not been successfully called
    Start = 9, // BASS_Start has not been successfully called
    Ssl = 10, // SSL/HTTPS support isn't available
    Reinit = 11, // device needs to be reinitialized
    Already = 14, // already initialized/paused/whatever
    NotAudio = 17, // file does not contain audio
    NoChannel = 18, // can't get a free channel
    IllegalType = 19, // an illegal type was specified
    IllegalParam = 20, // an illegal parameter was specified
    No3d = 21, // no 3D support
    NoEAX = 22, // no EAX support
    IllegalDevice = 23, // illegal device number
    NotPlaying = 24, // not playing
    IllegalSampleRate = 25, // illegal sample rate
    NotFileStream = 27, // the stream is not a file stream
    NoHardware = 29, // no hardware voices available
    Empty = 31, // the file has no sample data
    NoNetwork = 32, // no internet connection could be opened
    Create = 33, // couldn't create the file
    NoEffects = 34, // effects are not available
    NotAvailable = 37, // requested data/action is not available
    Decoding = 38, // the channel is/isn't a "decoding channel"
    MissingDX = 39, // a sufficient DirectX version is not installed
    Timeout = 40, // connection timedout
    UnknownFileFormat = 41, // unsupported file format
    Speaker = 42, // unavailable speaker
    InvalidBassVersion = 43, // invalid BASS version (used by add-ons)
    UnavailableCodec = 44, // codec is not available/supported
    Ended = 45, // the channel/file has ended
    Busy = 46, // the device is busy
    Unstreamable = 47, // unstreamable file
    UnsupportedProtocol = 48, // unsupported protocol
    Denied = 49, // access denied
    Unknown = -1, // some other mystery problem
};

pub const Error = error{
    Ok,
    Memory,
    FileOpen,
    Driver,
    BufferLost,
    Handle,
    Format,
    Position,
    Init,
    Start,
    Ssl,
    Reinit,
    Already,
    NotAudio,
    NoChannel,
    IllegalType,
    IllegalParam,
    No3d,
    NoEAX,
    IllegalDevice,
    NotPlaying,
    IllegalSampleRate,
    NotFileStream,
    NoHardware,
    Empty,
    NoNetwork,
    Create,
    NoEffects,
    NotAvailable,
    Decoding,
    MissingDX,
    Timeout,
    UnknownFileFormat,
    Speaker,
    InvalidBassVersion,
    UnavailableCodec,
    Ended,
    Busy,
    Unstreamable,
    UnsupportedProtocol,
    Denied,
    Unknown,
};

fn bassErrorToZigError(error_int: c_int) Error {
    const tag_name = @tagName(@intToEnum(ErrorInt, error_int));

    const error_type_info: std.builtin.Type.ErrorSet = @typeInfo(Error).ErrorSet.?;
    inline for (error_type_info.?) |real_error_type| {
        if (std.mem.eql(u8, real_error_type.name, tag_name)) {
            return @field(Error, real_error_type.name);
        }
    }

    return Error.Unknown;
}

pub fn init(
    device: union(enum) {
        default: void,
        no_sound: void,
        device: c_int,
    },
    frequency: ?u32,
    flags: InitFlags,
    window: ?*anyopaque,
) !void {
    const device_int = switch (device) {
        .default => -1,
        .no_sound => 0,
        .device => |dev| dev,
    };

    //If the user specifies a frequency,
    if (frequency != null)
        //Assert the frequency flag is set
        std.debug.assert(flags.frequency);

    var success = c.BASS_Init(
        device_int,
        frequency orelse 44100,
        @bitCast(u32, flags),
        if (builtin.os.tag == .windows) @ptrCast(c.HWND, @alignCast(@alignOf(c.HWND), window)) else window,
        null,
    );

    if (success != 0) return;

    return bassErrorToZigError(c.BASS_ErrorGetCode());
}

pub const Version = packed struct(u32) {
    patch: u8,
    revision: u8,
    minor: u8,
    major: u8,
};

pub fn getVersion() Version {
    return @bitCast(Version, c.BASS_GetVersion());
}

pub fn setVolume(volume: f32) !void {
    var success = c.BASS_SetVolume(volume);

    if (success != 0) return;

    return bassErrorToZigError(c.BASS_ErrorGetCode());
}

pub fn getVolume() f32 {
    return c.BASS_GetVolume();
}

pub const StreamFlags = packed struct(u32) {
    pub const Override = enum(u2) {
        none = 0,
        ///Override the lowest volume stream when this one starts
        override_lowest_volume = 1,
        ///Override the longest playing stream when this one starts
        override_longest_playing = 2,
        ///Override the furthest stream from the listener when this one starts (3D only)
        override_furthest_from_listener = 3,
    };

    ///8-bit audio
    bits_8: bool = false,
    ///32-bit floating point audio
    float: bool = false,
    ///Mono
    mono: bool = false,
    ///Looped
    loop: bool = false,
    ///Enable 3D functionality
    three_dimensional: bool = false,
    ///Unused, disable hardware accelleration?
    software: bool = false,
    ///Mute at max distance
    mute_max: bool = false,
    ///Unused, unknown possible use
    vam: bool = false,
    ///Unused, enabled FX on the stream?
    fx: bool = false,
    ///What should happen when there are too many streams playing and this one tries to play?
    override_settings: Override = .none,
    _padding: u21 = 0,
};

pub const ChannelAttribute = enum(u32) {
    frequency = 1,
    volume = 2,
    pan = 3,
    eax_mix = 4,
    no_buffer = 5,
    variable_bit_rate = 6,
    cpu = 7,
    source = 8,
    net_resume = 9,
    scan_info = 10,
    no_ramp = 11,
    bitrate = 12,
    buffer = 13,
    granule = 14,
    user = 15,
    tail = 16,
    push_limit = 17,
    download_proc = 18,
    vol_dsp = 19,
    vol_dsp_priority = 20,
};

fn ChannelFunctions(comptime Type: type) type {
    return struct {
        pub fn play(self: Type, restart: bool) !void {
            const success = c.BASS_ChannelPlay(self.handle, if (restart) 1 else 0);
            if (success != 0) return;
            return bassErrorToZigError(c.BASS_ErrorGetCode());
        }

        pub fn pause(self: Type) !void {
            const success = c.BASS_ChannelPause(self.handle);
            if (success != 0) return;
            return bassErrorToZigError(c.BASS_ErrorGetCode());
        }

        pub fn setAttribute(self: Type, attribute: ChannelAttribute, value: f32) !void {
            const success = c.BASS_ChannelSetAttribute(self.handle, @enumToInt(attribute), value);

            if (success == 0) {
                return bassErrorToZigError(c.BASS_ErrorGetCode());
            }
        }

        pub fn getSecondPosition(self: Type) !f64 {
            var byte_pos = c.BASS_ChannelGetPosition(self.handle, c.BASS_POS_BYTE);

            if (byte_pos == @bitCast(u64, @as(i64, -1))) {
                return bassErrorToZigError(c.BASS_ErrorGetCode());
            }

            var second_pos = c.BASS_ChannelBytes2Seconds(self.handle, byte_pos);

            if (second_pos < 0) {
                return bassErrorToZigError(c.BASS_ErrorGetCode());
            }

            return second_pos;
        }
    };
}

pub const Stream = extern struct {
    pub usingnamespace ChannelFunctions(Stream);

    handle: u32,

    pub fn deinit(self: Stream) void {
        var success = c.BASS_StreamFree(self.handle);

        if (success == 0) {
            std.debug.panicExtra(null, null, "Unknown error during BASS_Free??? err:{d}\n", .{c.BASS_ErrorGetCode()});
        }
    }
};

pub const StreamProc = fn (Stream, ?*anyopaque, u32, ?*anyopaque) callconv(.C) u32;

pub fn createStream(frequency: u32, channels: u32, flags: StreamFlags, proc: ?*const StreamProc, user: ?*anyopaque) !Stream {
    const handle = c.BASS_StreamCreate(frequency, channels, @bitCast(u32, flags), if (proc != null) @ptrCast(*const c.STREAMPROC, proc) else null, user);

    if (handle == 0) {
        return bassErrorToZigError(c.BASS_ErrorGetCode());
    }

    return .{ .handle = handle };
}

pub fn createFileStream(
    source: union(enum) {
        file: struct {
            path: [:0]const u8,
            length: u64 = 0,
        },
        memory: []const u8,
    },
    offset: u64,
    flags: StreamFlags,
) !Stream {
    const is_mem: c.BOOL = switch (source) {
        .memory => 1,
        .file => 0,
    };

    const data_ptr: [*]const u8 = switch (source) {
        .memory => |memory| memory.ptr,
        .file => |file| file.path.ptr,
    };

    const length: usize = switch (source) {
        .memory => |memory| memory.len,
        .file => |file| file.length,
    };

    const handle = c.BASS_StreamCreateFile(is_mem, data_ptr, offset, length, @bitCast(u32, flags));

    if (handle == 0) {
        return bassErrorToZigError(c.BASS_ErrorGetCode());
    }

    return .{ .handle = handle };
}

pub fn deinit() void {
    var success = c.BASS_Free();

    if (success != 0) return;

    std.debug.panicExtra(null, null, "Unknown error during BASS_Free??? err:{d}\n", .{c.BASS_ErrorGetCode()});
}
