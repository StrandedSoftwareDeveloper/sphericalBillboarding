//-------------------------------------------------------J.M.J.-------------------------------------------------------
#version 330 core

layout (location = 0) in vec3 aPos;

out vec3 FragPos;

uniform mat4 sphereWorld;
uniform mat4 world;
uniform mat4 view;
uniform mat4 projection;
uniform sampler2D xHeight;
uniform sampler2D yHeight;
uniform sampler2D zHeight;

vec4 sampleTriplanar(vec3 normal) {
    vec2 xAxisUV = normal.zy * 0.5 + 0.5;
    xAxisUV.x *= 0.5;
    xAxisUV.x = 0.5-xAxisUV.x;
    xAxisUV.y = 1.0-xAxisUV.y;
    if (normal.x < 0.0) {
        xAxisUV.x += 0.5;
    } else {
        xAxisUV.x = 0.5-xAxisUV.x;
    }
    
    vec2 yAxisUV = normal.xz * 0.5 + 0.5;
    yAxisUV.x *= 0.5;
    yAxisUV.y = 1.0-yAxisUV.y;
    if (normal.y < 0.0) {
        yAxisUV.x += 0.5;
    }
    
    vec2 zAxisUV = normal.xy * 0.5 + 0.5;
    zAxisUV.x *= 0.5;
    zAxisUV.y = 1.0-zAxisUV.y;
    if (normal.z > 0.0) {
        zAxisUV.x = 0.5 - zAxisUV.x;
        zAxisUV.x += 0.5;
    }
    
    vec4 xColor = texture(xHeight, xAxisUV);
    vec4 yColor = texture(yHeight, yAxisUV);
    vec4 zColor = texture(zHeight, zAxisUV);
    
    vec3 weights = abs(normal);
    weights /= weights.x + weights.y + weights.z;
    return (xColor * weights.x) + (yColor * weights.y) + (zColor * weights.z);
}

void main() {
    FragPos = (sphereWorld * view * vec4(aPos, 1.0)).xyz;
    vec3 objPos = sphereWorld[3].xyz;
    
    vec4 height4 = sampleTriplanar(normalize(FragPos));
    float height = height4.x * 0.1/*0.011279*/ + 1.0;
    
    gl_Position = projection * /*view */ world * vec4(aPos * height, 1.0);
}
