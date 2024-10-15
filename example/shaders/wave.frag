#version 300 es

precision mediump float;

#include <flutter/runtime_effect.glsl>

uniform float uTime;
uniform vec2 uSize;
uniform vec2 uOrigin;     // Uniform untuk origin
uniform sampler2D uTexture;

out vec4 fragColor;

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uSize;

    // Efek Ripple
    const float amplitude = 0.03;
    const float frequency = 15.0;
    const float decay = 2.0;
    const float speed = 1.0;

    float distance = length(uv - uOrigin);
    float delay = distance / speed;
    float time = max(0.0, uTime - delay);

    float rippleAmount = amplitude * sin(frequency * time) * exp(-decay * time);

    vec2 n = normalize(uv - uOrigin);
    vec2 newPosition = uv + rippleAmount * n;

    // Clamp newPosition ke [0,1] untuk mencegah sampling di luar tekstur
    newPosition = clamp(newPosition, vec2(0.0), vec2(1.0));

    vec4 color = texture(uTexture, newPosition);

    // Efek Glow di Tepi dengan Animasi Gelombang Sine
    float edgeGlowThickness = 0.04; // Ketebalan glow di tepi
    float edgeGlowIntensity = 1.9;  // Intensitas glow tepi

    // Hitung jarak ke tepi terdekat
    float edgeDistance = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));

    // Tentukan apakah fragmen berada di area tepi
    float isEdge = smoothstep(edgeGlowThickness, 0.0, edgeDistance);

    // Hitung posisi sepanjang tepi (0.0 hingga 1.0)
    float edgePos = 0.0;
    if (uv.x < edgeGlowThickness) {
        // Tepi Kiri
        edgePos = uv.y;
    } else if (uv.x > 1.0 - edgeGlowThickness) {
        // Tepi Kanan
        edgePos = 1.0 - uv.y;
    } else if (uv.y < edgeGlowThickness) {
        // Tepi Bawah
        edgePos = uv.x;
    } else if (uv.y > 1.0 - edgeGlowThickness) {
        // Tepi Atas
        edgePos = 1.0 - uv.x;
    }

    // Animasi gelombang sine di sepanjang tepi
    float wave = sin(edgePos * 10.0 + uTime * 5.0) * 0.5 + 0.5; // Normalisasi ke [0,1]

    // Faktor fade berdasarkan waktu animasi ripple
    float maxFade = (1.0 / decay) * exp(-1.0); // Normalisasi maksimum fade
    float fade = (time * exp(-decay * time)) / maxFade;

    // Modifikasi intensitas glow berdasarkan gelombang dan fade
    float animatedGlow = isEdge * wave * edgeGlowIntensity * fade;
    animatedGlow = max(animatedGlow, 0.0); // Pastikan tidak negatif

    // Warna gradient untuk glow tepi
    vec3 edgeGlowColor = vec3(
        0.5 + 0.5 * sin(uTime + edgePos * 6.28318),
        0.5 + 0.5 * sin(uTime + edgePos * 6.28318 + 2.0944),
        0.5 + 0.5 * sin(uTime + edgePos * 6.28318 + 4.1888)
    );

    // Terapkan glow di tepi
    vec4 edgeGlowFinalColor = vec4(edgeGlowColor, 1.0) * animatedGlow;

    // Gabungkan warna utama dengan efek glow
    fragColor = color + edgeGlowFinalColor;

    // Pastikan nilai fragColor berada dalam rentang yang valid
    fragColor = clamp(fragColor, 0.0, 1.0);
}
