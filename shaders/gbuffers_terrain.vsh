#version 120

varying vec2 TexCoords;
varying vec2 LightmapCoords;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform float frameTimeCounter;
varying vec3 Normal;
varying vec4 Color;
attribute vec4 mc_Entity;

void main() {
    // Transform the vertex
    gl_Position = ftransform();
    // Assign values to varying variables
    vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
    TexCoords = gl_MultiTexCoord0.st;
    // Grass
    if (mc_Entity.x == 10031 || mc_Entity.x == 10059 || mc_Entity.x == 10175 || mc_Entity.x == 10176 || mc_Entity.x == 10177){
        position.x += cos(position.z + (frameTimeCounter * 2)) / 17;
        position.z += cos(position.x + (frameTimeCounter * 2)) / 17;
        gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
    }
    // Leaves
    if (mc_Entity.x == 10018){
        position.x += sin(position.z + (frameTimeCounter * 2)) / 17;
        position.z += cos(position.x + (frameTimeCounter * 2)) / 17;
        gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
    }
    LightmapCoords = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.st;
    // Transform them into the [0, 1] range
    LightmapCoords = (LightmapCoords * 33.05f / 32.0f) - (1.05f / 32.0f);
    Normal = gl_NormalMatrix * gl_Normal;
    Color = gl_Color;
}