#include "/lib/settings.glsl"

flat varying vec2 TAA_Offset;
flat varying vec3 WsunVec;

uniform sampler2D colortex4;

uniform int frameCounter;
uniform float sunElevation;
uniform vec3 sunPosition;
uniform mat4 gbufferModelViewInverse;
#include "/lib/util.glsl"
#include "/lib/res_params.glsl"

uniform int framemod8;
const vec2[8] offsets = vec2[8](vec2(1./8.,-3./8.),
							vec2(-1.,3.)/8.,
							vec2(5.0,1.)/8.,
							vec2(-3,-5.)/8.,
							vec2(-5.,5.)/8.,
							vec2(-7.,-1.)/8.,
							vec2(3,7.)/8.,
							vec2(7.,-7.)/8.);
void main() {
	gl_Position = ftransform();

	WsunVec = (float(sunElevation > 1e-5)*2-1.)*normalize(mat3(gbufferModelViewInverse) * sunPosition);
	

	#ifdef TAA
		TAA_Offset = offsets[framemod8];
	#else
		TAA_Offset = vec2(0.0);
	#endif

	#ifdef TAA_UPSCALING
		gl_Position.xy = (gl_Position.xy*0.5+0.5)*RENDER_SCALE*2.0-1.0;
	#endif
}
