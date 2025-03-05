//-------------------------------------------------------J.M.J.-------------------------------------------------------
#version 330 core

layout (location = 0) in vec3 aPos;

out vec3 FragPos;

uniform mat4 world;
uniform mat4 view;
uniform mat4 projection;

void main() {
    vec4 pos = world * vec4(aPos, 1.0);
    FragPos = aPos.xyz;
    pos = view * pos;
    gl_Position = projection * pos;
}
