﻿#ifndef CG_MATH_LAB
#define CG_MATH_LAB

// from shadergraph generated code
void mathlab_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
{
    Out = UV * Tiling + Offset;
}

float2 mathlab_gradientNoise_dir(float2 p)
{
    // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
    p = p % 289;
    float x = (34 * p.x + 1) * p.x % 289 + p.y;
    x = (34 * x + 1) * x % 289;
    x = frac(x / 41) * 2 - 1;
    return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
}

float mathlab_sineWave(float inputx, float frequency, float amplitude, float speed, float time)
{
    return sin(frequency * inputx + speed * time) * amplitude;
}
            
float mathlab_gradientNoise(float2 p)
{
    float2 ip = floor(p);
    float2 fp = frac(p);
    float d00 = dot(mathlab_gradientNoise_dir(ip), fp);
    float d01 = dot(mathlab_gradientNoise_dir(ip + float2(0, 1)), fp - float2(0, 1));
    float d10 = dot(mathlab_gradientNoise_dir(ip + float2(1, 0)), fp - float2(1, 0));
    float d11 = dot(mathlab_gradientNoise_dir(ip + float2(1, 1)), fp - float2(1, 1));
    fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
    return lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x);
}

#endif