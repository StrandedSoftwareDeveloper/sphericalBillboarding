//-------------------------------------------------------J.M.J.-------------------------------------------------------
#version 330 core

in vec3 FragPos;

out vec4 FragColor;

uniform mat4 world;
uniform mat4 view;
uniform mat4 projection;

void main() {
    vec3 objPos = world[3].xyz;
    vec3 pos = FragPos - objPos;
    gl_FragColor = vec4(FragPos, 0.0);
}
