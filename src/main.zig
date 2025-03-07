const std = @import("std");
const gl = @import("gl");
const obj = @import("obj");
const glfw = @import("mach-glfw");
const vec = @import("vector.zig");
const mat = @import("matrix.zig");
const quat = @import("quaternion.zig");
const c = @cImport({
    @cDefine("STB_IMAGE_IMPLEMENTATION", {});
    @cDefine("STBI_NO_SIMD", {});
    @cDefine("STBI_NO_GIF", {});
    @cDefine("STBI_NO_HDR", {});
    @cDefine("STBI_NO_TGA", {});
    @cInclude("stb_image.h");
});

var procs: gl.ProcTable = undefined;

var shaderID: u32 = 0;
var planetShaderID: u32 = 0;

var forwardPressed: bool = false;
var backwardPressed: bool = false;
var leftPressed: bool = false;
var rightPressed: bool = false;
var upPressed: bool = false;
var downPressed: bool = false;
var mouseCaptured: bool = false;
var wireFrame: bool = false;
var useCam2: bool = false;
var doTime: bool = true;

var camera: Camera = .{.pos = .{.x = 4_000_000.0, .y = 0.0, .z = -5.0}, //.rot = .{.x = 0.0, .y = 0.0, .z = 0.0, .w = 1.0},
    .forward = .{.x = 0.0, .y = 0.0, .z = 1.0}, .up = .{.x = 0.0, .y = 1.0, .z = 0.0}, .right = .{.x = 1.0, .y = 0.0, .z = 0.0},
    .fov = 90.0, .nearClip = 0.01, .farClip = 100.0, .speed = 0.01, .sensitivity = 0.005, .aspect = 640.0/480.0,
};

var camera2: Camera = .{.pos = .{.x = 0.0, .y = 0.0, .z = -5.0}, //.rot = .{.x = 0.0, .y = 0.0, .z = 0.0, .w = 1.0},
    .forward = .{.x = 0.0, .y = 0.0, .z = 1.0}, .up = .{.x = 0.0, .y = 1.0, .z = 0.0}, .right = .{.x = 1.0, .y = 0.0, .z = 0.0},
    .fov = 90.0, .nearClip = 0.1, .farClip = 100.0, .speed = 0.1, .sensitivity = 0.005, .aspect = 640.0/480.0,
};

/// Default GLFW error handling callback
fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}

fn windowSizeCallback(window: glfw.Window, width: i32, height: i32) void {
    _ = window;
    gl.Viewport(0, 0, width, height);
    camera.aspect = @as(f64, @floatFromInt(width)) / @as(f64, @floatFromInt(height));
    camera2.aspect = @as(f64, @floatFromInt(width)) / @as(f64, @floatFromInt(height));
}

fn keyCallback(window: glfw.Window, key: glfw.Key, scancode: i32, action: glfw.Action, mods: glfw.Mods) void {
    _ = window;
    _ = scancode;
    _ = mods;
    
    switch (key) {
        .w, .up => {
            forwardPressed = action != .release;
        },
        .s, .down => {
            backwardPressed = action != .release;
        },
        .a, .left => {
            leftPressed = action != .release;
        },
        .d, .right => {
            rightPressed = action != .release;
        },
        .e, .space => {
            upPressed = action != .release;
        },
        .q, .left_shift => {
            downPressed = action != .release;
        },
        .f => {
            if (action == .press) {
                wireFrame = !wireFrame;
            }
        },
        .r => {
            if (action == .press) {
                useCam2 = !useCam2;
            }
        },
        .t => {
            if (action == .press) {
                doTime = !doTime;
            }
        },
        .escape => {
            if (action == .press) {
                mouseCaptured = !mouseCaptured;
            }
        },
        else => {},
    }
}

fn cursorPosCallback(window: glfw.Window, xPos: f64, yPos: f64) void {
    _ = window;
    
    if (mouseCaptured) {
        const up: vec.Vector3d = camera.forward.cross(camera.right);
        camera.forward = camera.forward.add(up.multScalar(-yPos*camera.sensitivity)).normalize();
        camera.forward = camera.forward.add(camera.right.multScalar(xPos*camera.sensitivity)).normalize();
    }
}

fn scrollCallback(window: glfw.Window, xPos: f64, yPos: f64) void {
    _ = window;
    _ = xPos;
    //std.debug.print("{d:.2} {d:.2}\n", .{xPos, yPos});
    camera.fov += -yPos;
    std.debug.print("{d:.2}\n", .{camera.fov});
}

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    //std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
    
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator: std.mem.Allocator = gpa.allocator();
    defer _ = gpa.deinit();
    
    glfw.setErrorCallback(errorCallback);
    if (!glfw.init(.{})) {
        std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    defer glfw.terminate();

    // Create our window
    const window: glfw.Window = glfw.Window.create(640, 480, "Hello, mach-glfw!", null, null, .{
        .context_version_major = gl.info.version_major,
        .context_version_minor = gl.info.version_minor,
        // This example supports both OpenGL (Core profile) and OpenGL ES.
        // (Toggled by building with '-Dgles')
        .opengl_profile = switch (gl.info.api) {
            .gl => .opengl_core_profile,
            .gles => .opengl_any_profile,
            else => comptime unreachable,
        },
        // The forward compat hint should only be true when using regular OpenGL.
        .opengl_forward_compat = gl.info.api == .gl,
    }) orelse {
        std.log.err("failed to create GLFW window: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    };
    defer window.destroy();
    
    glfw.makeContextCurrent(window);
    defer glfw.makeContextCurrent(null);
    
    if (!procs.init(glfw.getProcAddress)) return error.InitFailed;
    
    gl.makeProcTableCurrent(&procs);
    defer gl.makeProcTableCurrent(null);
    
    gl.Viewport(0, 0, 640, 480);
    window.setSizeCallback(windowSizeCallback);
    window.setKeyCallback(keyCallback);
    window.setCursorPosCallback(cursorPosCallback);
    window.setScrollCallback(scrollCallback);

    setupGL();
    
    //gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE);
    
    std.debug.print("Loading/generating models...\n", .{});
    
    var sphere: Model = try Model.load("models/cubeSphere.obj", planetShaderID, allocator); //try Model.sphere(planetShaderID, allocator);
    defer sphere.deinit();
    
    var sphere2: Model = try Model.sphere(shaderID, allocator);
    defer sphere2.deinit();
    
    var monkey: Model = try Model.load("models/Suzanne.obj", shaderID, allocator);
    defer monkey.deinit();
    
    var origin: Model = try Model.load("models/origin.obj", shaderID, allocator);
    defer origin.deinit();
    
    var frustum: Model = try Model.load("models/frustum.obj", shaderID, allocator);
    defer frustum.deinit();
    
    var line: Model = try Model.load("models/line.obj", shaderID, allocator);
    defer line.deinit();
    
    std.debug.print("Loading textures...\n", .{});
    
    var xAxis: Texture = Texture.load(allocator, "textures/outX.png.raw");
    defer xAxis.unload(allocator);
    
    var yAxis: Texture = Texture.load(allocator, "textures/outY.png.raw");
    defer yAxis.unload(allocator);
    
    var zAxis: Texture = Texture.load(allocator, "textures/outZ.png.raw");
    defer zAxis.unload(allocator);
    
    
    var xHeight: Texture = Texture.load(allocator, "textures/heightX.png.raw");
    defer xHeight.unload(allocator);
    
    var yHeight: Texture = Texture.load(allocator, "textures/heightY.png.raw");
    defer yHeight.unload(allocator);
    
    var zHeight: Texture = Texture.load(allocator, "textures/heightZ.png.raw");
    defer zHeight.unload(allocator);
    
    const startTime: i64 = std.time.milliTimestamp();
    var time: f64 = 0.0;
    // Wait for the user to close the window.
    while (!window.shouldClose()) {
        if (forwardPressed) {
            camera.pos = camera.pos.add(camera.forward.multScalar(camera.speed));
        }
        if (backwardPressed) {
            camera.pos = camera.pos.sub(camera.forward.multScalar(camera.speed));
        }
        if (leftPressed) {
            camera.pos = camera.pos.sub(camera.right.multScalar(camera.speed));
        }
        if (rightPressed) {
            camera.pos = camera.pos.add(camera.right.multScalar(camera.speed));
        }
        if (upPressed) {
            camera.pos = camera.pos.add(camera.up.multScalar(camera.speed));
        }
        if (downPressed) {
            camera.pos = camera.pos.sub(camera.up.multScalar(camera.speed));
        }
        //std.debug.print("x:{d:.2} y:{d:.2} z:{d:.2}\n", .{camera.pos.x, camera.pos.y, camera.pos.z});
        camera.pos.y = 0.0;
        
        if (mouseCaptured) {
            window.setInputModeCursor(.disabled);
            window.setCursorPos(0.0, 0.0);
        } else {
            window.setInputModeCursor(.normal);
        }
        
        camera.updateVectors();
        
        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
        
        
        gl.UseProgram(planetShaderID);
        if (useCam2) {
            setShaderMatrix(planetShaderID, "view", camera2.viewMatrix());
            setShaderMatrix(planetShaderID, "projection", camera2.projectionMatrix());
        } else {
            setShaderMatrix(planetShaderID, "view", camera.viewMatrix());
            setShaderMatrix(planetShaderID, "projection", camera.projectionMatrix());
        }
        
        if (doTime) {
            time = @as(f64, @floatFromInt(std.time.milliTimestamp()-startTime))*0.001;
        }
        
        sphere.world = mat.Mat4.fromAxisAngle(.{.x = 0.0, .y = 1.0, .z = 0.0}, time * std.math.tau * 0.01);
        sphere.world = sphere.world.multMatrix4(mat.Mat4.fromAxisAngle(.{.x = 0.0, .y = 0.0, .z = 1.0}, std.math.degreesToRadians(0.0)));
        //sphere.world = mat.Mat4.identity();
        setShaderMatrix(planetShaderID, "sphereWorld", sphere.world);
        
        const forward: vec.Vector3d = vec.Vector3d.sub(.{.x = 4000000.0, .y = 0.0, .z = 0.0}, camera.pos).normalize();
        const up: vec.Vector3d = .{.x = 0.0, .y = 1.0, .z = 0.0};
        
        sphere.world = mat.Mat4.lookAt(forward, up);
        //const q: quat.Quaternion = quat.Quaternion.fromMatrix(sphere.world);
        const q: quat.Quaternion = quat.Quaternion.lookAt(forward, up);
        //q.val.w = quantize(q.val.w, 0.1);
        //var axisAngle: vec.Vector4 = q.toAxisAngle();
        //axisAngle.w = quantize(axisAngle.w, 0.1);
        //q = quat.Quaternion.fromAxisAngle(.{.x = axisAngle.x, .y = axisAngle.y, .z = axisAngle.z}, axisAngle.w);
        //q.val = q.val.normalize();
        sphere.world = mat.Mat4.fromQuat(q).invertPosRot();
        setShaderMatrix(planetShaderID, "view", sphere.world);
        sphere.world = sphere.world.setPos(.{.x = 4000000.0, .y = 0.0, .z = 0.0});
        sphere.world = mat.Mat4.multMatrix4(camera.viewMatrix(), sphere.world);
        
        //sphere2.world = mat.Mat4.fromQuatAndPos(vec.Vector4.normalize(.{.w = 1.0, .x = 0.0, .y = 0.0, .z = 0.0}), .{.x = 3.0, .y = 0.0, .z = 0.0});
        //sphere2.world = mat.Mat4.lookAt(planetForward, planetAxis).invertPosRot();
        //sphere2.world = mat.Mat4.fromAxisAngle(.{.x = 0.0, .y = 1.0, .z = 0.0}, time * 0.01);
        //sphere2.world = sphere2.world.multMatrix4(mat.Mat4.fromAxisAngle(.{.x = 0.0, .y = 0.0, .z = 1.0}, std.math.degreesToRadians(23.44)));
        //sphere2.world = sphere2.world.setPos(.{.x = 3.0, .y = 0.0, .z = 0.0});
        
        gl.ActiveTexture(gl.TEXTURE0);
        gl.BindTexture(gl.TEXTURE_2D, xAxis.id);
        gl.ActiveTexture(gl.TEXTURE1);
        gl.BindTexture(gl.TEXTURE_2D, yAxis.id);
        gl.ActiveTexture(gl.TEXTURE2);
        gl.BindTexture(gl.TEXTURE_2D, zAxis.id);
        
        gl.ActiveTexture(gl.TEXTURE3);
        gl.BindTexture(gl.TEXTURE_2D, xHeight.id);
        gl.ActiveTexture(gl.TEXTURE4);
        gl.BindTexture(gl.TEXTURE_2D, yHeight.id);
        gl.ActiveTexture(gl.TEXTURE5);
        gl.BindTexture(gl.TEXTURE_2D, zHeight.id);
        
        gl.Uniform1i(gl.GetUniformLocation(planetShaderID, "xAxis"), 0);
        gl.Uniform1i(gl.GetUniformLocation(planetShaderID, "yAxis"), 1);
        gl.Uniform1i(gl.GetUniformLocation(planetShaderID, "zAxis"), 2);
        gl.Uniform1i(gl.GetUniformLocation(planetShaderID, "xHeight"), 3);
        gl.Uniform1i(gl.GetUniformLocation(planetShaderID, "yHeight"), 4);
        gl.Uniform1i(gl.GetUniformLocation(planetShaderID, "zHeight"), 5);
        sphere.draw();
        
        
        gl.UseProgram(shaderID);
        
        if (useCam2) {
            setShaderMatrix(shaderID, "view", camera2.viewMatrix());
            setShaderMatrix(shaderID, "projection", camera2.projectionMatrix());
        } else {
            setShaderMatrix(shaderID, "view", camera.viewMatrix());
            setShaderMatrix(shaderID, "projection", camera.projectionMatrix());
        }
        
        //sphere2.draw();
        
        monkey.world = mat.Mat4.fromPos(.{.x = 4000000.0-3.0, .y = 0.0, .z = 0.0});
        monkey.draw();
        
        gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE);
        frustum.world = camera.viewMatrix().invertPosRot();
        
        if (useCam2) {
            frustum.draw();
        }
        
        if (!wireFrame) {
            gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL);
        }
        
        gl.Disable(gl.DEPTH_TEST);
        //origin.draw();
        gl.Enable(gl.DEPTH_TEST);
        
        window.swapBuffers();
        glfw.pollEvents();
        if (doTime) {
            time += 1.0;
        }
    }
}

const Texture = struct {
    id: u32,
    image: Image,
    
    pub fn init(image: Image) Texture {
        var out: Texture = undefined;
        out.image = image;
        gl.GenTextures(1, @ptrCast(&out.id));
        gl.BindTexture(gl.TEXTURE_2D, out.id);
        
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_BORDER);
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_BORDER);
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
        
        gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, @intCast(image.width), @intCast(image.height), 0, gl.RGB, gl.UNSIGNED_BYTE, image.data.ptr);
        gl.GenerateMipmap(gl.TEXTURE_2D);
        
        return out;
    }
    
    pub fn load(allocator: std.mem.Allocator, comptime path: []const u8) Texture {
        const image: Image = Image.load(allocator, path);
        const out: Texture = init(image);
        return out;
    }
    
    pub fn unload(texture: *Texture, allocator: std.mem.Allocator) void {
        texture.id = 0;
        texture.image.unload(allocator);
    }
};

const Image = struct {
    data: []u8,
    width: usize,
    height: usize,
    channels: usize,

    pub fn init(allocator: std.mem.Allocator, width: usize, height: usize, channels: usize) !Image {
        var img: Image = .{.data = undefined, .width = width, .height = height, .channels = channels};
        img.data = try allocator.alloc(u8, width*height*channels);
        return img;
    }

    pub fn deinit(self: Image, allocator: std.mem.Allocator) void {
        allocator.free(self.data);
    }
    
    fn loadRaw(allocator: std.mem.Allocator, comptime path: []const u8, width: *c_int, height: *c_int, channels: *c_int, req_channels: c_int) [*c]u8 {
        width.* = 1024;
        height.* = 512;
        channels.* = 3;
        _ = req_channels;
        
        const out: []u8 = allocator.alloc(u8, @intCast(width.* * height.* * channels.*)) catch unreachable;
        out[0] = 0;
        @memcpy(out, @embedFile(path));
        
        return @ptrCast(out);
    }

    pub fn load(allocator: std.mem.Allocator, comptime path: []const u8) Image {
        var out: Image = .{.data = undefined, .width = 0, .height = 0, .channels = 0};

        //const raw_data = @embedFile(path);
        //_ = allocator;
        
        var n: c_int = 0;
        var width: c_int = 0;
        var height: c_int = 0;
        //const data: [*c]u8 = c.stbi_load(path, &width, &height, &n, 3);
        //const data: [*c]u8 = c.stbi_load_from_memory(raw_data, raw_data.len, &width, &height, &n, 3);
        const data: [*c]u8 = loadRaw(allocator, path, &width, &height, &n, 3);
        if (data == null) {
            std.debug.print("ERROR: Failed to load \"{s}\"\n", .{path});
            @panic("Panic: Failed to load image\n");
        }

        out.width = @intCast(width);
        out.height = @intCast(height);
        out.channels = 3;
        out.data = data[0..out.width*out.height*3];
        
        //const file: std.fs.File = std.fs.cwd().createFile("src/" ++ path ++ ".raw", .{}) catch unreachable;
        //defer file.close();
        
        //file.writeAll(out.data) catch unreachable;

        return out;
    }

    pub fn save(img: Image, path: [*c]const u8) void {
        _ = c.stbi_write_png(path, @as(c_int, @intCast(img.width)), @as(c_int, @intCast(img.height)), @as(c_int, @intCast(img.channels)), @ptrCast(img.data), @as(c_int, @intCast(img.width*img.channels)));
    }

    pub fn unload(self: *Image, allocator: std.mem.Allocator) void {
        //c.stbi_image_free(self.data.ptr);
        allocator.free(self.data);
    }
};

const Camera = struct {
    pos: vec.Vector3d,
    //rot: vec.Vector4, //Quaternion
    forward: vec.Vector3d,
    up: vec.Vector3d,
    right: vec.Vector3d,
    fov: f64,         //FOV in degrees
    nearClip: f64,
    farClip: f64,
    speed: f64,
    sensitivity: f64,
    aspect: f64,
    
    pub fn updateVectors(cam: *Camera) void {
        cam.right = cam.up.cross(cam.forward).normalize();
        cam.up = cam.forward.cross(cam.right).normalize();
    }
    
    pub fn viewMatrix(cam: Camera) mat.Mat4 {
        //const rotMat: mat.Mat4 = mat.Mat4.fromQuat(cam.rot).transpose();
        var rotMat: mat.Mat4 = mat.Mat4.identity();
        const newY: vec.Vector3d = cam.forward.cross(cam.right).normalize();
        rotMat.r0.x = cam.right.x;
        rotMat.r1.x = newY.x;
        rotMat.r2.x = cam.forward.x;
        
        rotMat.r0.y = cam.right.y;
        rotMat.r1.y = newY.y;
        rotMat.r2.y = cam.forward.y;
        
        rotMat.r0.z = cam.right.z;
        rotMat.r1.z = newY.z;
        rotMat.r2.z = cam.forward.z;
        
        const posMat: mat.Mat4 = mat.Mat4.fromPos(vec.Vector3d.zero().sub(cam.pos)); //mat.Mat4.fromPos(vec.Vector3.zero().sub(cam.pos.add(cam.forward.multScalar(0.64)))); //I'm not gonna pretend to know why I have to do this
        
        const out: mat.Mat4 = mat.Mat4.multMatrix4(rotMat, posMat);
        
        return out;
    }
    
    //Current version adapted from https://ogldev.org/www/tutorial12/tutorial12.html
    pub fn projectionMatrix(cam: Camera) mat.Mat4 {
        var out: mat.Mat4 = mat.Mat4.identity();
        
        //out.r3.z = std.math.tan(std.math.degreesToRadians(cam.fov)*0.5); //FOV thing
        out.r3.z = 1.0;
        out.r3.w = 0.0;
        out.r0.x = 1.0 / (cam.aspect * std.math.tan(std.math.degreesToRadians(cam.fov*0.5)));
        out.r1.y = 1.0 / std.math.tan(std.math.degreesToRadians(cam.fov*0.5));
        
        //const rise: f64 = cam.farClip - (-cam.nearClip);
        //const run: f64 = cam.farClip - cam.nearClip;
        const slope: f64 = (-cam.nearClip-cam.farClip)/(cam.nearClip-cam.farClip);//rise / run;
        const bias: f64 = (2*cam.farClip*cam.nearClip)/(cam.nearClip-cam.farClip);//(slope * cam.nearClip) + cam.nearClip;

        out.r2.z = slope; //Z Scale factor
        out.r2.w = bias; //Bias
        //std.debug.print("w:{d:.2} z:{d:.2}\n", .{slope, bias}); //z = 100  w = out.r3.z * 100  z = z * out.r2.z
        //out.r1.y = cam.aspect; //Aspect ratio
        //out.debug_print_matrix();
        
        //std.debug.print("{d:.4} {d:.4}\n", .{out.r2.z, out.r2.w});
        
        return out;
    }
};

const Model = struct {
    VAO: u32,
    VBO: u32,
    EBO: u32,
    nIndices: usize,
    nTriangles: usize,
    world: mat.Mat4,
    shader: u32,
    allocator: std.mem.Allocator,
    
    pub fn load(comptime path: []const u8, shader: u32, allocator: std.mem.Allocator) !Model {
        var out: Model = undefined;
        out.allocator = allocator;
        out.shader = shader;
        
        out.world = mat.Mat4.identity();
        
        gl.GenVertexArrays(1, @ptrCast(&out.VAO));
        gl.GenBuffers(1, @ptrCast(&out.VBO));
        gl.GenBuffers(1, @ptrCast(&out.EBO));
        
        gl.BindVertexArray(out.VAO);
        gl.BindBuffer(gl.ARRAY_BUFFER, out.VBO);
        
        var object = try obj.parseObj(allocator, @embedFile(path));
        defer object.deinit(allocator);
        out.nIndices = object.meshes[0].indices.len;
        out.nTriangles = object.vertices.len / 3;
        
        var buffer: []u32 = try allocator.alloc(u32, object.meshes[0].indices.len);
        defer allocator.free(buffer);
        for (0..object.meshes[0].indices.len) |i| {
            buffer[i] = object.meshes[0].indices[i].vertex.?;
        }
        
        gl.BufferData(gl.ARRAY_BUFFER, @intCast(object.vertices.len*@sizeOf(f32)), object.vertices.ptr, gl.STATIC_DRAW);
        
        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, out.EBO);
        gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, @intCast(buffer.len*@sizeOf(u32)), buffer.ptr, gl.STATIC_DRAW);
        
        gl.BindBuffer(gl.ARRAY_BUFFER, out.VBO);
        gl.EnableVertexAttribArray(0);
        gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, @sizeOf(f32)*3, 0);
        
        gl.BindVertexArray(0);
        
        return out;
    }
    
    pub fn sphere(shader: u32, allocator: std.mem.Allocator) !Model {
        var out: Model = undefined;
        out.allocator = allocator;
        out.shader = shader;
        
        out.world = mat.Mat4.identity();
        
        gl.GenVertexArrays(1, @ptrCast(&out.VAO));
        gl.GenBuffers(1, @ptrCast(&out.VBO));
        gl.GenBuffers(1, @ptrCast(&out.EBO));
        
        gl.BindVertexArray(out.VAO);
        gl.BindBuffer(gl.ARRAY_BUFFER, out.VBO);
        
        
    
        
        
        var finalVerts: std.ArrayList(vec.Vector3f) = std.ArrayList(vec.Vector3f).init(allocator);
        defer finalVerts.deinit();
        
        var verts: std.ArrayList(vec.Vector3f) = std.ArrayList(vec.Vector3f).init(allocator);
        defer verts.deinit();
        
        var indices: std.ArrayList(u32) = std.ArrayList(u32).init(allocator);
        defer indices.deinit();
        
        var ringVertexCounts: std.ArrayList(usize) = std.ArrayList(usize).init(allocator);
        defer ringVertexCounts.deinit();
        
        var targetEdgeLength: f32 = 0.1;
        //const numRings: usize = @intFromFloat((std.math.pi / targetEdgeLength) * 0.9);
        var point: vec.Vector3f = .{.x = 0.0, .y = 0.0, .z = -1.0};
        try verts.append(point);
        //try indices.appendSlice(&[3]usize{0, 0, 0});
        while (vec.Vector3f.sub(.{.x = 0.0, .y = 0.0, .z = 1.0}, point).length() > targetEdgeLength*2.0) {
            const dir: vec.Vector3f = vec.Vector3f.cross(point, .{.x = -1.0, .y = 0.0, .z = 0.0});
            point = point.add(dir.multScalar(targetEdgeLength)).normalize();
            
            try verts.append(point);
            //try indices.appendSlice(&[3]usize{verts.items.len-1, verts.items.len-1, verts.items.len-1});
            
            const circumference: f64 = std.math.tau * point.y; //We're intentionally ignoring the y axis so we can get the radius of the 2D circular "slice" of the sphere at this y coordinate
                                                               //We can also ignore the x axis since it's guaranteed to be 0 at this point
            
            const numEdges: usize = @intFromFloat(circumference / targetEdgeLength);
            try ringVertexCounts.append(numEdges);
            
            const numEdgesF: f32 = @floatFromInt(numEdges);
            const edgeAngle: f32 = std.math.tau / numEdgesF;
            for (1..numEdges) |j| {
                var p: vec.Vector3f = vec.Vector3f.zero();
                p.x = std.math.cos(@as(f32, @floatFromInt(j)) * edgeAngle + std.math.pi * 0.5) * point.y;
                p.y = std.math.sin(@as(f32, @floatFromInt(j)) * edgeAngle + std.math.pi * 0.5) * point.y;
                p.z = point.z;
                try verts.append(p);
                //try indices.appendSlice(&[3]usize{verts.items.len-1, verts.items.len-1, verts.items.len-1});
            }
            
            targetEdgeLength *= 1.0;
        }
        
        for (1..ringVertexCounts.items[0]+1) |i| { //For each vertex in the first ring
            try indices.append(0);
            try indices.append(@intCast((i%ringVertexCounts.items[0])+1));
            try indices.append(@intCast(i));
        }
        //We have to skip ahead rings[i+1].verts.len-rings[i].verts.len vertices
        //const spacing: f32 = @as(f32, @floatFromInt(rings[i].verts.len)) / @as(f32, @floatFromInt(skipNum)) - @as(f32, @floatFromInt(skipNum)) / 2.0;
        var startVertIndex: usize = 1;
        for (0..ringVertexCounts.items.len-1) |i| { //For each ring
            var dontSkip: bool = false;
            var backwardsSkip: bool = false;
            if (ringVertexCounts.items[i+1] < ringVertexCounts.items[i]) {
                //dontSkip = true;
                backwardsSkip = true;
            }
            const skipNum: usize = @max(ringVertexCounts.items[i+1], ringVertexCounts.items[i])-@min(ringVertexCounts.items[i], ringVertexCounts.items[i+1]);
            //std.debug.print("skipNum:{}\n", .{skipNum});
            
            var skipSpacing: f32 = 1.0 / @as(f32, @floatFromInt(skipNum));
            var nextSkipCounter: f32 = 0.0; //1.0 at the first skip, 2.0 at the second, etc
            if (skipNum == 0) {
                dontSkip = true;
                skipSpacing = 2.0;
            }
            var currentSkipAmount: usize = 0;
            for (0..ringVertexCounts.items[i]) |j| { //For each vertex in the ring
                var isSkip: bool = false;
                
                const nextSkipIndex: usize = @intFromFloat(@round(nextSkipCounter * skipSpacing * @as(f32, @floatFromInt(ringVertexCounts.items[i]))));
                
                if (nextSkipIndex == j and !dontSkip) {
                    //std.debug.print("Skip time! i:{} j:{} backwardsSkip:{} skipSpacing:{d:.2} nextSkipCounter:{d:.2} currentSkipAmount:{} nextSkipIndex:{}\n", .{i, j, backwardsSkip, skipSpacing, nextSkipCounter, currentSkipAmount, nextSkipIndex});
                    currentSkipAmount += 1;
                    nextSkipCounter += 1.0;
                    isSkip = true;
                }
                
                if (backwardsSkip) {
                    try indices.append(@intCast(startVertIndex + j + currentSkipAmount - 1)); //A0
                    try indices.append(@intCast(startVertIndex + j + currentSkipAmount)); //A1
                    try indices.append(@intCast(startVertIndex + ringVertexCounts.items[i] + (j%ringVertexCounts.items[i+1]))); //B0
                } else {
                    try indices.append(@intCast(startVertIndex + j)); //A0
                    try indices.append(@intCast(startVertIndex + j + 1)); //A1
                    try indices.append(@intCast(startVertIndex + ringVertexCounts.items[i] + (j%ringVertexCounts.items[i+1]) + currentSkipAmount)); //B0
                }
                
                if (isSkip and backwardsSkip) {
                    if (j != 0) {
                        try indices.append(@intCast(startVertIndex + j + currentSkipAmount - 2)); //A1
                        try indices.append(@intCast(startVertIndex + j + currentSkipAmount - 1)); //A1
                        try indices.append(@intCast((((startVertIndex + ringVertexCounts.items[i] + (j%ringVertexCounts.items[i+1])) - (startVertIndex + ringVertexCounts.items[i])) % ringVertexCounts.items[i+1]) + (startVertIndex + ringVertexCounts.items[i]))); //B0
                    }
                } else if (isSkip) {
                    try indices.append(@intCast(startVertIndex + ringVertexCounts.items[i] + j + currentSkipAmount - 1)); //B0
                    try indices.append(@intCast(startVertIndex + j)); //A1
                    try indices.append(@intCast((((startVertIndex + ringVertexCounts.items[i] + j + currentSkipAmount) - (startVertIndex + ringVertexCounts.items[i])) % ringVertexCounts.items[i+1]) + (startVertIndex + ringVertexCounts.items[i]))); //B1
                }
                
                if (backwardsSkip) {
                    try indices.append(@intCast(startVertIndex + j + currentSkipAmount)); //A1
                    try indices.append(@intCast((((startVertIndex + ringVertexCounts.items[i] + (j%ringVertexCounts.items[i+1] + 1)) - (startVertIndex + ringVertexCounts.items[i])) % ringVertexCounts.items[i+1]) + (startVertIndex + ringVertexCounts.items[i]))); //B0
                    try indices.append(@intCast(startVertIndex + ringVertexCounts.items[i] + (j%ringVertexCounts.items[i+1]))); //B0
                } else {
                    try indices.append(@intCast(startVertIndex + ringVertexCounts.items[i] + j + currentSkipAmount)); //B0
                    try indices.append(@intCast(startVertIndex + j + 1)); //A1
                    try indices.append(@intCast((((startVertIndex + ringVertexCounts.items[i] + j + currentSkipAmount + 1) - (startVertIndex + ringVertexCounts.items[i])) % ringVertexCounts.items[i+1]) + (startVertIndex + ringVertexCounts.items[i]))); //B1
                }
            }
                
            try indices.append(@intCast(startVertIndex + ringVertexCounts.items[i] - 1)); //A0
            try indices.append(@intCast(startVertIndex)); //A1
            try indices.append(@intCast(startVertIndex + ringVertexCounts.items[i])); //B0
            
            startVertIndex += ringVertexCounts.items[i];
        }
        
        
        out.nIndices = indices.items.len;//object.meshes[0].indices.len;
        out.nTriangles = 0; //Not used
        
        
    
        
        
        gl.BufferData(gl.ARRAY_BUFFER, @intCast(verts.items.len*@sizeOf(vec.Vector3f)), verts.items.ptr, gl.STATIC_DRAW);
        
        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, out.EBO);
        gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, @intCast(indices.items.len*@sizeOf(u32)), indices.items.ptr, gl.STATIC_DRAW);
        
        gl.BindBuffer(gl.ARRAY_BUFFER, out.VBO);
        gl.EnableVertexAttribArray(0);
        gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, @sizeOf(vec.Vector3f), 0);
        
        gl.BindVertexArray(0);
        
        return out;
    }
    
    pub fn deinit(model: *Model) void {
        gl.DeleteBuffers(1, @ptrCast(&model.VBO));
        //gl.DeleteBuffers(1, @ptrCast(&model.EBO));
        gl.DeleteVertexArrays(1, @ptrCast(&model.VAO));
    }
    
    pub fn draw(model: Model) void {
        setShaderMatrix(model.shader, "world", model.world);
        gl.BindVertexArray(model.VAO);
        gl.DrawElements(gl.TRIANGLES, @intCast(model.nIndices), gl.UNSIGNED_INT, 0);
        //gl.DrawArrays(gl.TRIANGLES, 0, @intCast(model.nTriangles));
    }
};

fn setShaderMatrix(shader: u32, name: [:0]const u8, matrix: mat.Mat4) void {
    var temp: [16]f32 = undefined;
    temp[ 0] = @floatCast(matrix.r0.x);
    temp[ 1] = @floatCast(matrix.r0.y);
    temp[ 2] = @floatCast(matrix.r0.z);
    temp[ 3] = @floatCast(matrix.r0.w);
    
    temp[ 4] = @floatCast(matrix.r1.x);
    temp[ 5] = @floatCast(matrix.r1.y);
    temp[ 6] = @floatCast(matrix.r1.z);
    temp[ 7] = @floatCast(matrix.r1.w);
    
    temp[ 8] = @floatCast(matrix.r2.x);
    temp[ 9] = @floatCast(matrix.r2.y);
    temp[10] = @floatCast(matrix.r2.z);
    temp[11] = @floatCast(matrix.r2.w);
    
    temp[12] = @floatCast(matrix.r3.x);
    temp[13] = @floatCast(matrix.r3.y);
    temp[14] = @floatCast(matrix.r3.z);
    temp[15] = @floatCast(matrix.r3.w);
    gl.UniformMatrix4fv(gl.GetUniformLocation(shader, name), 1, gl.TRUE, &temp);
}

fn setupGL() void {
    //gl.Enable(gl.CULL_FACE);
    //gl.CullFace(gl.BACK);
    //gl.FrontFace(gl.CCW);
    gl.Enable(gl.DEPTH_TEST);
    gl.ClearColor(0.03, 0.03, 0.03, 1.0);
    
    shaderID = loadShaders("shaders/vertex.glsl", "shaders/fragment.glsl");
    planetShaderID = loadShaders("shaders/planetVert.glsl", "shaders/planetFrag.glsl");
    gl.UseProgram(shaderID);
}

fn loadShaders(comptime vertPath: []const u8, comptime fragPath: []const u8) u32 {
    const vertexCode = @embedFile(vertPath);
    const fragmentCode = @embedFile(fragPath);
    
    const vertShaderID: u32 = gl.CreateShader(gl.VERTEX_SHADER);
    const fragShaderID: u32 = gl.CreateShader(gl.FRAGMENT_SHADER);
    defer gl.DeleteShader(vertShaderID);
    defer gl.DeleteShader(fragShaderID);
    
    gl.ShaderSource(vertShaderID, 1, @ptrCast(&vertexCode), null);
    gl.ShaderSource(fragShaderID, 1, @ptrCast(&fragmentCode), null);
    
    gl.CompileShader(vertShaderID);
    gl.CompileShader(fragShaderID);
    
    var success: i32 = 0;
    gl.GetShaderiv(vertShaderID, gl.COMPILE_STATUS, &success);
    if (success == 0) {
        var buffer: [1024]u8 = std.mem.zeroes([1024]u8);
        gl.GetShaderInfoLog(vertShaderID, buffer.len, null, &buffer);
        std.debug.print("Failed to compile vertex shader! Error:\n{s}\n", .{buffer});
    }
    
    success = 0;
    gl.GetShaderiv(fragShaderID, gl.COMPILE_STATUS, &success);
    if (success == 0) {
        var buffer: [1024]u8 = std.mem.zeroes([1024]u8);
        gl.GetShaderInfoLog(fragShaderID, buffer.len, null, &buffer);
        std.debug.print("Failed to compile fragment shader! Error:\n{s}\n", .{buffer});
    }
    
    const programID: u32 = gl.CreateProgram();
    gl.AttachShader(programID, vertShaderID);
    gl.AttachShader(programID, fragShaderID);
    gl.LinkProgram(programID);
    
    success = 0;
    gl.GetProgramiv(programID, gl.LINK_STATUS, &success);
    if (success == 0) {
        var buffer: [1024]u8 = std.mem.zeroes([1024]u8);
        gl.GetShaderInfoLog(programID, buffer.len, null, &buffer);
        std.debug.print("Failed to link shaders! Error:\n{s}\n", .{buffer});
    }
    
    return programID;
}
