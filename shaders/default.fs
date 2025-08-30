#version 330 core

in vec2 fragTexCoord;
in vec3 fragNormal;
in vec4 fragColor;
in vec3 vWorldPos;
in float vTime;

out vec4 finalColor;

uniform sampler2D texture0; // Raylib's primary texture
uniform vec4 colDiffuse;    // Raylib's material color

void main() {
    vec4 texColor = texture(texture0, fragTexCoord);
    finalColor = texColor * colDiffuse * fragColor;
}