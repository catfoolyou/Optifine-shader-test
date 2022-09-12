#version 120

uniform float viewHeight;
uniform float viewWidth;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjectionInverse;
uniform vec3 fogColor;
uniform vec3 skyColor;

varying vec4 starData; //rgb = star color, a = flag for weather or not this pixel is a star.

float fogify(float x, float w) {
	return w / (x * x + w);
}

  #define OMNI_TINT 0.5
  #define AMBIENT_MIDDLE_COLOR vec3(0.987528, 0.591192, 0.301392)
  #define AMBIENT_DAY_COLOR vec3(0.91954, 0.90804, 0.6762)
  #define AMBIENT_NIGHT_COLOR vec3(0.04693014, 0.0507353 , 0.05993107)

  #define HI_MIDDLE_COLOR vec3(0.117, 0.26, 0.494)
  #define HI_DAY_COLOR vec3(0.104, 0.26, 0.507)
  #define HI_NIGHT_COLOR vec3(0.014, 0.019, 0.025)

  #define LOW_MIDDLE_COLOR vec3(1.183, 0.658, 0.311)
  #define LOW_DAY_COLOR vec3(0.65, 0.91, 1.3)
  #define LOW_NIGHT_COLOR vec3(0.0213, 0.0306, 0.0387)

  #define WATER_COLOR vec3(0.018, 0.12 , 0.18)

vec3 calcSkyColor(vec3 pos) {
	float upDot = dot(pos, gbufferModelView[1].xyz);
	return mix(skyColor, fogColor, fogify(max(upDot, 0.0), 0.25));
}

void main() {
	vec3 color;
	if (starData.a > 0.5) {
		color = starData.rgb;
	}
	else {
		vec4 pos = vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight) * 2.0 - 1.0, 1.0, 1.0);
		pos = gbufferProjectionInverse * pos;
		color = calcSkyColor(normalize(pos.xyz));
	}

/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color, 1.0); //gcolor
}