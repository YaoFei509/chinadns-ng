const std = @import("std");
const builtin = @import("builtin");
const build_opts = @import("build_opts");
const modules = @import("modules.zig");
const tests = @import("tests.zig");
const c = @import("c.zig");
const cc = @import("cc.zig");
const g = @import("g.zig");
const log = @import("log.zig");
const opt = @import("opt.zig");
const net = @import("net.zig");
const ipset = @import("ipset.zig");
const server = @import("server.zig");
const EvLoop = @import("EvLoop.zig");
const co = @import("co.zig");
const groups = @import("groups.zig");

// TODO:
// - alloc_only allocator
// - vla/alloca allocator (another stack)

// ============================================================================

/// the rewrite is to avoid generating unnecessary code in release mode.
pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    @setCold(true);
    if (builtin.mode == .Debug or builtin.mode == .ReleaseSafe)
        std.builtin.default_panic(msg, error_return_trace, ret_addr)
    else
        cc.abort();
}

// ============================================================================

const _debug = builtin.mode == .Debug;

const gpa_t = if (_debug) std.heap.GeneralPurposeAllocator(.{}) else void;
var _gpa: gpa_t = undefined;

const pipe_fds_t = if (_debug) [2]c_int else void;
var _pipe_fds: pipe_fds_t = undefined;

fn on_sigusr1(_: c_int) callconv(.C) void {
    const v: u8 = 0;
    _ = cc.write(_pipe_fds[1], std.mem.asBytes(&v));
}

fn memleak_checker() void {
    defer co.terminate(@frame(), @frameSize(memleak_checker));

    cc.pipe2(&_pipe_fds, c.O_CLOEXEC | c.O_NONBLOCK) orelse {
        log.err(@src(), "pipe() failed: (%d) %m", .{cc.errno()});
        @panic("pipe failed");
    };
    defer _ = cc.close(_pipe_fds[1]); // write end

    // register sig_handler
    _ = cc.signal(c.SIGUSR1, on_sigusr1);

    const fdobj = EvLoop.Fd.new(_pipe_fds[0]);
    defer fdobj.free(); // read end

    while (true) {
        var v: u8 = undefined;
        _ = g.evloop.read(fdobj, std.mem.asBytes(&v)) orelse {
            log.err(@src(), "read(%d) failed: (%d) %m", .{ fdobj.fd, cc.errno() });
            continue;
        };
        log.info(@src(), "signal received, check memory leaks ...", .{});
        _ = _gpa.detectLeaks();
    }
}

// ============================================================================

/// called by EvLoop.check_timeout
pub const check_timeout = server.check_timeout;

pub fn main() u8 {
    g.allocator = if (_debug) b: {
        _gpa = gpa_t{};
        break :b _gpa.allocator();
    } else std.heap.c_allocator;

    defer {
        if (_debug)
            _ = _gpa.deinit();
    }

    // ============================================================================

    _ = cc.signal(c.SIGPIPE, cc.SIG_IGN());

    _ = cc.setvbuf(cc.stdout, null, c._IOLBF, 256);

    // setting default values for TZ
    _ = cc.setenv("TZ", ":/etc/localtime", false);

    // ============================================================================

    // used only for business-independent initialization, such as global variables
    init_all_module();
    defer if (_debug) deinit_all_module();

    // ============================================================================

    if (build_opts.is_test)
        return tests.main();

    // ============================================================================

    opt.parse();

    net.init();

    const src = @src();

    const bind_proto: cc.ConstStr = if (g.flags.has_all(.{ .bind_tcp, .bind_udp }))
        "tcp+udp"
    else if (g.flags.has(.bind_tcp))
        "tcp"
    else // bind_udp
        "udp";

    for (g.bind_ips.items()) |ip|
        log.info(
            src,
            "local listen addr: %s#%u@%s",
            .{ ip, cc.to_uint(g.bind_port), bind_proto },
        );

    groups.on_start();

    if (g.default_tag == .none or g.noaaaa_rule.require_ip_test()) {
        const name46 = cc.to_cstr_x(&.{ g.chnroute_name.slice(), ",", g.chnroute6_name.slice() });
        g.chnroute_testctx = ipset.new_testctx(name46);
        log.info(src, "ip test db: %s", .{name46});
    }

    log.info(src, "default domain name tag: %s", .{g.default_tag.name()});

    g.noaaaa_rule.display();

    if (g.cache_size > 0) {
        log.info(src, "enable dns cache, capacity: %u", .{cc.to_uint(g.cache_size)});

        if (g.cache_stale > 0)
            log.info(src, "use stale cache, excess TTL: %lu", .{cc.to_ulong(g.cache_stale)});

        if (g.cache_refresh > 0)
            log.info(src, "pre-refresh cache, remain TTL: %u%%", .{cc.to_uint(g.cache_refresh)});

        if (g.cache_nodata_ttl > 0)
            log.info(src, "cache NODATA response, TTL: %u", .{cc.to_uint(g.cache_nodata_ttl)});
    }

    if (g.verdict_cache_size > 0)
        log.info(src, "enable verdict cache, capacity: %u", .{cc.to_uint(g.verdict_cache_size)});

    log.info(src, "response timeout of upstream: %u", .{cc.to_uint(g.upstream_timeout)});

    if (g.trustdns_packet_n > 1)
        log.info(src, "num of packets to trustdns: %u", .{cc.to_uint(g.trustdns_packet_n)});

    if (g.default_tag == .none) {
        const action = cc.b2s(g.flags.has(.noip_as_chnip), "accept", "filter");
        log.info(src, "%s no-ip reply from chinadns", .{action});
    }

    if (g.flags.has(.reuse_port))
        log.info(src, "SO_REUSEPORT for listening socket", .{});

    if (g.verbose())
        log.info(src, "printing the verbose runtime log", .{});

    // ============================================================================

    g.evloop = EvLoop.init();

    server.start();

    if (_debug)
        co.create(memleak_checker, .{});

    g.evloop.run();

    return 0;
}

fn init_all_module() void {
    comptime var i = 0;
    inline while (i < modules.module_list.len) : (i += 1) {
        const module = modules.module_list[i];
        const module_name: cc.ConstStr = modules.name_list[i];
        if (@hasDecl(module, "module_init")) {
            if (false) log.debug(@src(), "%s.module_init()", .{module_name});
            module.module_init();
        }
    }
}

fn deinit_all_module() void {
    comptime var i = 0;
    inline while (i < modules.module_list.len) : (i += 1) {
        const module = modules.module_list[i];
        const module_name: cc.ConstStr = modules.name_list[i];
        if (@hasDecl(module, "module_deinit")) {
            if (false) log.debug(@src(), "%s.module_deinit()", .{module_name});
            module.module_deinit();
        }
    }
}
