#version 330

in vec2 fragTexCoord;
out vec4 finalColor;

uniform sampler2D texture0; // the scene texture
uniform vec2 playerPos;      // player position in screen space (pixels)
uniform float radius;        // visibility radius in pixels
uniform vec2 screenSize;     // screen width/height

void main() {
    // Convert UV -> screen coords
    vec2 fragPos = fragTexCoord * screenSize;

    // Distance from player
    float dist = distance(fragPos, playerPos);

    // Smooth visibility: 0 = fully visible, 1 = fully black
    // Flip the order of radius arguments
    float visibility = 1.0 - smoothstep(radius*0.8, radius, dist);
    
    // Sample the scene
    vec4 sceneColor = texture(texture0, fragTexCoord);

    // Mix scene with black based on visibility
    finalColor = sceneColor * visibility;
}
