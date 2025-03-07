const std = @import("std");
const vec = @import("vector.zig");
const mat = @import("matrix.zig");

fn quantize(val: f64, snapInterval: f64) f64 {
    return @round(val / snapInterval) * snapInterval;
}

pub const Quaternion = struct {
    val: vec.Vector4, //w = scalar, x = i, y = j, z = k
    
    //From https://en.wikipedia.org/wiki/Rotation_matrix#Quaternion
    //Note: May not work!!
    pub fn fromMatrix(m: mat.Mat4) Quaternion {
        const r: f64 = @sqrt(1.0 + m.r0.x - m.r1.y - m.r2.z);
        const s: f64 = 1.0 / (2.0 * r);
        const w = 0.5 * r;
        const x: f64 = (m.r2.y - m.r1.z) * s;
        const y: f64 = (m.r0.z - m.r2.x) * s;
        const z: f64 = (m.r1.x - m.r0.y) * s;
        return .{.val = .{.w = w, .x = x, .y = y, .z = z}};
    }
    
    pub fn lookAt(forward: vec.Vector3d, up: vec.Vector3d) Quaternion {
        _ = up;
        //const normalUp: vec.Vector3d = .{.x = 0.0, .y = 0.0, .z = 1.0}; //vec.Vector3d = up.cross(forward).normalize();
        //const rotAxis: vec.Vector3d = vec.Vector3d.cross(normalUp, forward).normalize();
        //const rotAngle = std.math.acos(vec.Vector3d.dot(normalUp, forward));
        const projection: vec.Vector2(f64) = .{.x = forward.x, .y = forward.z};
        const rise: f64 = forward.y;
        const run: f64 = projection.length();
        const slope: f64 = rise / run;
        const q1: Quaternion = fromAxisAngle(.{.x = 0.0, .y = 1.0, .z = 0.0}, @mod(quantize(projection.getAngle() - std.math.pi * 0.5, std.math.tau / 32.0), std.math.tau));
        const q2: Quaternion = fromAxisAngle(.{.x = 1.0, .y = 0.0, .z = 0.0}, quantize(std.math.atan(slope), std.math.tau / 32.0));
        return q2.multQuat(q1);
    }
    
    //Implemented from https://www.youtube.com/watch?v=Hhzgaq5PKPo
    //Note: Seems to be right handed if +z is forward
    pub fn fromAxisAngle(axis: vec.Vector3d, angle: f64) Quaternion {
        const xyz: vec.Vector3d = axis.multScalar(std.math.sin(angle*0.5));
        return .{.val = .{.w = std.math.cos(angle*0.5), .x = xyz.x, .y = xyz.y, .z = xyz.z}};
    }
    
    //Implemented from https://www.youtube.com/watch?v=Hhzgaq5PKPo
    //Output: w is angle, xyz is axis
    pub fn toAxisAngle(q: Quaternion) vec.Vector4 {
        const xyz: vec.Vector3d = vec.Vector3d.normalize(.{.x = q.val.x, .y = q.val.y, .z = q.val.z});
        return .{.w = std.math.acos(q.val.w)*2.0, .x = xyz.x, .y = xyz.y, .z = xyz.z};
    }
    
    //Adapted from https://github.com/robrohan/r2/blob/main/r2_maths.h
    pub fn multVec3(q: Quaternion, v: vec.Vector3d) vec.Vector3d {
        const inv: Quaternion = q.conjugate();
        var temp: Quaternion = q.multQuat(.{.val = .{.w = 0.0, .x = v.x, .y = v.y, .z = v.z}});
        temp = temp.multQuat(inv);
        return .{.x = temp.val.x, .y = temp.val.y, .z = temp.val.z};
    }
    
    //Adapted from https://github.com/robrohan/r2/blob/main/r2_maths.h
    pub fn conjugate(q: Quaternion) Quaternion {
        return .{.val = .{.w = q.val.w, .x = -q.val.x, .y = -q.val.y, .z = -q.val.z}};
    }
    
    //Implemented from https://www.youtube.com/watch?v=Hhzgaq5PKPo
    pub fn multQuat(left: Quaternion, right: Quaternion) Quaternion {
        const a1: f64 = left.val.w;
        const b1: f64 = left.val.x;
        const c1: f64 = left.val.y;
        const d1: f64 = left.val.z;
        
        const a2: f64 = right.val.w;
        const b2: f64 = right.val.x;
        const c2: f64 = right.val.y;
        const d2: f64 = right.val.z;
        return .{
            .val = .{
                .w = a1*a2 - b1*b2 - c1*c2 - d1*d2,
                .x = a1*b2 + b1*a2 + c1*d2 - d1*c2,
                .y = a1*c2 - b1*d2 + c1*a2 + d1*b2,
                .z = a1*d2 + b1*c2 - c1*b2 + d1*a2,
            }
        };
    }
};

test "Axis angle sanity check 1" {
    const q: Quaternion = Quaternion.fromAxisAngle(.{.x = 0.0, .y = 1.0, .z = 0.0}, std.math.degreesToRadians(45.0));
    const axisAngle: vec.Vector4 = q.toAxisAngle();
    try axisAngle.expectEqual(.{.w = std.math.degreesToRadians(45.0), .x = 0.0, .y = 1.0, .z = 0.0}, 0.01);
}

test "Axis angle sanity check 2" {
    const q: Quaternion = Quaternion.fromAxisAngle(vec.Vector3d.normalize(.{.x = 0.0, .y = 1.0, .z = 1.0}), std.math.degreesToRadians(12.0));
    const axisAngle: vec.Vector4 = q.toAxisAngle();
    const expect: vec.Vector3d = vec.Vector3d.normalize(.{.x = 0.0, .y = 1.0, .z = 1.0});
    try axisAngle.expectEqual(.{.w = std.math.degreesToRadians(12.0), .x = expect.x, .y = expect.y, .z = expect.z}, 0.01);
}

test "Rotate point test 1" {
    const q: Quaternion = Quaternion.fromAxisAngle(vec.Vector3d.normalize(.{.x = 0.0, .y = 1.0, .z = 0.0}), std.math.degreesToRadians(90.0));
    const p: vec.Vector3d = .{.x = 1.0, .y = 0.0, .z = 0.0};
    const result: vec.Vector3d = q.multVec3(p);
    //std.debug.print("{d:.2}, {d:.2}, {d:.2}, {d:.2}\n", .{resultQ.val.w, resultQ.val.x, resultQ.val.y, resultQ.val.z});
    const expect: vec.Vector3d = .{.x = 0.0, .y = 0.0, .z = -1.0};
    try result.expectEqual(expect, 0.01);
}

test "Rotate point test 2" {
    const q: Quaternion = Quaternion.fromAxisAngle(vec.Vector3d.normalize(.{.x = 1.0, .y = 0.0, .z = 0.0}), std.math.degreesToRadians(45.0));
    const p: vec.Vector3d = .{.x = 0.0, .y = 1.0, .z = 0.0};
    const result: vec.Vector3d = q.multVec3(p);
    const expect: vec.Vector3d = .{.x = 0.0, .y = 0.707, .z = 0.707};
    try result.expectEqual(expect, 0.01);
}