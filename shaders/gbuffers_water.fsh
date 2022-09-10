#version 120

varying vec2 TexCoords;
varying vec2 LightmapCoords;
uniform float frameTimeCounter;
varying vec3 Normal;
varying vec4 Color;
varying vec4 mc_Entity;
varying float blockID;

// The texture atlas
uniform sampler2D texture;

void main(){
    /*vec3 playerPos = getPlayerPos(texcoord, depth);
    vec3 viewDir = normalize(playerPos);
    vec3 reflectionDirection = reflect(viewDir, normal);
    vec3 screenSpaceReflectionPos = toScreenSpace(reflectionDirection);
    vec3 reflectColor = texture(u_color, screenSpaceReflectionPos.xy).rgb;*/

    vec4 color = vec4(0.0f, 0.25f, 0.4f, 0.6f);
    vec4 Albedo = texture2D(texture, TexCoords) * Color;
    int id = int(floor(blockID + 0.5));
    if (id == 10119){
         Albedo = color;
    }
    /* DRAWBUFFERS:012 */
    gl_FragData[0] = Albedo;
    gl_FragData[1] = vec4(Normal * 0.5f + 0.5f, 1.0f);
    gl_FragData[2] = vec4(LightmapCoords, 0.0f, 1.0f);
}