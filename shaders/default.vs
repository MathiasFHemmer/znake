#version 330 core

in vec3 vertexPosition;
in vec2 vertexTexCoord;
in vec3 vertexNormal;
in vec4 vertexColor;

out vec2 fragTexCoord;
out vec3 fragNormal;
out vec4 fragColor;
out vec3 vWorldPos;
out float vTime;

uniform mat4 matModel;      // Raylib's model matrix
uniform mat4 matView;       // Raylib's view matrix  
uniform mat4 matProjection; // Raylib's projection matrix
uniform vec3 worldPos;
uniform float time;

void main() {
    fragTexCoord = vertexTexCoord;
    fragNormal = vertexNormal;
    fragColor = vertexColor;
	vWorldPos = worldPos;
	vTime = time;
    gl_Position = matProjection * matView * matModel * vec4(vertexPosition, 1.0);
}