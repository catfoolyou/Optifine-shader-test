#version 120

#define WAVING_WATER

varying vec4 color;
varying vec4 texcoord;
varying vec4 lmcoord;
varying vec4 position;
//varying vec4 bloommask;
varying vec3 binormal;
varying vec3 normal;
varying vec3 tangent;
varying vec3 viewVector;
varying vec3 wpos;
varying float iswater;

attribute vec4 mc_Entity;

uniform vec3 cameraPosition;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform int worldTime;
uniform float frameTimeCounter;

const float PI = 3.1415927;

void main() {
	
	
	//vec4 viewpos = gl_ModelViewMatrix * gl_Vertex;
	position = gl_ModelViewMatrix * gl_Vertex;
	iswater = 0.0f;
	float displacement = 0.0;
	
	/* un-rotate */
	vec4 viewpos = gbufferModelViewInverse * position;

	vec3 worldpos = viewpos.xyz + cameraPosition;
	wpos = worldpos;
	

#ifdef WAVING_WATER
	if(mc_Entity.x == 8.0 || mc_Entity.x == 9.0) {
	
		iswater = 1.0;
		float fy = fract(worldpos.y + 0.001);
		
	    if (fy > 0.002) {

			float wave = 0.05 * sin(2 * PI * (frameTimeCounter*0.75 + worldpos.x /  7.0 + worldpos.z / 13.0))
		               + 0.05 * sin(2 * PI * (frameTimeCounter*0.6 + worldpos.x / 11.0 + worldpos.z /  5.0));
			displacement = clamp(wave, -fy, 1.0-fy);
			viewpos.y += displacement;
		}
		
	}
#endif

	/* re-rotate */
	viewpos = gbufferModelView * viewpos;

	/* projectify */
	gl_Position = gl_ProjectionMatrix * viewpos;
	
	color = gl_Color;
	
	texcoord = gl_TextureMatrix[0] * gl_MultiTexCoord0;

	lmcoord = gl_TextureMatrix[1] * gl_MultiTexCoord1;
	
	gl_FogFragCoord = gl_Position.z;
	
	tangent = vec3(0.0);
	binormal = vec3(0.0);
	normal = normalize(gl_NormalMatrix * normalize(gl_Normal));

	if (gl_Normal.x > 0.5) {
		//  1.0,  0.0,  0.0
		tangent  = normalize(gl_NormalMatrix * vec3( 0.0,  0.0, -1.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0, -1.0,  0.0));
	}
	
	else if (gl_Normal.x < -0.5) {
		// -1.0,  0.0,  0.0
		tangent  = normalize(gl_NormalMatrix * vec3( 0.0,  0.0,  1.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0, -1.0,  0.0));
	}
	
	else if (gl_Normal.y > 0.5) {
		//  0.0,  1.0,  0.0
		tangent  = normalize(gl_NormalMatrix * vec3( 1.0,  0.0,  0.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0,  0.0,  1.0));
	}
	
	else if (gl_Normal.y < -0.5) {
		//  0.0, -1.0,  0.0
		tangent  = normalize(gl_NormalMatrix * vec3( 1.0,  0.0,  0.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0,  0.0,  1.0));
	}
	
	else if (gl_Normal.z > 0.5) {
		//  0.0,  0.0,  1.0
		tangent  = normalize(gl_NormalMatrix * vec3( 1.0,  0.0,  0.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0, -1.0,  0.0));
	}
	
	else if (gl_Normal.z < -0.5) {
		//  0.0,  0.0, -1.0
		tangent  = normalize(gl_NormalMatrix * vec3(-1.0,  0.0,  0.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0, -1.0,  0.0));
	}
	
	mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
							tangent.y, binormal.y, normal.y,
							tangent.z, binormal.z, normal.z);
	
		vec3 newnormal = vec3(sin(displacement*PI),1.0-cos(displacement*PI),displacement);
	
			vec3 bump = newnormal;
			bump = bump;
		
		float bumpmult = 0.05;
	
	
	bump = bump * vec3(bumpmult, bumpmult, bumpmult) + vec3(0.0f, 0.0f, 1.0f - bumpmult);
		
		normal = bump * tbnMatrix;
		
	viewVector = (gl_ModelViewMatrix * gl_Vertex).xyz;
	viewVector = normalize(tbnMatrix * viewVector);
	
	
}