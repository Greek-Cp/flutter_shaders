#version 300 es

precision mediump float;

#include <flutter/runtime_effect.glsl>

uniform float uTime;
uniform vec2 uSize;
uniform vec2 uOrigin;     // Uniform for origin
uniform sampler2D uTexture;

out vec4 fragColor;

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uSize;

    // Ripple Effect
    const float amplitude = 0.03;
    const float frequency = 15.0;
    const float decay = 2.0;
    const float speed = 1.0;

    float distance = length(uv - uOrigin);
    float delay = distance / speed;
    float time = max(0.0, uTime - delay);

    // Calculate ripple amount
    float rippleAmount = amplitude * sin(frequency * time) * exp(-decay * time);

    vec2 n = normalize(uv - uOrigin);
    vec2 newPosition = uv + rippleAmount * n;

    // Clamp newPosition to [0,1] to prevent sampling outside the texture
    newPosition = clamp(newPosition, vec2(0.0), vec2(1.0));

    vec4 color = texture(uTexture, newPosition);

    // Edge Glow Effect tied to Ripple Effect
    float edgeGlowThickness = 0.04; // Thickness of the glow at the edges
    float edgeGlowIntensity = 1.0;  // Intensity of the edge glow

    // Calculate distance to the nearest edge
    float edgeDistance = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));

    // Determine if the fragment is in the edge area
    float isEdge = smoothstep(edgeGlowThickness, 0.0, edgeDistance);

    // Calculate the time when the ripple reaches the edge
    float distLeft = uOrigin.x;
    float distRight = 1.0 - uOrigin.x;
    float distTop = 1.0 - uOrigin.y;
    float distBottom = uOrigin.y;
    float maxDistanceToEdge = max(max(distLeft, distRight), max(distTop, distBottom));
    float edgeDelay = maxDistanceToEdge / speed;

    // Edge time relative to when the ripple reaches the edge
    float edgeTime = max(0.0, uTime - edgeDelay);

    // Use the same decay function for the edge glow
    float edgeGlowFade = exp(-decay * edgeTime);

    // Sine wave animation along the edge
    float wave = sin(uTime * 5.0 + edgeDistance * 50.0) * 0.5 + 0.5; // Normalize to [0,1]

    // Modify glow intensity based on wave and edge glow fade
    float animatedGlow = isEdge * wave * edgeGlowIntensity * edgeGlowFade;

    // Gradient color for the edge glow
    vec3 edgeGlowColor = vec3(
        0.5 + 0.5 * sin(uTime * 3.0 + edgeDistance * 20.0),
        0.5 + 0.5 * sin(uTime * 4.0 + edgeDistance * 30.0),
        0.5 + 0.5 * sin(uTime * 5.0 + edgeDistance * 40.0)
    );

    // Apply glow at the edge with full opacity
    vec4 edgeColor = vec4(edgeGlowColor, 1.0);

    // Combine edge color with base color using mix function
    fragColor = mix(color, edgeColor, animatedGlow);

    // Ensure fragColor values stay within valid range
    fragColor = clamp(fragColor, 0.0, 1.0);
}
