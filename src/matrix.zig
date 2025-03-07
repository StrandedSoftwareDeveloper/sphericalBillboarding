const std = @import("std");
const vec = @import("vector.zig");
const quat = @import("quaternion.zig");

pub const Mat4 = struct {
    r0: vec.Vector4,
    r1: vec.Vector4,
    r2: vec.Vector4,
    r3: vec.Vector4,
    
    pub fn multMatrix4(l: Mat4, r: Mat4) Mat4 {
        var out: Mat4 = identity();
        
        out.r0.x = l.r0.x * r.r0.x + l.r0.y * r.r1.x + l.r0.z * r.r2.x + l.r0.w * r.r3.x;
        out.r0.y = l.r0.x * r.r0.y + l.r0.y * r.r1.y + l.r0.z * r.r2.y + l.r0.w * r.r3.y;
        out.r0.z = l.r0.x * r.r0.z + l.r0.y * r.r1.z + l.r0.z * r.r2.z + l.r0.w * r.r3.z;
        out.r0.w = l.r0.x * r.r0.w + l.r0.y * r.r1.w + l.r0.z * r.r2.w + l.r0.w * r.r3.w;

        out.r1.x = l.r1.x * r.r0.x + l.r1.y * r.r1.x + l.r1.z * r.r2.x + l.r1.w * r.r3.x;
        out.r1.y = l.r1.x * r.r0.y + l.r1.y * r.r1.y + l.r1.z * r.r2.y + l.r1.w * r.r3.y;
        out.r1.z = l.r1.x * r.r0.z + l.r1.y * r.r1.z + l.r1.z * r.r2.z + l.r1.w * r.r3.z;
        out.r1.w = l.r1.x * r.r0.w + l.r1.y * r.r1.w + l.r1.z * r.r2.w + l.r1.w * r.r3.w;
        
        out.r2.x = l.r2.x * r.r0.x + l.r2.y * r.r1.x + l.r2.z * r.r2.x + l.r2.w * r.r3.x;
        out.r2.y = l.r2.x * r.r0.y + l.r2.y * r.r1.y + l.r2.z * r.r2.y + l.r2.w * r.r3.y;
        out.r2.z = l.r2.x * r.r0.z + l.r2.y * r.r1.z + l.r2.z * r.r2.z + l.r2.w * r.r3.z;
        out.r2.w = l.r2.x * r.r0.w + l.r2.y * r.r1.w + l.r2.z * r.r2.w + l.r2.w * r.r3.w;
        
        
        out.r3.x = l.r3.x * r.r0.x + l.r3.y * r.r1.x + l.r3.z * r.r2.x + l.r3.w * r.r3.x;
        out.r3.y = l.r3.x * r.r0.y + l.r3.y * r.r1.y + l.r3.z * r.r2.y + l.r3.w * r.r3.y;
        out.r3.z = l.r3.x * r.r0.z + l.r3.y * r.r1.z + l.r3.z * r.r2.z + l.r3.w * r.r3.z;
        out.r3.w = l.r3.x * r.r0.w + l.r3.y * r.r1.w + l.r3.z * r.r2.w + l.r3.w * r.r3.w;
        
        return out;
    }

    pub fn multVector4(self: Mat4, v: vec.Vector4) vec.Vector4 {
        var out: vec.Vector4 = vec.Vector4.zero();

        out.x = self.r0.x * v.x + self.r0.y * v.y + self.r0.z * v.z + self.r0.w * v.w;
        out.y = self.r1.x * v.x + self.r1.y * v.y + self.r1.z * v.z + self.r1.w * v.w;
        out.z = self.r2.x * v.x + self.r2.y * v.y + self.r2.z * v.z + self.r2.w * v.w;
        out.w = self.r3.x * v.x + self.r3.y * v.y + self.r3.z * v.z + self.r3.w * v.w;

        return out;
    }

    pub fn identity() Mat4 {
        return .{
            .r0 = .{.x = 1.0, .y = 0.0, .z = 0.0, .w = 0.0},
            .r1 = .{.x = 0.0, .y = 1.0, .z = 0.0, .w = 0.0},
            .r2 = .{.x = 0.0, .y = 0.0, .z = 1.0, .w = 0.0},
            .r3 = .{.x = 0.0, .y = 0.0, .z = 0.0, .w = 1.0},
        };
    }
    
    pub fn transpose(mat: Mat4) Mat4 {
        var out: Mat4 = identity();
        
        out.r0.x = mat.r0.x;
        out.r0.y = mat.r1.x;
        out.r0.z = mat.r2.x;
        out.r0.w = mat.r3.x;
        
        out.r1.x = mat.r0.y;
        out.r1.y = mat.r1.y;
        out.r1.z = mat.r2.y;
        out.r1.w = mat.r3.y;
        
        out.r2.x = mat.r0.z;
        out.r2.y = mat.r1.z;
        out.r2.z = mat.r2.z;
        out.r2.w = mat.r3.z;
        
        out.r3.x = mat.r0.w;
        out.r3.y = mat.r1.w;
        out.r3.z = mat.r2.w;
        out.r3.w = mat.r3.w;
        
        return out;
    }

    pub fn setPos(mat: Mat4, v: vec.Vector3d) Mat4 {
        var out: Mat4 = mat;
        out.r0.w = v.x;
        out.r1.w = v.y;
        out.r2.w = v.z;
        return out;
    }
    
    pub fn translate(mat: Mat4, v: vec.Vector3d) Mat4 {
        var out: Mat4 = mat;
        out.r0.w += v.x;
        out.r1.w += v.y;
        out.r2.w += v.z;
        return out;
    }

    pub fn debug_print_matrix(mat: Mat4) void {
        std.debug.print("\n{d:.2} {d:.2} {d:.2} {d:.2}\n", .{mat.r0.x, mat.r0.y, mat.r0.z, mat.r0.w});
        std.debug.print("{d:.2} {d:.2} {d:.2} {d:.2}\n", .{mat.r1.x, mat.r1.y, mat.r1.z, mat.r1.w});
        std.debug.print("{d:.2} {d:.2} {d:.2} {d:.2}\n", .{mat.r2.x, mat.r2.y, mat.r2.z, mat.r2.w});
        std.debug.print("{d:.2} {d:.2} {d:.2} {d:.2}\n", .{mat.r3.x, mat.r3.y, mat.r3.z, mat.r3.w});
    }

    pub fn invertPosRot(mat: Mat4) Mat4 {
        var out: Mat4 = mat;
        
        const pos: vec.Vector3d = .{.x = -out.r0.w, .y = -out.r1.w, .z = -out.r2.w}; //Extract and invert the position
        out.r0.w = 0;
        out.r1.w = 0;
        out.r2.w = 0;
        
        out = out.transpose(); //Invert the rotation
        out = out.multMatrix4(fromPos(pos));
        
        return out;
    }
    
    pub fn lookAt(forward: vec.Vector3d, up: vec.Vector3d) Mat4 {
        var out: Mat4 = Mat4.identity();
        
        const right: vec.Vector3d = forward.cross(up).normalize();
        const newY: vec.Vector3d = forward.cross(right).normalize();
        
        out.r0.x = right.x;
        out.r1.x = newY.x;
        out.r2.x = forward.x;
        
        out.r0.y = right.y;
        out.r1.y = newY.y;
        out.r2.y = forward.y;
        
        out.r0.z = right.z;
        out.r1.z = newY.z;
        out.r2.z = forward.z;
        
        return out;
    }
    
    //Adapted from https://www.euclideanspace.com/maths/geometry/rotations/conversions/angleToMatrix/
    pub fn fromAxisAngle(axis: vec.Vector3d, angle: f64) Mat4 {
        const c: f64 = std.math.cos(angle);
        const s: f64 = std.math.sin(angle);
        const t: f64 = 1.0 - c;
        const x = axis.x;
        const y = axis.y;
        const z = axis.z;
        return .{
            .r0 = .{.x = t*x*x+c,   .y = t*x*y-z*s, .z = t*x*z+y*s, .w = 0.0},
            .r1 = .{.x = t*x*y+z*s, .y = t*y*y+c,   .z = t*y*z-x*s, .w = 0.0},
            .r2 = .{.x = t*x*z-y*s, .y = t*y*z+x*s, .z = t*z*z+c,   .w = 0.0},
            .r3 = .{.x = 0.0,       .y = 0.0,       .z = 0.0,       .w = 1.0},
        };
    }

    pub fn fromPos(v: vec.Vector3d) Mat4 {
        var out: Mat4 = Mat4.identity();
        out.r0.w = v.x;
        out.r1.w = v.y;
        out.r2.w = v.z;
        return out;
    }

    //From https://en.wikipedia.org/wiki/Quaternions_and_spatial_rotation#Quaternion-derived_rotation_matrix
    pub fn fromQuat(q: quat.Quaternion) Mat4 {
        return .{ //r=w, i=x, j=y, k=z
            .r0 = .{.x = 1.0-2*(q.val.y*q.val.y + q.val.z*q.val.z), .y = 2*(q.val.x*q.val.y - q.val.z*q.val.w),     .z = 2*(q.val.x*q.val.z + q.val.y*q.val.w),     .w = 0.0},
            .r1 = .{.x = 2*(q.val.x*q.val.y + q.val.z*q.val.w),     .y = 1.0-2*(q.val.x*q.val.x + q.val.z*q.val.z), .z = 2*(q.val.y*q.val.z - q.val.x*q.val.w),     .w = 0.0},
            .r2 = .{.x = 2*(q.val.x*q.val.z - q.val.y*q.val.w),     .y = 2*(q.val.y*q.val.z + q.val.x*q.val.w),     .z = 1.0-2*(q.val.x*q.val.x + q.val.y*q.val.y), .w = 0.0},
            .r3 = .{.x = 0.0,                                       .y = 0.0,                                       .z = 0.0,                                       .w = 1.0},
        };
    }

    pub fn fromQuatAndPos(q: quat.Quaternion, pos: vec.Vector3d) Mat4 {
        var out: Mat4 = fromQuat(q);

        out.r0.w = pos.x;
        out.r1.w = pos.y;
        out.r2.w = pos.z;

        return out;
    }
};

test "Identity test" {
    var matrix: Mat4 = Mat4.identity();
    const vector: vec.Vector4 = .{.w = 1.0, .x = 2.0, .y = 1.0, .z = 0.0};
    const result: vec.Vector4 = matrix.multVector4(vector);
    try result.expectEqual(.{.w = 1.0, .x = 2.0, .y = 1.0, .z = 0.0}, 0.01);
}

test "Translation test" {
    var matrix: Mat4 = Mat4.identity();
    matrix = matrix.translate(.{.x = 7.0, .y = -2.0, .z = 1.5});
    //matrix.debug_print_matrix();
    const vector: vec.Vector4 = .{.w = 1.0, .x = 2.0, .y = 1.0, .z = 0.0};
    const result: vec.Vector4 = matrix.multVector4(vector);
    //std.debug.print("\n\nResult: w:{d:.2} x:{d:.2} y:{d:.2} z:{d:.2}\n\n", .{result.w, result.x, result.y, result.z});
    try result.expectEqual(.{.w = 1.0, .x = 9.0, .y = -1.0, .z = 1.5}, 0.01);
}

test "Rotation test 1" {
    var matrix: Mat4 = Mat4.fromQuat(quat.Quaternion.fromAxisAngle(.{.x = 0.0, .y = 0.0, .z = 1.0}, std.math.degreesToRadians(180.0)));
    const vector: vec.Vector4 = .{.w = 1.0, .x = 2.0, .y = 1.0, .z = 0.0};
    const result: vec.Vector4 = matrix.multVector4(vector);
    try result.expectEqual(.{.w = 1.0, .x = -2.0, .y = -1.0, .z = 0.0}, 0.01);
}

test "Rotation test 2" {
    var matrix: Mat4 = Mat4.fromQuat(quat.Quaternion.fromAxisAngle(.{.x = 0.0, .y = 1.0, .z = 0.0}, std.math.degreesToRadians(90.0)));
    const vector: vec.Vector4 = .{.w = 1.0, .x = 2.0, .y = 1.0, .z = 0.0};
    const result: vec.Vector4 = matrix.multVector4(vector);
    try result.expectEqual(.{.w = 1.0, .x = 0.0, .y = 1.0, .z = -2.0}, 0.01);
}

test "Rotation and translation test" {
    var matrix: Mat4 = Mat4.fromQuat(quat.Quaternion.fromAxisAngle(.{.x = 0.0, .y = 1.0, .z = 0.0}, std.math.degreesToRadians(90.0)));
    const vector: vec.Vector4 = .{.w = 1.0, .x = 2.0, .y = 1.0, .z = 0.0};
    const result: vec.Vector4 = matrix.multVector4(vector);
    try result.expectEqual(.{.w = 1.0, .x = 0.0, .y = 1.0, .z = -2.0}, 0.01);
}

test "Matrix-Matrix multiplication test" {
    var rotMatrix: Mat4 = Mat4.fromQuat(quat.Quaternion.fromAxisAngle(.{.x = 0.0, .y = 1.0, .z = 0.0}, std.math.degreesToRadians(90.0)));
    var posMatrix: Mat4 = Mat4.fromPos(.{.x = 3.0, .y = 2.0, .z = -1.0});
    var composite: Mat4 = Mat4.multMatrix4(rotMatrix, posMatrix);
    
    const vector: vec.Vector4 = .{.w = 1.0, .x = 2.0, .y = 1.0, .z = 0.0};
    const moved: vec.Vector4 = posMatrix.multVector4(vector);
    const rotated: vec.Vector4 = rotMatrix.multVector4(moved);
    const transformed: vec.Vector4 = composite.multVector4(vector);
    try vec.Vector4.expectEqual(rotated, transformed, 0.01);
}