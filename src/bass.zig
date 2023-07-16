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
    const tag_name = @tagName(@as(ErrorInt, @enumFromInt(error_int)));

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
    window: usize,
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

    @setRuntimeSafety(false);
    var success = c.BASS_Init(
        device_int,
        frequency orelse 44100,
        @as(u32, @bitCast(flags)),
        @ptrFromInt(window),
        null,
    );
    @setRuntimeSafety(true);

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
    return @as(Version, @bitCast(c.BASS_GetVersion()));
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
    pub const Union = packed union {
        na: u2,
        sample: Override,
        stream: Prescan,
    };

    pub const Prescan = enum(u2) {
        none = 0,
        prescan = 2,
    };

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
    @"union": Union = .{ .na = 0 },
    ///Automatically free the stream when it stops/ends
    auto_free: bool = false,
    ///Restrict the download rate of an internet file stream
    restrict_rate: bool = false,
    _padding: u19 = 0,
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

pub const ActiveState = enum(u32) {
    stopped = 0,
    playing = 1,
    stalled = 2,
    paused = 3,
    paused_device = 4,
};

pub const PositionMode = enum(u32) {
    byte = 0,
    music_order = 1,
    ogg = 3,
    end = 0x10,
    loop = 0x11,
};

pub const PositionFlags = packed struct(u6) {
    decode_to: bool = false,
    flush: bool = false,
    inexact: bool = false,
    relative: bool = false,
    reset: bool = false,
    scan: bool = false,
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

        pub fn stop(self: Type) !void {
            const success = c.BASS_ChannelStop(self.handle);
            if (success != 0) return;
            return bassErrorToZigError(c.BASS_ErrorGetCode());
        }

        pub fn activeState(self: Type) !ActiveState {
            var state: ActiveState = @enumFromInt(c.BASS_ChannelIsActive(self.handle));

            //As per docs, the state being `stopped` could mean stopped, or an error, so we need to check
            if (state == .stopped) {
                var err = bassErrorToZigError(c.BASS_ErrorGetCode());
                if (err != Error.Ok) {
                    return err;
                }
            }

            return state;
        }

        pub fn setAttribute(self: Type, attribute: ChannelAttribute, value: f32) !void {
            const success = c.BASS_ChannelSetAttribute(self.handle, @intFromEnum(attribute), value);

            if (success == 0) {
                return bassErrorToZigError(c.BASS_ErrorGetCode());
            }
        }

        pub fn getSecondPosition(self: Type) !f64 {
            var byte_pos = c.BASS_ChannelGetPosition(self.handle, c.BASS_POS_BYTE);

            if (byte_pos == @as(u64, @bitCast(@as(i64, -1)))) {
                return bassErrorToZigError(c.BASS_ErrorGetCode());
            }

            var second_pos = c.BASS_ChannelBytes2Seconds(self.handle, byte_pos);

            if (second_pos < 0) {
                return bassErrorToZigError(c.BASS_ErrorGetCode());
            }

            return second_pos;
        }

        pub fn getLength(self: Type, mode: PositionMode) !u64 {
            //Assert mode is byte, music_order, or ogg, as per the docs
            std.debug.assert(mode == .byte or mode == .music_order or mode == .ogg);

            var position = c.BASS_ChannelGetLength(self.handle, @intFromEnum(mode));
            //If position is -1, then return an error
            if (position == @as(u64, @bitCast(@as(i64, -1)))) {
                return bassErrorToZigError(c.BASS_ErrorGetCode());
            }

            return position;
        }

        pub fn setPosition(self: Type, position: u64, mode: PositionMode, flags: PositionFlags) !void {
            //Turn the mode into an int
            var mode_int = @intFromEnum(mode);
            //Add in the bits from the flags, shift 24bits left, making the least signifigant bit be `0x1000000` (flush)
            mode_int |= @as(u32, @intCast(@as(u6, @bitCast(flags)))) << 24;

            var success = c.BASS_ChannelSetPosition(self.handle, position, mode_int);
            if (success != 0) return;
            return bassErrorToZigError(c.BASS_ErrorGetCode());
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
    const handle = c.BASS_StreamCreate(frequency, channels, @as(u32, @bitCast(flags)), if (proc != null) @as(*const c.STREAMPROC, @ptrCast(proc)) else null, user);

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

    const handle = c.BASS_StreamCreateFile(is_mem, data_ptr, offset, length, @as(u32, @bitCast(flags)));

    if (handle == 0) {
        return bassErrorToZigError(c.BASS_ErrorGetCode());
    }

    return .{ .handle = handle };
}

pub const ConfigOption = enum(u32) {
    ///Playback buffer length
    buffer = 0,
    ///Update period of playback buffers
    update_period = 1,
    global_sample_volume = 4,
    global_stream_volume = 5,
    global_music_volume = 6,
    ///Volume translation curve
    curve_volume = 7,
    ///Panning translation curve
    curve_pan = 8,
    ///Pass 32-bit floating-point sample data to all DSP functions?
    float_dsp = 9,
    ///The 3D algorithm used for software mixed 3D channels
    three_dimensional_algorithm = 10,
    ///TIme to wait for a server to respond to a connection request
    network_timeout = 11,
    ///Internet download buffer length
    network_buffer = 12,
    ///Prevent channels being played when the output is paused
    pause_noplay = 13,
    ///Amount to pre-buffer before playing internet streams
    network_prebuffer = 15,
    ///Use passive mode in FTP connections?
    network_passive = 18,
    ///Recording buffer length
    recording_buffer = 19,
    ///Process URLs in playlists
    network_playlist = 21,
    ///IT virtual channels
    music_virtual = 22,
    ///File format verification length
    verify = 23,
    ///Number of update threads
    update_threads = 24,
    ///Output device buffer length
    dev_buffer = 27,
    ///Undocumented. Complain on the forums if you need this! https://www.un4seen.com/doc/#bass/BASS_SetConfig.html
    recording_loopback = 28,
    ///Undocumented. Complain on the forums if you need this! https://www.un4seen.com/doc/#bass/BASS_SetConfig.html
    vista_truepos = 30,
    ///Audio session configuration on iOS
    ios_session = 34,
    ///Include a "Default" entry in the output device list?
    default_device = 36,
    network_read_timeout = 37,
    ///Undocumented. Complain on the forums if you need this! https://www.un4seen.com/doc/#bass/BASS_SetConfig.html
    vista_speakers = 38,
    ///Undocumented. Complain on the forums if you need this! https://www.un4seen.com/doc/#bass/BASS_SetConfig.html
    ios_speaker = 39,
    ///Disable the use of Media Foundation
    disable_media_foundation = 40,
    ///Undocumented. Complain on the forums if you need this! https://www.un4seen.com/doc/#bass/BASS_SetConfig.html
    handles = 41,
    ///Unicode device information
    unicode = 42,
    ///Default sample rate conversion quality
    default_sample_rate_conversion = 43,
    ///Default sample rate conversion quality for samples
    sample_default_sample_rate_conversion = 44,
    ///Asynchronous file reading buffer length
    async_file_buffer = 45,
    ///Pre-scan chained OGG files
    ogg_prescan = 47,
    ///Play the audio from videos using Media Foundation
    media_foundation_video = 48,
    ///Undocumented. Complain on the forums if you need this! https://www.un4seen.com/doc/#bass/BASS_SetConfig.html
    airplay = 49,
    ///Do not stop an output device when nothing is playing
    device_nonstop = 50,
    ///Undocumented. Complain on the forums if you need this! https://www.un4seen.com/doc/#bass/BASS_SetConfig.html
    ios_nocategory = 51,
    ///File format verification length for internet streams
    verify_network = 52,
    ///Output device update period
    device_period = 53,
    ///Undocumented. Complain on the forums if you need this! https://www.un4seen.com/doc/#bass/BASS_SetConfig.html
    float = 54,
    ///Undocumented. Complain on the forums if you need this! https://www.un4seen.com/doc/#bass/BASS_SetConfig.html
    network_seek = 56,
    ///Disable the use of Android media codecs
    disable_android_media = 58,
    ///Maximum nested playlist processing depth
    network_playlist_depth = 59,
    ///Undocumented. Complain on the forums if you need this! https://www.un4seen.com/doc/#bass/BASS_SetConfig.html
    network_prebuffer_wait = 60,
    ///Session ID to use for output on Android
    android_session_id = 62,
    ///Retain Windows mixer settings across sessions
    wasapi_persist = 65,
    ///Use WASAPI when recording
    record_using_wasapi = 66,
    ///Enable AAudio output on Android
    android_aaudio = 67,
    ///Use the same handle for a sample and its single channel
    sample_onehandle = 69,
    ///Request Shoutcast metadata?
    network_shoutcast_metadata = 71,
    ///Restricted download rate
    network_restricted_rate = 72,
    ///Include a "Default" entry in the recording device list
    default_recording_device = 73,
    ///Default playback ramping
    no_ramp = 74,
};

pub fn setConfig(option: ConfigOption, value: u32) !void {
    var success = c.BASS_SetConfig(@intFromEnum(option), value);

    if (success != 0) return;
    return bassErrorToZigError(c.BASS_ErrorGetCode());
}

pub fn deinit() void {
    var success = c.BASS_Free();

    if (success != 0) return;

    std.debug.panicExtra(null, null, "Unknown error during BASS_Free??? err:{d}\n", .{c.BASS_ErrorGetCode()});
}
