const std = @import("std");
const sokol = @import("sokol");
const sapp = sokol.app;
const sg = sokol.gfx;
const sglue = sokol.glue;
const slog = sokol.log;

pub fn main() void {
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .width = 800,
        .height = 600,
        .window_title = "A Small World",
        .sample_count = 4,
    });
}

fn gfxInit() void {
    sg.setup(.{});
}

export fn init() void {
    gfxInit();
}

export fn frame() void {
    sg.beginPass(.{});
    sg.endPass();
    sg.commit();
}
