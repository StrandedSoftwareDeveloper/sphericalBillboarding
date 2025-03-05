//-------------------------------------------------------J.M.J.-------------------------------------------------------
#version 330 core

in vec3 FragPos;

out vec4 FragColor;

uniform mat4 sphereWorld;
uniform mat4 world;
uniform mat4 view;
uniform mat4 projection;
uniform sampler2D xAxis;
uniform sampler2D yAxis;
uniform sampler2D zAxis;

vec4 sampleTriplanar(vec3 pos) {
    vec2 xAxisUV = pos.zy * 0.5 + 0.5;
    xAxisUV.x *= 0.5;
    xAxisUV.x = 0.5-xAxisUV.x;
    xAxisUV.y = 1.0-xAxisUV.y;
    if (pos.x < 0.0) {
        xAxisUV.x += 0.5;
    } else {
        xAxisUV.x = 0.5-xAxisUV.x;
    }
    
    vec2 yAxisUV = pos.xz * 0.5 + 0.5;
    yAxisUV.x *= 0.5;
    yAxisUV.y = 1.0-yAxisUV.y;
    if (pos.y < 0.0) {
        yAxisUV.x += 0.5;
    }
    
    vec2 zAxisUV = pos.xy * 0.5 + 0.5;
    zAxisUV.x *= 0.5;
    zAxisUV.y = 1.0-zAxisUV.y;
    if (pos.z > 0.0) {
        zAxisUV.x = 0.5 - zAxisUV.x;
        zAxisUV.x += 0.5;
    }
    
    vec4 xColor = texture(xAxis, xAxisUV);
    vec4 yColor = texture(yAxis, yAxisUV);
    vec4 zColor = texture(zAxis, zAxisUV);
    
    vec3 weights = abs(pos);
    weights /= weights.x + weights.y + weights.z;
    return (xColor * weights.x) + (yColor * weights.y) + (zColor * weights.z);
}

void main() {
    vec3 posOnSphere = normalize(FragPos);
    
    gl_FragColor = sampleTriplanar(posOnSphere);
}
