#version 440

// Motion blur for a surface that has been rendered to a texture: a streak
// along its own velocity. With no velocity it is a plain copy, so the surface
// stays pixel-exact at rest.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 velocity;      // streak in texture coordinates
};

layout(binding = 1) uniform sampler2D source;

void main()
{
    if (dot(velocity, velocity) < 1.0e-9) {
        fragColor = texture(source, qt_TexCoord0) * qt_Opacity;
        return;
    }
    // Jitter the taps per pixel so the streak dithers instead of banding.
    float jitter = fract(sin(dot(qt_TexCoord0, vec2(12.9898, 78.233))) * 43758.5453) - 0.5;
    vec4 acc = vec4(0.0);
    for (int i = 0; i < 16; ++i) {
        float t = (float(i) + 0.5 + jitter) / 16.0 - 0.5;
        acc += texture(source, qt_TexCoord0 + velocity * t);
    }
    fragColor = acc * (1.0 / 16.0) * qt_Opacity;
}
