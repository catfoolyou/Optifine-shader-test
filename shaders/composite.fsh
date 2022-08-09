#version 120

#include "distort.glsl"

varying vec2 TexCoords;
varying vec2 lmcoord;
varying vec4 texcoord;

// Direction of the sun (not normalized!)
uniform vec3 sunPosition;

// The color textures which we wrote to
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex6;
uniform sampler2D depthtex0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D noisetex;
uniform sampler2D lightmap;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

uniform int worldTime;
uniform float rainStrength; 
uniform ivec2 eyeBrightness;
uniform vec3 skyColor;

/*
const int colortex0Format = RGBA16F;
const int colortex1Format = RGB16;
const int colortex2Format = RGB16;
*/

const float sunPathRotation = -20.0f;
const int shadowMapResolution = 600; // Shadowmap quality
const float shadowDistance = 75;
const int noiseTextureResolution = 32; 
const float shadowDistanceRenderMul = 1.0f;

vec2 AdjustLightmap(in vec2 Lightmap){
    vec2 NewLightMap;
    NewLightMap.x = 2.0 * pow(Lightmap.x, 5.06);
    NewLightMap.y = Lightmap.y;
    return NewLightMap;
}

// Input is not adjusted lightmap coordinates
vec3 GetLightmapColor(in vec2 Lightmap){
    // First adjust the lightmap
    Lightmap = AdjustLightmap(Lightmap);
    // Color of the torch and sky. The sky color changes depending on time of day but I will ignore that for simplicity
    const vec3 TorchColor = vec3(1.3f, 0.75f, 0.25f);
    const vec3 SkyColor = vec3(0.1f, 0.1f, 0.25f);
    // Add the lighting togther to get the total contribution of the lightmap the final color.
    vec3 LightmapLighting = (Lightmap.x * TorchColor) + (Lightmap.y * SkyColor * skyColor / 3);
    // Return the value
    return LightmapLighting;
}

float Visibility(in sampler2D ShadowMap, in vec3 SampleCoords) {
    return step(SampleCoords.z - 0.001f, texture2D(ShadowMap, SampleCoords.xy).r);
}

vec3 TransparentShadow(in vec3 SampleCoords){
    float ShadowVisibility0 = Visibility(shadowtex0, SampleCoords);
    float ShadowVisibility1 = Visibility(shadowtex1, SampleCoords);
    vec3 TransmittedColor = (texture2D(shadowcolor0, SampleCoords.xy)).rgb * (1.0f - (texture2D(shadowcolor0, SampleCoords.xy)).a); // Perform a blend operation with the sun color
    return mix(TransmittedColor * ShadowVisibility1, vec3(1.0f), ShadowVisibility0);
}

#define SHADOW_SAMPLES 2 // Higher gives better quality, lower gives better performance

vec3 GetShadow(float depth) {
    vec3 ClipSpace = vec3(TexCoords, depth) * 2.0f - 1.0f;
    vec4 ViewW = gbufferProjectionInverse * vec4(ClipSpace, 1.0f);
    vec3 View = ViewW.xyz / ViewW.w;
    vec4 World = gbufferModelViewInverse * vec4(View, 1.0f);
    vec4 ShadowSpace = shadowProjection * shadowModelView * World;
    ShadowSpace.xy = DistortPosition(ShadowSpace.xy);
    vec3 SampleCoords = ShadowSpace.xyz * 0.5f + 0.5f;
    float RandomAngle = texture2D(noisetex, TexCoords * 20.0f).r * 100.0f;
    float cosTheta = cos(RandomAngle);
	float sinTheta = sin(RandomAngle);
    mat2 Rotation =  mat2(cosTheta, -sinTheta, sinTheta, cosTheta) / shadowMapResolution; // We can move our division by the shadow map resolution here for a small speedup
    vec3 ShadowAccum = vec3(0.0f);
    for(int x = -SHADOW_SAMPLES; x <= SHADOW_SAMPLES; x++){
        for(int y = -SHADOW_SAMPLES; y <= SHADOW_SAMPLES; y++){
            vec2 Offset = Rotation * vec2(x, y);
            vec3 CurrentSampleCoordinate = vec3(SampleCoords.xy + Offset, SampleCoords.z);
            ShadowAccum += TransparentShadow(CurrentSampleCoordinate);
        }
    }
    ShadowAccum /= 25;
    return ShadowAccum;
}

void main(){
    float Vibrance = 1.9f;
    vec3 Albedo = pow(texture2D(colortex0, TexCoords).rgb, vec3(Vibrance));
    float Depth = texture2D(depthtex0, TexCoords).r;
    if(Depth == 1.0f){
        gl_FragData[0] = vec4(Albedo, 1.0f);
        return;
    }
    vec3 Normal = normalize(texture2D(colortex1, TexCoords).rgb);
    vec2 Lightmap = texture2D(colortex2, TexCoords).rg;
    vec3 LightmapColor = GetLightmapColor(Lightmap);
    float NdotL = 1.0f;
    if(worldTime >= 12786 && worldTime < 23961){
        NdotL = 0.0f; //
    }
    if(worldTime >= 2000 && worldTime < 12000){
        NdotL = 1.0f; // Day
    }
    if(worldTime >= 12000 && worldTime < 12542){
        NdotL = (((12000 - worldTime) * 0.65f) / 542) + 1.0f; // Early evening
    }
    if(worldTime >= 12542 && worldTime < 12786){
        NdotL = (((12542 - worldTime) * 0.35f) / 244) + 0.35f; // Late evening
    }
    if(worldTime >= 167 && worldTime < 2000){
        NdotL = (((worldTime - 167) * 0.65f) / 1833) + 0.35f; // Late morning
    }
    if(worldTime >= 23961 && worldTime < 24000){
        NdotL = ((worldTime - 23961) * 0.066f) / 39; // Early morning 1
    }
    if(worldTime >= 0 && worldTime < 167){
        NdotL = ((worldTime * 0.284f) / 167) + 0.066f; // Early morning 2
    }
    if(rainStrength > 0){
        NdotL = mix(1, 0, rainStrength); // Rain
    }
    vec3 Diffuse = Albedo * (LightmapColor + NdotL * GetShadow(Depth) + (NdotL / 5));
    /* DRAWBUFFERS:0 */
    // Finally write the diffuse color
    gl_FragData[0] = vec4(Diffuse, lmcoord.y);
}