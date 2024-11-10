#include "/lib/settings.glsl"

// #if defined END_SHADER || defined NETHER_SHADER
// 	#undef IS_LPV_ENABLED
// #endifs

#ifdef IS_LPV_ENABLED
	#extension GL_ARB_shader_image_load_store: enable
	#extension GL_ARB_shading_language_packing: enable
#endif

#include "/lib/res_params.glsl"


const bool colortex5MipmapEnabled = true;

#ifdef OVERWORLD_SHADER
	const bool shadowHardwareFiltering = true;
	uniform sampler2DShadow shadow;

	#ifdef TRANSLUCENT_COLORED_SHADOWS
		uniform sampler2D shadowcolor0;
		uniform sampler2DShadow shadowtex0;
		uniform sampler2DShadow shadowtex1;
	#endif

	flat varying vec3 averageSkyCol_Clouds;
	flat varying vec4 lightCol;


	#if Sun_specular_Strength != 0
		#define LIGHTSOURCE_REFLECTION
	#endif
	
	#include "/lib/lightning_stuff.glsl"
#endif

#ifdef NETHER_SHADER
	uniform float nightVision;
	uniform sampler2D colortex4;
	const bool colortex4MipmapEnabled = true;
	uniform vec3 lightningEffect;
	// #define LIGHTSOURCE_REFLECTION
#endif

#ifdef END_SHADER
	uniform float nightVision;
	uniform sampler2D colortex4;
	uniform vec3 lightningEffect;
	
	flat varying float Flashing;
	// #define LIGHTSOURCE_REFLECTION
#endif

uniform int hideGUI;
uniform sampler2D noisetex; //noise
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;

#ifdef DISTANT_HORIZONS
uniform sampler2D dhDepthTex;
uniform sampler2D dhDepthTex1;
#endif

uniform sampler2D colortex0; //clouds
uniform sampler2D colortex1; //albedo(rgb),material(alpha) RGBA16
uniform sampler2D colortex2; //translucents(rgba)
uniform sampler2D colortex3; //filtered shadowmap(VPS)
// uniform sampler2D colortex4; //LUT(rgb), quarter res depth(alpha)
uniform sampler2D colortex5; //TAA buffer/previous frame
uniform sampler2D colortex6; //Noise
uniform sampler2D colortex7; //water?
uniform sampler2D colortex8; //Specular
// uniform sampler2D colortex9; //Specular
uniform sampler2D colortex10;
uniform sampler2D colortex11;
uniform sampler2D colortex12;
uniform sampler2D colortex13;
uniform sampler2D colortex14;
uniform sampler2D colortex15; // flat normals(rgb), vanillaAO(alpha)

#ifdef IS_LPV_ENABLED
	uniform usampler1D texBlockData;
	uniform sampler3D texLpv1;
	uniform sampler3D texLpv2;
#endif


uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

// uniform float far;
uniform float near;
uniform float farPlane;
uniform float dhFarPlane;
uniform float dhNearPlane;

flat varying vec3 zMults;

uniform vec2 texelSize;
uniform float viewWidth;
uniform float viewHeight;
uniform float aspectRatio;

uniform float eyeAltitude;
flat varying vec2 TAA_Offset;

uniform int frameCounter;
uniform float frameTimeCounter;

uniform float rainStrength;
uniform int isEyeInWater;
uniform ivec2 eyeBrightnessSmooth;

uniform vec3 sunVec;
flat varying vec3 WsunVec;
flat varying vec3 unsigned_WsunVec;
flat varying float exposure;

#ifdef IS_LPV_ENABLED
	uniform int heldItemId;
	uniform int heldItemId2;
#endif

#define diagonal3(m) vec3((m)[0].x, (m)[1].y, m[2].z)
#define  projMAD(m, v) (diagonal3(m) * (v) + (m)[3].xyz)

void convertHandDepth(inout float depth) {
    float ndcDepth = depth * 2.0 - 1.0;
    ndcDepth /= MC_HAND_DEPTH;
    depth = ndcDepth * 0.5 + 0.5;
}
float convertHandDepth_2(in float depth, bool hand) {
	if(!hand) return depth;

    float ndcDepth = depth * 2.0 - 1.0;
    ndcDepth /= MC_HAND_DEPTH;
    return ndcDepth * 0.5 + 0.5;
}

vec3 toScreenSpace(vec3 p) {
	vec4 iProjDiag = vec4(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y, gbufferProjectionInverse[2].zw);
    vec3 feetPlayerPos = p * 2. - 1.;
    vec4 viewPos = iProjDiag * feetPlayerPos.xyzz + gbufferProjectionInverse[3];
    return viewPos.xyz / viewPos.w;
}




#include "/lib/color_transforms.glsl"
#include "/lib/waterBump.glsl"
#include "/lib/sky_gradient.glsl"

#include "/lib/Shadow_Params.glsl"
#include "/lib/Shadows.glsl"
#include "/lib/stars.glsl"

#ifdef OVERWORLD_SHADER
	#include "/lib/volumetricClouds.glsl"
#endif

#include "/lib/util.glsl"

#ifdef IS_LPV_ENABLED
	#include "/lib/hsv.glsl"
	#include "/lib/lpv_common.glsl"
	#include "/lib/lpv_render.glsl"
#endif

#include "/lib/diffuse_lighting.glsl"

float ld(float dist) {
    return (2.0 * near) / (far + near - dist * (far - near));
}

vec3 decode (vec2 encn){
    vec3 n = vec3(0.0);
    encn = encn * 2.0 - 1.0;
    n.xy = abs(encn);
    n.z = 1.0 - n.x - n.y;
    n.xy = n.z <= 0.0 ? (1.0 - n.yx) * sign(encn) : encn;
    return clamp(normalize(n.xyz),-1.0,1.0);
}
vec2 decodeVec2(float a){
    const vec2 constant1 = 65535. / vec2( 256., 65536.);
    const float constant2 = 256. / 255.;
    return fract( a * constant1 ) * constant2 ;
}


#include "/lib/end_fog.glsl"
#include "/lib/specular.glsl"



#include "/lib/DistantHorizons_projections.glsl"

float DH_ld(float dist) {
    return (2.0 * dhNearPlane) / (dhFarPlane + dhNearPlane - dist * (dhFarPlane - dhNearPlane));
}
float DH_inv_ld (float lindepth){
	return -((2.0*dhNearPlane/lindepth)-dhFarPlane-dhNearPlane)/(dhFarPlane-dhNearPlane);
}

float linearizeDepthFast(const in float depth, const in float near, const in float far) {
    return (near * far) / (depth * (near - far) + far);
	// return (2.0 * near) / (far + near - depth * (far - near));
}
float invertlinearDepthFast(const in float depth, const in float near, const in float far) {
	return ((2.0*near/depth)-far-near)/(far-near);
}


vec3 normVec (vec3 vec){
	return vec*inversesqrt(dot(vec,vec));
}
float lengthVec (vec3 vec){
	return sqrt(dot(vec,vec));
}
#define fsign(a)  (clamp((a)*1e35,0.,1.)*2.-1.)
float triangularize(float dither)
{
    float center = dither*2.0-1.0;
    dither = center*inversesqrt(abs(center));
    return clamp(dither-fsign(center),0.0,1.0);
}

vec3 fp10Dither(vec3 color,float dither){
	const vec3 mantissaBits = vec3(6.,6.,5.);
	vec3 exponent = floor(log2(color));
	return color + dither*exp2(-mantissaBits)*exp2(exponent);
}



// float facos(float sx){
//     float x = clamp(abs( sx ),0.,1.);
//     return sqrt( 1. - x ) * ( -0.16882 * x + 1.56734 );
// }

vec2 tapLocation(int sampleNumber,int nb, float nbRot,float jitter,float distort)
{
	float alpha0 = sampleNumber/nb;
    float alpha = (sampleNumber+jitter)/nb;
    float angle = jitter*6.28 + alpha * 4.0 * 6.28;

    float sin_v, cos_v;

	sin_v = sin(angle);
	cos_v = cos(angle);

    return vec2(cos_v, sin_v)*sqrt(alpha);
}


vec3 BilateralFiltering(sampler2D tex, sampler2D depth,vec2 coord,float frDepth,float maxZ){
  vec4 sampled = vec4(texelFetch2D(tex,ivec2(coord),0).rgb,1.0);

  return vec3(sampled.x,sampled.yz/sampled.w);
}
float interleaved_gradientNoise(){
	vec2 coord = gl_FragCoord.xy + (frameCounter%40000) * 2.0;
	float noise = fract( 52.9829189 * fract( (coord.x * 0.06711056) + (coord.y * 0.00583715) ) );
	return noise ;
}
float R2_dither(){
	vec2 coord = gl_FragCoord.xy + (frameCounter%40000) * 2.0;
	vec2 alpha = vec2(0.75487765, 0.56984026);
	return fract(alpha.x * coord.x + alpha.y * coord.y ) ;
}
float blueNoise(){
  return fract(texelFetch2D(noisetex, ivec2(gl_FragCoord.xy)%512, 0).a + 1.0/1.6180339887 * frameCounter);
}
vec4 blueNoise(vec2 coord){
  return texelFetch2D(colortex6, ivec2(coord)%512 , 0) ;
}

vec3 toShadowSpaceProjected(vec3 feetPlayerPos){
	
	mat4 DH_shadowProjection = DH_shadowProjectionTweak(shadowProjection);

    feetPlayerPos = mat3(gbufferModelViewInverse) * feetPlayerPos + gbufferModelViewInverse[3].xyz;
    feetPlayerPos = mat3(shadowModelView) * feetPlayerPos + shadowModelView[3].xyz;
    feetPlayerPos = diagonal3(DH_shadowProjection) * feetPlayerPos + DH_shadowProjection[3].xyz;

    return feetPlayerPos;
}

vec2 tapLocation(int sampleNumber, float spinAngle,int nb, float nbRot,float r0)
{
    float alpha = (float(sampleNumber*1.0f + r0) * (1.0 / (nb)));
    float angle = alpha * (nbRot * 6.28) + spinAngle*6.28;

    float ssR = alpha;
    float sin_v, cos_v;

	sin_v = sin(angle);
	cos_v = cos(angle);

    return vec2(cos_v, sin_v)*ssR;
}
vec2 tapLocation_simple(
	int samples, int totalSamples, float rotation, float rng
){
	const float PI = 3.141592653589793238462643383279502884197169;
    float alpha = float(samples + rng) * (1.0 / float(totalSamples));
    float angle = alpha * (rotation * PI);

	float sin_v = sin(angle);
	float cos_v = cos(angle);

    return vec2(cos_v, sin_v) * sqrt(alpha);
}

vec2 CleanSample(
	int samples, float totalSamples, float noise
){

	// this will be used to make 1 full rotation of the spiral. the mulitplication is so it does nearly a single rotation, instead of going past where it started
	float variance = noise * 0.897;

	// for every sample input, it will have variance applied to it.
	float variedSamples = float(samples) + variance;
	
	// for every sample, the sample position must change its distance from the origin.
	// otherwise, you will just have a circle.
    float spiralShape = pow(variedSamples / (totalSamples + variance),0.5);

	float shape = 2.26; // this is very important. 2.26 is very specific
    float theta = variedSamples * (PI * shape);

	float x =  cos(theta) * spiralShape;
	float y =  sin(theta) * spiralShape;

    return vec2(x, y);
}
vec3 viewToWorld(vec3 viewPos) {
    vec4 pos;
    pos.xyz = viewPos;
    pos.w = 0.0;
    pos = gbufferModelViewInverse * pos;
    return pos.xyz;
}
vec3 worldToView(vec3 worldPos) {
    vec4 pos = vec4(worldPos, 0.0);
    pos = gbufferModelView * pos;
    return pos.xyz;
}

void waterVolumetrics_notoverworld(inout vec3 inColor, vec3 rayStart, vec3 rayEnd, float estEndDepth, float estSunDepth, float rayLength, float dither, vec3 waterCoefs, vec3 scatterCoef, vec3 ambient){
		inColor *= exp(-rayLength * waterCoefs);	//No need to take the integrated value
		int spCount = rayMarchSampleCount;
		vec3 start = toShadowSpaceProjected(rayStart);
		vec3 end = toShadowSpaceProjected(rayEnd);
		vec3 dV = (end-start);
		//limit ray length at 32 blocks for performance and reducing integration error
		//you can't see above this anyway
		float maxZ = min(rayLength,12.0)/(1e-8+rayLength);
		dV *= maxZ;
		vec3 dVWorld = -mat3(gbufferModelViewInverse) * (rayEnd - rayStart) * maxZ;
		rayLength *= maxZ;
		estEndDepth *= maxZ;
		estSunDepth *= maxZ;
		vec3 absorbance = vec3(1.0);
		vec3 vL = vec3(0.0);


		float expFactor = 11.0;
		vec3 progressW = gbufferModelViewInverse[3].xyz+cameraPosition;
		for (int i=0;i<spCount;i++) {
			float d = (pow(expFactor, float(i+dither)/float(spCount))/expFactor - 1.0/expFactor)/(1-1.0/expFactor);
			float dd = pow(expFactor, float(i+dither)/float(spCount)) * log(expFactor) / float(spCount)/(expFactor-1.0);
			vec3 spPos = start.xyz + dV*d;
			progressW = gbufferModelViewInverse[3].xyz+cameraPosition + d*dVWorld;

			vec3 ambientMul = exp(-max(estEndDepth * d,0.0) * waterCoefs);

			vec3 light =  (ambientMul*ambient) * scatterCoef;

			vL += (light - light * exp(-waterCoefs * dd * rayLength)) / waterCoefs *absorbance;
			absorbance *= exp(-dd * rayLength * waterCoefs);
		}
		inColor += vL;
}

#ifdef OVERWORLD_SHADER


float fogPhase(float lightPoint){
	float linear = 1.0 - clamp(lightPoint*0.5+0.5,0.0,1.0);
	float linear2 = 1.0 - clamp(lightPoint,0.0,1.0);

	float exponential = exp2(pow(linear,0.3) * -15.0 ) * 1.5;
	exponential += sqrt(exp2(sqrt(linear) * -12.5));

	return exponential;
}

void waterVolumetrics(inout vec3 inColor, vec3 rayStart, vec3 rayEnd, float estEndDepth, float estSunDepth, float rayLength, float dither, vec3 waterCoefs, vec3 scatterCoef, vec3 ambient, vec3 lightSource, float VdotL){
	int spCount = rayMarchSampleCount;

	vec3 start = toShadowSpaceProjected(rayStart);
	vec3 end = toShadowSpaceProjected(rayEnd);
	vec3 dV = (end-start);

	//limit ray length at 32 blocks for performance and reducing integration error
	//you can't see above this anyway
	float maxZ = min(rayLength,12.0)/(1e-8+rayLength);
	dV *= maxZ;
	rayLength *= maxZ;
	estEndDepth *= maxZ;
	estSunDepth *= maxZ;
	
	vec3 wpos = mat3(gbufferModelViewInverse) * rayStart  + gbufferModelViewInverse[3].xyz;
	vec3 dVWorld = (wpos - gbufferModelViewInverse[3].xyz);

	inColor *= exp(-rayLength * waterCoefs);	// No need to take the integrated value
	float phase = fogPhase(VdotL) * 5.0;
	vec3 absorbance = vec3(1.0);
	vec3 vL = vec3(0.0);

	float expFactor = 11.0;
	for (int i=0;i<spCount;i++) {
		float d = (pow(expFactor, float(i+dither)/float(spCount))/expFactor - 1.0/expFactor)/(1-1.0/expFactor);
		float dd = pow(expFactor, float(i+dither)/float(spCount)) * log(expFactor) / float(spCount)/(expFactor-1.0);
		vec3 spPos = start.xyz + dV*d;

		vec3 progressW = start.xyz+cameraPosition+dVWorld;

		//project into biased shadowmap space
		#ifdef DISTORT_SHADOWMAP
			float distortFactor = calcDistort(spPos.xy);
		#else
			float distortFactor = 1.0;
		#endif

		vec3 pos = vec3(spPos.xy*distortFactor, spPos.z);
		float sh = 1.0;
		if (abs(pos.x) < 1.0-0.5/2048. && abs(pos.y) < 1.0-0.5/2048){
			pos = pos*vec3(0.5,0.5,0.5/6.0)+0.5;
			sh =  shadow2D( shadow, pos).x;
		}

		#ifdef VL_CLOUDS_SHADOWS
			sh *= GetCloudShadow_VLFOG(progressW,WsunVec);
		#endif

		vec3 sunMul = exp(-estSunDepth * d * waterCoefs * 1.1);
		vec3 ambientMul = exp(-estEndDepth * d * waterCoefs );

		vec3 Directlight = (lightSource * phase * sunMul) * sh;
		vec3 Indirectlight = ambient * ambientMul;

		vec3 light = (Indirectlight + Directlight) * scatterCoef;

		vL += (light - light * exp(-waterCoefs * dd * rayLength)) / waterCoefs * absorbance;
		absorbance *= exp(-waterCoefs * dd * rayLength);
	}
	inColor += vL;
}

#endif

vec2 SSRT_Shadows(vec3 viewPos, bool depthCheck, vec3 lightDir, float noise, bool isSSS, bool hand){
   
	float handSwitch = hand ? 1.0 : 0.0;

    float steps = 16.0;
	float Shadow = 1.0; 
	float SSS = 0.0;
	
	float _near = near; float _far = far*4.0;

	if (depthCheck) {
		_near = dhNearPlane;
		_far = dhFarPlane;
	}
    
	vec3 clipPosition = toClipSpace3_DH(viewPos, depthCheck);

	//prevents the ray from going behind the camera
	float rayLength = ((viewPos.z + lightDir.z * _far*sqrt(3.)) > -_near) ?
      				  (-_near -viewPos.z) / lightDir.z : _far*sqrt(3.);

    vec3 direction = toClipSpace3_DH(viewPos + lightDir*rayLength, depthCheck) - clipPosition;  //convert to clip space
    direction.xyz = direction.xyz / max(abs(direction.x)/texelSize.x, abs(direction.y)/texelSize.y);	//fixed step size
	
	float Stepmult = depthCheck ? (isSSS ? 0.5 : 6.0) : (isSSS ? 1.0 : 3.0);

	// Stepmult = depthCheck ? 0.5 : 1.0;
	

    vec3 rayDir = direction * Stepmult  * vec3(RENDER_SCALE,1.0);
	
	vec3 screenPos = clipPosition * vec3(RENDER_SCALE,1.0) + rayDir*noise;
	if(isSSS) screenPos -= rayDir*0.9;

	for (int i = 0; i < int(steps); i++) {
		
		screenPos += rayDir;
	

		float samplePos = convertHandDepth_2(texture2D(depthtex1, screenPos.xy).x, hand);
		
		#ifdef DISTANT_HORIZONS
			if(depthCheck) samplePos = texture2D(dhDepthTex1, screenPos.xy).x;
		#endif

		if(samplePos <= screenPos.z) {
			vec2 linearZ = vec2(linearizeDepthFast(screenPos.z, _near, _far), linearizeDepthFast(samplePos, _near, _far));
			float calcthreshold = abs(linearZ.x - linearZ.y) / linearZ.x;

			bool depthThreshold1 = calcthreshold < mix(0.015, 0.035,  handSwitch);
			bool depthThreshold2 = calcthreshold < 0.05;

			if (depthThreshold1) Shadow = 0.0;

			if (depthThreshold2) SSS = i/steps;
				
		}
	}

	return vec2(Shadow, SSS);
}


void Emission(
	inout vec3 Lighting,
	vec3 Albedo,
	float Emission,
	float exposure
){
	float autoBrightnessAdjust = mix(5.0, 100.0, clamp(exp(-10.0*exposure),0.0,1.0));
	if( Emission < 254.5/255.0) Lighting = mix(Lighting, Albedo * Emissive_Brightness * autoBrightnessAdjust, pow(Emission, Emissive_Curve)); // old method.... idk why
	// if( Emission < 254.5/255.0 ) Lighting += (Albedo * Emissive_Brightness) * pow(Emission, Emissive_Curve);
}

#include "/lib/indirect_lighting_effects.glsl"
#include "/lib/PhotonGTAO.glsl"

vec4 BilateralUpscale(sampler2D tex, sampler2D depth, vec2 coord, float referenceDepth){
  
	const ivec2 scaling = ivec2(1.0/VL_RENDER_RESOLUTION);
	ivec2 posDepth  = ivec2(coord*VL_RENDER_RESOLUTION) * scaling;
	ivec2 posColor  = ivec2(coord*VL_RENDER_RESOLUTION);

  	ivec2 pos = ivec2(gl_FragCoord.xy*texelSize + 1);

	ivec2 getRadius[4] = ivec2[](
   	 	ivec2(-2,-2),
	  	ivec2(-2, 0),
		ivec2( 0, 0),
		ivec2( 0,-2)
  	);
	
	float diffThreshold = zMults.x;

	vec4 RESULT = vec4(0.0);
	float SUM = 0.0;

	for (int i = 0; i < 4; i++) {
		
		ivec2 radius = getRadius[i];
		
		float offsetDepth = ld(texelFetch2D(depth, posDepth + radius * scaling + pos * scaling, 0).r);
		
		float EDGES = abs(offsetDepth - referenceDepth) < diffThreshold ? 1.0 : 1e-5;
		
		RESULT += texelFetch2D(tex, posColor + radius + pos, 0) * EDGES;
		
		SUM += EDGES;
	}
	// return vec4(0,0,0,1) * SUM;
	return RESULT / SUM;
}

vec4 BilateralUpscale_DH(sampler2D tex, sampler2D depth, vec2 coord, float referenceDepth){
	ivec2 scaling = ivec2(1.0/VL_RENDER_RESOLUTION);
	ivec2 posDepth  = ivec2(coord*VL_RENDER_RESOLUTION) * scaling;
	ivec2 posColor  = ivec2(coord*VL_RENDER_RESOLUTION);
 	ivec2 pos = ivec2(gl_FragCoord.xy*texelSize + 1);

	ivec2 getRadius[4] = ivec2[](
   		ivec2(-2,-2),
	 	ivec2(-2, 0),
		ivec2( 0, 0),
		ivec2( 0,-2)
  	);

	#ifdef DISTANT_HORIZONS
		float diffThreshold = 0.01;
	#else
		float diffThreshold = zMults.x;
	#endif

	vec4 RESULT = vec4(0.0);
	float SUM = 0.0;

	for (int i = 0; i < 4; i++) {
		
		ivec2 radius = getRadius[i];

		#ifdef DISTANT_HORIZONS
			float offsetDepth = sqrt(texelFetch2D(depth, posDepth + radius * scaling + pos * scaling,0).a/65000.0);
		#else
			float offsetDepth = ld(texelFetch2D(depth, posDepth + radius * scaling + pos * scaling, 0).r);
		#endif

		float EDGES = abs(offsetDepth - referenceDepth) < diffThreshold ? 1.0 : 1e-5;
		
		RESULT += texelFetch2D(tex, posColor + radius + pos, 0) * EDGES;

		SUM += EDGES;
	}
	// return vec4(1) * SUM;
	return RESULT / SUM;

}

void BilateralUpscale_REUSE_Z(sampler2D tex1, sampler2D tex2, sampler2D depth, vec2 coord, float referenceDepth, inout vec2 ambientEffects, inout vec3 filteredShadow, bool hand){
	ivec2 scaling = ivec2(1.0);
	ivec2 posDepth  = ivec2(coord) * scaling;
	ivec2 posColor  = ivec2(coord);
  	ivec2 pos = ivec2(gl_FragCoord.xy*texelSize + 1);

	ivec2 getRadius[4] = ivec2[](
   	 	ivec2(-2,-2),
	  	ivec2(-2, 0),
		ivec2( 0, 0),
		ivec2( 0,-2)
  	);

	#ifdef DISTANT_HORIZONS
		float diffThreshold = 0.0005;
	#else
		float diffThreshold = 0.005;
	#endif

	vec3 shadow_RESULT = vec3(0.0);
	vec2 ssao_RESULT = vec2(0.0);
	vec4 fog_RESULT = vec4(0.0);
	float SUM = 0.0;

	for (int i = 0; i < 4; i++) {
		
		ivec2 radius = getRadius[i];

		#ifdef DISTANT_HORIZONS
			float offsetDepth = sqrt(texelFetch2D(depth, posDepth + radius * scaling + pos * scaling,0).a/65000.0);
		#else
			float offsetDepth = ld(texelFetch2D(depth, posDepth + radius * scaling + pos * scaling, 0).r);
		#endif

		float EDGES = abs(offsetDepth - referenceDepth) < diffThreshold ? 1.0 : 1e-5;
		// #ifdef Variable_Penumbra_Shadows
			shadow_RESULT += texelFetch2D(tex1, posColor + radius + pos, 0).rgb * EDGES;
		// #endif

		#if indirect_effect == 1
			ssao_RESULT += texelFetch2D(tex2, posColor + radius + pos, 0).rg * EDGES;
		#endif

		SUM += EDGES;
	}
	// #ifdef Variable_Penumbra_Shadows
		filteredShadow = shadow_RESULT/SUM;
	// #endif
	#if indirect_effect == 1
		ambientEffects = ssao_RESULT/SUM;
	#endif
}

#ifdef OVERWORLD_SHADER
float ComputeShadowMap(in vec3 projectedShadowPosition, float distortFactor, float noise, float shadowBlockerDepth, float NdotL, float maxDistFade, inout vec3 directLightColor, inout float FUNNYSHADOW, bool isSSS){

	if(maxDistFade <= 0.0) return 1.0;
	float backface = NdotL <= 0.0 ? 1.0 : 0.0;

	float shadowmap = 0.0;
	vec3 translucentTint = vec3(0.0);

	#ifdef BASIC_SHADOW_FILTER
		int samples = SHADOW_FILTER_SAMPLE_COUNT;
		float rdMul = shadowBlockerDepth*distortFactor*d0*k/shadowMapResolution;
		
		for(int i = 0; i < samples; i++){
			// vec2 offsetS = tapLocation_simple(i, 7, 9, noise) * 0.5;
			vec2 offsetS = CleanSample(i, samples - 1, noise) * 0.3;
			projectedShadowPosition.xy += rdMul*offsetS;
	#else
		int samples = 1;
	#endif
		#ifdef TRANSLUCENT_COLORED_SHADOWS
			// determine when opaque shadows are overlapping translucent shadows by getting the difference of opaque depth and translucent depth
			float shadowDepthDiff = pow(clamp((shadow2D(shadowtex1, projectedShadowPosition).x - projectedShadowPosition.z*0.6)*2.0,0.0,1.0),2.0);

			// get opaque shadow data to get opaque data from translucent shadows.
			float opaqueShadow = shadow2D(shadowtex0, projectedShadowPosition).x;
			shadowmap += max(opaqueShadow, shadowDepthDiff);

			// get translucent shadow data
			vec4 translucentShadow = texture2D(shadowcolor0, projectedShadowPosition.xy);

			// this curve simply looked the nicest. it has no other meaning.
			float shadowAlpha = pow(1.0 - pow(translucentShadow.a,5.0),0.2);

			FUNNYSHADOW = shadowAlpha;

			// normalize the color to remove luminance, and keep the hue. remove all opaque color.
			// mulitply shadow alpha to shadow color, but only on surfaces facing the lightsource. this is a tradeoff to protect subsurface scattering's colored shadow tint from shadow bias on the back of the caster.
			translucentShadow.rgb = max(normalize(translucentShadow.rgb + 0.0001), max(opaqueShadow, 1.0-shadowAlpha)) * max(shadowAlpha,  backface * (1.0 - shadowDepthDiff));

			float translucentMask = 1 - max(shadowDepthDiff-opaqueShadow, 0);
			// make it such that full alpha areas that arent in a shadow have a value of 1.0 instead of 0.0
			translucentTint += mix(translucentShadow.rgb, vec3(1.0),  opaqueShadow*shadowDepthDiff);
		#else
			shadowmap += shadow2D(shadow, projectedShadowPosition).x;
		#endif
	#ifdef BASIC_SHADOW_FILTER
		}
	#endif

	#ifdef TRANSLUCENT_COLORED_SHADOWS
		// tint the lightsource color with the translucent shadow color
		directLightColor *= mix(vec3(1.0), translucentTint.rgb / samples, maxDistFade);
	#endif

	// return maxDistFade;

	return mix(1.0, shadowmap / samples, maxDistFade);

}
#endif

float CustomPhase(float LightPos){

	float PhaseCurve = 1.0 - LightPos;
	float Final = exp2(sqrt(PhaseCurve) * -25.0);
	Final += exp(PhaseCurve * -10.0)*0.5;

	return Final;
}

vec3 SubsurfaceScattering_sun(vec3 albedo, float Scattering, float Density, float lightPos, float shadows){
	
	Scattering *= sss_density_multiplier;

	float density = 0.0001 + Density*2.0;
	
	float scatterDepth = max(1.0 - Scattering/density,0.0);
	scatterDepth = exp((1.0-scatterDepth) * -7.0);

	// this is for SSS when there is no shadow blocker depth
	#if defined BASIC_SHADOW_FILTER && defined Variable_Penumbra_Shadows
		scatterDepth = max(scatterDepth, pow(shadows, 0.5 + (1.0-Density) * 2.0)  );
	#else
		scatterDepth = exp(-7.0 * pow(1.0-shadows,3.0))*min(2.0-sss_density_multiplier,1.0);
	#endif


	// PBR at its finest :clueless:
	vec3 absorbColor = exp(max(luma(albedo) - albedo*vec3(1.0,1.1,1.2), 0.0) * -(20.0 - 19*scatterDepth) * sss_absorbance_multiplier);
	
	vec3 scatter = scatterDepth * absorbColor * pow(Density, LabSSS_Curve);

	scatter *= 1.0 + CustomPhase(lightPos)*6.0; // ~10x brighter at the peak

	return scatter;
}

vec3 SubsurfaceScattering_sky(vec3 albedo, float Scattering, float Density){
	
	Scattering *= sss_density_multiplier;
	
	float scatterDepth = 1.0 - pow(Scattering, 0.5 + Density * 2.5);

	// PBR at its finest :clueless:
	vec3 absorbColor = exp(max(luma(albedo) - albedo*vec3(1.0,1.1,1.2), 0.0)  * -(15.0 - 10.0*scatterDepth)  * sss_absorbance_multiplier);
	
	vec3 scatter = scatterDepth * absorbColor * pow(Density, LabSSS_Curve);

	return scatter;
}

void main() {

		vec3 DEBUG = vec3(1.0);

	////// --------------- SETUP STUFF --------------- //////
		vec2 texcoord = gl_FragCoord.xy*texelSize;
	
		vec2 bnoise = blueNoise(gl_FragCoord.xy).rg;
		int seed = (frameCounter%40000) + frameCounter*2;
		float noise = fract(R2_samples(seed).y + bnoise.y);
		float noise_2 = R2_dither();

		float z0 = texture2D(depthtex0,texcoord).x;
		float z = texture2D(depthtex1,texcoord).x;
		float swappedDepth = z;

		bool isDHrange = z >= 1.0;

		#ifdef DISTANT_HORIZONS
			float DH_mixedLinearZ = sqrt(texture2D(colortex12,texcoord).a/65000.0);
			float DH_depth0 = texture2D(dhDepthTex,texcoord).x;
			float DH_depth1 = texture2D(dhDepthTex1,texcoord).x;

			float depthOpaque = z;
			float depthOpaqueL = linearizeDepthFast(depthOpaque, near, farPlane);
			
			#ifdef DISTANT_HORIZONS
			    float dhDepthOpaque = DH_depth1;
			    float dhDepthOpaqueL = linearizeDepthFast(dhDepthOpaque, dhNearPlane, dhFarPlane);

				if (depthOpaque >= 1.0 || (dhDepthOpaqueL < depthOpaqueL && dhDepthOpaque > 0.0)){
			        depthOpaque = dhDepthOpaque;
			        depthOpaqueL = dhDepthOpaqueL;
			    }
			#endif

			swappedDepth = depthOpaque;
		#else
			float DH_depth0 = 0.0;
			float DH_depth1 = 0.0;
		#endif

	


	////// --------------- UNPACK OPAQUE GBUFFERS --------------- //////
	
		vec4 data = texture2D(colortex1,texcoord);

		vec4 dataUnpacked0 = vec4(decodeVec2(data.x),decodeVec2(data.y)); // albedo, masks
		vec4 dataUnpacked1 = vec4(decodeVec2(data.z),decodeVec2(data.w)); // normals, lightmaps
		// vec4 dataUnpacked2 = vec4(decodeVec2(data.z),decodeVec2(data.w));

		vec3 albedo = toLinear(vec3(dataUnpacked0.xz,dataUnpacked1.x));
		vec3 normal = decode(dataUnpacked0.yw);
		vec2 lightmap = dataUnpacked1.yz;//min(max(dataUnpacked1.yz - 0.05,0.0)*1.06,1.0);// small offset to hide flickering from precision error in the encoding/decoding on values close to 1.0 or 0.0
		

		#if defined END_SHADER || defined NETHER_SHADER
			lightmap.y = 1.0;
		#endif

		// if(isEyeInWater == 1) lightmap.y = max(lightmap.y, 0.75);

	////// --------------- UNPACK MISC --------------- //////
	
		vec4 SpecularTex = texture2D(colortex8,texcoord);
		float LabSSS = clamp((-65.0 + SpecularTex.z * 255.0) / 190.0 ,0.0,1.0);	

		vec4 normalAndAO = texture2D(colortex15,texcoord);
		vec3 FlatNormals = normalAndAO.rgb * 2.0 - 1.0;
		vec3 slopednormal = normal;

		float vanilla_AO = z < 1.0 ? clamp(normalAndAO.a,0,1) : 0.0;
		normalAndAO.a = clamp(pow(normalAndAO.a*5,4),0,1);

		if(isDHrange){
			slopednormal = normal;
			FlatNormals = worldToView(normal);
		}


	////// --------------- MASKS/BOOLEANS --------------- //////
		// 1.0-0.8 ???
		// 0.75 = hand mask
		// 0.60 = grass mask
		// 0.55 = leaf mask (for ssao-sss)
		// 0.50 = lightning bolt mask
		// 0.45 = entity mask
		float opaqueMasks = dataUnpacked1.w;
		// 1.0 = water mask
		// 0.9 = entity mask
		// 0.8 = reflective entities
		// 0.7 = reflective blocks
  		float translucentMasks = texture2D(colortex7, texcoord).a;

		bool isWater = translucentMasks > 0.99;
		// bool isReflectiveEntity = abs(translucentMasks - 0.8) < 0.01;
		// bool isReflective = abs(translucentMasks - 0.7) < 0.01 || isWater || isReflectiveEntity;
		// bool isEntity = abs(translucentMasks - 0.9) < 0.01 || isReflectiveEntity;

		bool lightningBolt = abs(opaqueMasks-0.5) <0.01;
		bool isLeaf = abs(opaqueMasks-0.55) <0.01;
		bool entities = abs(opaqueMasks-0.45) < 0.01;	
		bool isGrass = abs(opaqueMasks-0.60) < 0.01;
		bool hand = abs(opaqueMasks-0.75) < 0.01 && z < 1.0;
		// bool blocklights = abs(opaqueMasks-0.8) <0.01;


		if(hand){
			convertHandDepth(z);
			convertHandDepth(z0);
		}

		#ifdef DISTANT_HORIZONS
			vec3 viewPos = toScreenSpace_DH(texcoord/RENDER_SCALE-TAA_Offset*texelSize*0.5, z, DH_depth1);
		#else
			vec3 viewPos = toScreenSpace(vec3(texcoord/RENDER_SCALE - TAA_Offset*texelSize*0.5,z));
		#endif
		
		vec3 feetPlayerPos = mat3(gbufferModelViewInverse) * viewPos;
		vec3 feetPlayerPos_normalized = normVec(feetPlayerPos);

		#ifdef POM
			#ifdef Horrible_slope_normals
    			vec3 ApproximatedFlatNormal = normalize(cross(dFdx(feetPlayerPos), dFdy(feetPlayerPos))); // it uses depth that has POM written to it.
				slopednormal = normalize(clamp(normal, ApproximatedFlatNormal*2.0 - 1.0, ApproximatedFlatNormal*2.0 + 1.0) );
			#endif
		#endif
	////// --------------- COLORS --------------- //////

		float dirtAmount = Dirt_Amount + 0.01;
		vec3 waterEpsilon = vec3(Water_Absorb_R, Water_Absorb_G, Water_Absorb_B);
		vec3 dirtEpsilon = vec3(Dirt_Absorb_R, Dirt_Absorb_G, Dirt_Absorb_B);
		vec3 totEpsilon = dirtEpsilon*dirtAmount + waterEpsilon;
		vec3 scatterCoef = dirtAmount * vec3(Dirt_Scatter_R, Dirt_Scatter_G, Dirt_Scatter_B) / 3.14;

		#ifdef BIOME_TINT_WATER
			// yoink the biome tint written in this buffer for water only.
			if(isWater){
				vec2 translucentdata = texture2D(colortex11,texcoord).gb;
				vec3 wateralbedo = vec3(decodeVec2(translucentdata.x),decodeVec2(translucentdata.y).x);
				scatterCoef = dirtAmount * wateralbedo / 3.14;
			}
		#endif
		vec3 Absorbtion = vec3(1.0);
		vec3 AmbientLightColor = vec3(0.0);
		vec3 MinimumLightColor = vec3(1.0);
		vec3 Indirect_lighting = vec3(0.0);
		vec3 Indirect_SSS = vec3(0.0);
		
		vec3 DirectLightColor = vec3(0.0);
		vec3 Direct_lighting = vec3(0.0);
		vec3 Direct_SSS = vec3(0.0);
		float cloudShadow = 1.0;
		float Shadows = 1.0;
		float NdotL = 1.0;
		float lightLeakFix = clamp(pow(eyeBrightnessSmooth.y/240. + lightmap.y,2.0) ,0.0,1.0);

		#ifdef OVERWORLD_SHADER
			DirectLightColor = lightCol.rgb / 80.0;
			AmbientLightColor = averageSkyCol_Clouds / 30.0;
			
			#ifdef PER_BIOME_ENVIRONMENT
				// BiomeSunlightColor(DirectLightColor);
				vec3 biomeDirect = DirectLightColor; 
				vec3 biomeIndirect = AmbientLightColor;
				float inBiome = BiomeVLFogColors(biomeDirect, biomeIndirect);

				float maxDistance = inBiome * min(max(1.0 -  length(feetPlayerPos)/(32*8),0.0)*2.0,1.0);
				DirectLightColor = mix(DirectLightColor, biomeDirect, maxDistance);
			#endif

			bool inShadowmapBounds = false;
		#endif

	#ifdef CLOUDS_INFRONT_OF_WORLD
		float heightRelativeToClouds = clamp(cameraPosition.y - LAYER0_minHEIGHT,0.0,1.0);
		vec4 Clouds = texture2D_bicubic_offset(colortex0, texcoord*CLOUDS_QUALITY, noise, RENDER_SCALE.x);
	#endif
	
	////////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////	    FILTER STUFF      //////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////
	
	vec3 filteredShadow = vec3(1.412,1.0,0.0);
	vec2 SSAO_SSS = vec2(1.0);
	
	#ifdef DISTANT_HORIZONS
		BilateralUpscale_REUSE_Z(colortex3,	colortex14, colortex12, gl_FragCoord.xy, DH_mixedLinearZ, SSAO_SSS, filteredShadow, hand);
	#else
		BilateralUpscale_REUSE_Z(colortex3,	colortex14, depthtex0, gl_FragCoord.xy, ld(z0), SSAO_SSS, filteredShadow, hand);
	#endif

	// SSAO_SSS = texture2D(colortex14,texcoord).xy;
	// filteredShadow = texture2D(colortex3,texcoord).xyz;
	// filteredShadow.rgb = vec3(filteredShadow.x, temporallyReprojectedData.gb);
	// SSAO_SSS.x = temporallyReprojectedData.a;

	float ShadowBlockerDepth = filteredShadow.y;
	// Shadows = vec3(clamp(1.0-filteredShadow.b,0.0,1.0));
	// shadowMap = vec3(Shadows);
	
	
	////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////	START DRAW	    ////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////
	if (swappedDepth >= 1.0) {
		#ifdef OVERWORLD_SHADER
			vec3 Background = vec3(0.0);
			
			#if RESOURCEPACK_SKY == 1 || RESOURCEPACK_SKY == 0
				// vec3 orbitstar = vec3(feetPlayerPos_normalized.x,abs(feetPlayerPos_normalized.y),feetPlayerPos_normalized.z); orbitstar.x -= WsunVec.x*0.2;

				vec3 orbitstar = normalize(mat3(gbufferModelViewInverse) * toScreenSpace(vec3(texcoord,1.0)));
				float radiance = 2.39996 - (worldTime + worldDay*24000.0) / 24000.0;
				// float radiance = 2.39996 + frameTimeCounter;
				mat2 rotationMatrix  = mat2(vec2(cos(radiance),  -sin(radiance)),  vec2(sin(radiance),  cos(radiance)));
				
				orbitstar.xy *= rotationMatrix;

				Background += stars(orbitstar) * 10.0 * clamp(-unsigned_WsunVec.y*2.0,0.0,1.0);
			#endif

			#if RESOURCEPACK_SKY == 2
				Background += toLinear(texture2D(colortex10, texcoord).rgb * (255.0 * 2.0));
			#else
				#if RESOURCEPACK_SKY == 1
					Background += toLinear(texture2D(colortex10, texcoord).rgb * (255.0 * 2.0));
				#endif
				#ifndef ambientLight_only
					Background += drawSun(dot(lightCol.a * WsunVec, feetPlayerPos_normalized),0, DirectLightColor,vec3(0.0));
					Background += drawMoon(feetPlayerPos_normalized,  lightCol.a * WsunVec, DirectLightColor*20, Background); 
				#endif
			#endif

			Background *= 1.0 - exp2(-50.0 * pow(clamp(feetPlayerPos_normalized.y+0.025,0.0,1.0),2.0)  ); // darken the ground in the sky.
			
			vec3 Sky = skyFromTex(feetPlayerPos_normalized, colortex4)/30.0;
			Background += Sky;

			#ifdef VOLUMETRIC_CLOUDS
				#ifdef CLOUDS_INFRONT_OF_WORLD
					if(heightRelativeToClouds < 1.0) Background = Background * Clouds.a + Clouds.rgb;
				#else
					vec4 Clouds = texture2D_bicubic_offset(colortex0, texcoord*CLOUDS_QUALITY, noise, RENDER_SCALE.x);
					Background = Background * Clouds.a + Clouds.rgb;
				#endif
			#endif

			gl_FragData[0].rgb = clamp(fp10Dither(Background, triangularize(noise_2)), 0.0, 65000.);
		#endif

		#if defined NETHER_SHADER || defined END_SHADER
			gl_FragData[0].rgb = vec3(0);
		#endif

	} else {

		feetPlayerPos += gbufferModelViewInverse[3].xyz;
	
	////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////	MAJOR LIGHTSOURCE STUFF 	////////////////////////
	////////////////////////////////////////////////////////////////////////////////////
	
	#ifdef OVERWORLD_SHADER
		float LM_shadowMapFallback = min(max(lightmap.y-0.8, 0.0) * 25,1.0);

		float LightningPhase = 0.0;
		vec3 LightningFlashLighting = Iris_Lightningflash(feetPlayerPos, lightningBoltPosition.xyz, slopednormal, LightningPhase) * pow(lightmap.y,10);

		NdotL = clamp((-15 + dot(slopednormal, WsunVec)*255.0) / 240.0  ,0.0,1.0);
		// NdotL = 1;
		float flatNormNdotL = clamp((-15 + dot(viewToWorld(FlatNormals), WsunVec)*255.0) / 240.0  ,0.0,1.0);
		
		// setup shadow projection
		vec3 shadowPlayerPos = mat3(gbufferModelViewInverse) * viewPos + gbufferModelViewInverse[3].xyz;
		if(!hand) GriAndEminShadowFix(shadowPlayerPos, viewToWorld(FlatNormals), vanilla_AO, lightmap.y);
		
		vec3 projectedShadowPosition = mat3(shadowModelView) * shadowPlayerPos + shadowModelView[3].xyz;
		projectedShadowPosition = diagonal3(shadowProjection) * projectedShadowPosition + shadowProjection[3].xyz;

		#if OPTIMIZED_SHADOW_DISTANCE > 0.0
			float shadowMapFalloff = smoothstep(0.0, 1.0, min(max(1.0 - length(feetPlayerPos) / (shadowDistance+16),0.0)*5.0,1.0));
			float shadowMapFalloff2 = smoothstep(0.0, 1.0, min(max(1.0 - length(feetPlayerPos) / shadowDistance,0.0)*5.0,1.0));
		#else
			vec3 shadowEdgePos = projectedShadowPosition * vec3(0.4,0.4,0.5/6.0) + vec3(0.5,0.5,0.12);
      		float fadeLength = max((shadowDistance/256)*30,10.0); 

      		vec3 cubicRadius = clamp(   min((1.0-shadowEdgePos)*fadeLength, shadowEdgePos*fadeLength),0.0,1.0);
      		float shadowmapFade = cubicRadius.x*cubicRadius.y*cubicRadius.z;

        	shadowmapFade = 1.0 - pow(1.0-pow(shadowmapFade,1.5),3.0); // make it nice and soft :)

			float shadowMapFalloff = shadowmapFade;
			float shadowMapFalloff2 = shadowmapFade;
		#endif

		// un-distort
		#ifdef DISTORT_SHADOWMAP
			float distortFactor = calcDistort(projectedShadowPosition.xy);
			projectedShadowPosition.xy *= distortFactor;
		#else
			float distortFactor = 1.0;
		#endif

		projectedShadowPosition = projectedShadowPosition * vec3(0.5,0.5,0.5/6.0) + vec3(0.5,0.5,0.5) ;

		float ShadowAlpha = 0.0; // this is for subsurface scattering later.
		Shadows = ComputeShadowMap(projectedShadowPosition, distortFactor, noise_2, filteredShadow.x, flatNormNdotL, shadowMapFalloff, DirectLightColor, ShadowAlpha, LabSSS > 0.0);

		if(!isWater) Shadows *= mix(LM_shadowMapFallback, 1.0, shadowMapFalloff2);

		#ifdef OLD_LIGHTLEAK_FIX
			if (isEyeInWater == 0) Shadows *= lightLeakFix; // light leak fix
		#endif
	#endif
	
	////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////	UNDER WATER SHADING		////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////////
 		if ((isEyeInWater == 0 && isWater) || (isEyeInWater == 1 && !isWater)){
			#ifdef DISTANT_HORIZONS
				vec3 viewPos0 = toScreenSpace_DH(texcoord/RENDER_SCALE-TAA_Offset*texelSize*0.5, z0, DH_depth0);
			#else
				vec3 viewPos0 = toScreenSpace(vec3(texcoord/RENDER_SCALE-TAA_Offset*texelSize*0.5,z0));
			#endif

			float Vdiff = distance(viewPos, viewPos0)*mix(5.0,2.0,clamp(pow(eyeBrightnessSmooth.y/240. + lightmap.y,2.0) ,0.0,1.0));
			float estimatedDepth = Vdiff * abs(feetPlayerPos_normalized.y);	//assuming water plane

			// make it such that the estimated depth flips to be correct when entering water.
			if (isEyeInWater == 1){
				estimatedDepth = 40.0 * pow(max(1.0-lightmap.y,0.0),2.0);
				MinimumLightColor = vec3(10.0);
			}

			float depthfalloff = 1.0 - clamp(exp(-0.1*estimatedDepth),0.0,1.0);
			

			float estimatedSunDepth = Vdiff; //assuming water plane
			Absorbtion = mix(exp(-2.0 * totEpsilon * estimatedDepth), exp(-8.0 * totEpsilon), depthfalloff);

			// DirectLightColor *= Absorbtion;

			// apply caustics to the lighting, and make sure they dont look weird
			DirectLightColor *= mix(1.0, waterCaustics(feetPlayerPos + cameraPosition, WsunVec)*WATER_CAUSTICS_BRIGHTNESS + 0.25, clamp(estimatedDepth,0,1));
		}


	#ifdef END_SHADER
		float vortexBounds = clamp(vortexBoundRange - length(feetPlayerPos+cameraPosition), 0.0,1.0);
        vec3 lightPos = LightSourcePosition(feetPlayerPos+cameraPosition, cameraPosition,vortexBounds);

		float lightningflash = texelFetch2D(colortex4,ivec2(1,1),0).x/150.0;
		vec3 lightColors = LightSourceColors(vortexBounds, lightningflash);
		
		float end_NdotL = clamp(dot(slopednormal, normalize(-lightPos))*0.5+0.5,0.0,1.0);
		end_NdotL *= end_NdotL;

		float fogShadow = GetCloudShadow(feetPlayerPos+cameraPosition, lightPos);
		float endPhase = endFogPhase(lightPos);

		Direct_lighting += lightColors * endPhase * end_NdotL * fogShadow;
		AmbientLightColor += lightColors * (endPhase*endPhase) * (1.0-exp(vec3(0.6,2.0,2) * -(endPhase*0.1))) ;
	#endif
	
	/////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////	INDIRECT LIGHTING 	/////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////

		#if defined OVERWORLD_SHADER && (indirect_effect == 0 || indirect_effect == 1)
			float allDirections = dot(abs(slopednormal),vec3(1.0));
			vec3 ambientcoefs = slopednormal / allDirections;
			float SkylightDir = ambientcoefs.y*1.5;
			
			if(isGrass) SkylightDir = 1.25;

			float skylight = max(pow(viewToWorld(FlatNormals).y*0.5+0.5,0.1) + SkylightDir, 0.2 + (1-lightmap.y)*0.8) ;

			#if indirect_effect == 1
				skylight =  min(skylight, mix(0.95, 2.5, pow(1-pow(1-SSAO_SSS.x, 0.5),2.0)	));
			#endif

			Indirect_lighting = AmbientLightColor * skylight;
		#endif

		#ifdef NETHER_SHADER
			// Indirect_lighting = skyCloudsFromTexLOD2(normal, colortex4, 6).rgb / 15.0;

			// vec3 up 	= skyCloudsFromTexLOD2(vec3( 0, 1, 0), colortex4, 6).rgb/ 30.0;
			// vec3 down 	= skyCloudsFromTexLOD2(vec3( 0,-1, 0), colortex4, 6).rgb/ 30.0;

			// up   *= pow( max( slopednormal.y, 0), 2);
			// down *= pow( max(-slopednormal.y, 0), 2);
			// Indirect_lighting += up + down;

			Indirect_lighting = vec3(0.05);
		#endif
		
		#ifdef END_SHADER
			Indirect_lighting += (vec3(0.5,0.75,1.0) * 0.9 + 0.1) * 0.1;

			Indirect_lighting *= clamp(1.5 + dot(normal, feetPlayerPos_normalized)*0.5,0,2);
		#endif
	
		#ifdef IS_LPV_ENABLED
			vec3 normalOffset = 0.5*viewToWorld(FlatNormals);

			#if LPV_NORMAL_STRENGTH > 0
				vec3 texNormalOffset = -normalOffset + slopednormal;
				normalOffset = mix(normalOffset, texNormalOffset, (LPV_NORMAL_STRENGTH*0.01));
			#endif

			vec3 lpvPos = GetLpvPosition(feetPlayerPos) + normalOffset;
		#else
			const vec3 lpvPos = vec3(0.0);
		#endif

		Indirect_lighting = DoAmbientLightColor(feetPlayerPos, lpvPos, Indirect_lighting, MinimumLightColor, vec3(TORCH_R,TORCH_G,TORCH_B) , lightmap.xy, exposure);
		
		#ifdef OVERWORLD_SHADER
			Indirect_lighting += LightningFlashLighting;
		#endif

		#ifdef SSS_view
			Indirect_lighting = vec3(3.0);
		#endif

	/////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////	EFFECTS FOR INDIRECT	/////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////

		float SkySSS = 1.0;
		vec3 AO = vec3(1.0);

		#if indirect_effect == 0
			AO = pow(1.0 - vanilla_AO*vanilla_AO,5.0) * vec3(1.0);
			Indirect_lighting *= AO;
		#endif

		#if indirect_effect == 1
			SkySSS = SSAO_SSS.y;

			float vanillaAO_curve = pow(1.0 - vanilla_AO*vanilla_AO,5.0);
			float SSAO_curve = pow(SSAO_SSS.x,6.0);

			// use the min of vanilla ao so they dont overdarken eachother
			AO = vec3( min(vanillaAO_curve, SSAO_curve) );
			
			Indirect_lighting *= AO;
		#endif

		// GTAO
		#if indirect_effect == 2
			vec2 r2 = fract(R2_samples((frameCounter%40000) + frameCounter*2) + bnoise);
			Indirect_lighting = AmbientLightColor/2.5;
			
			AO = ambient_occlusion(vec3(texcoord/RENDER_SCALE-TAA_Offset*texelSize*0.5,z), viewPos, worldToView(slopednormal), r2) * vec3(1.0);

			Indirect_lighting *= AO;
		#endif

		// RTAO and/or SSGI
		#if indirect_effect == 3 || indirect_effect == 4
			Indirect_lighting = AmbientLightColor;
			ApplySSRT(Indirect_lighting, viewPos, normal, vec3(bnoise, noise_2), 		feetPlayerPos, lpvPos, exposure, lightmap.xy, AmbientLightColor*2.5, vec3(TORCH_R,TORCH_G,TORCH_B), isGrass, hand);
		#endif

		#if defined END_SHADER
			Direct_lighting *= AO;
		#endif

	////////////////////////////////////////////////////////////////////////////////
	/////////////////////////	SUB SURFACE SCATTERING	////////////////////////////
	////////////////////////////////////////////////////////////////////////////////
	
	/////////////////////////////	SKY SSS		/////////////////////////////
		#if defined Ambient_SSS && defined OVERWORLD_SHADER && indirect_effect == 1
			if (!hand){
				vec3 ambientColor = (AmbientLightColor*2.5) * ambient_brightness; // x2.5 to match the brightness of upfacing skylight

				Indirect_SSS = SubsurfaceScattering_sky(albedo, SkySSS, LabSSS);
				Indirect_SSS *= lightmap.y*lightmap.y*lightmap.y;
				Indirect_SSS *= AO;

				// apply to ambient light.
				Indirect_lighting = max(Indirect_lighting, Indirect_SSS * ambientColor * ambientsss_brightness);

				// #ifdef OVERWORLD_SHADER
				// 	if(LabSSS > 0.0) Indirect_lighting += (1.0-SkySSS) * LightningPhase * lightningEffect *  pow(lightmap.y,10);
				// #endif
			}
		#endif
	
	////////////////////////////////	SUN SSS		////////////////////////////////
		#if SSS_TYPE != 0 && defined OVERWORLD_SHADER

			float sunSSS_density = LabSSS;
			float SSS_shadow = ShadowAlpha * Shadows;
			
			#ifdef DISTANT_HORIZONS_SHADOWMAP
				shadowMapFalloff2 = smoothstep(0.0, 1.0, min(max(1.0 - length(feetPlayerPos) / min(shadowDistance, far-32),0.0)*5.0,1.0));
			#endif

			#ifndef RENDER_ENTITY_SHADOWS
				if(entities) sunSSS_density = 0.0;
			#endif
			

			#ifdef SCREENSPACE_CONTACT_SHADOWS
				vec2 SS_directLight = SSRT_Shadows(toScreenSpace_DH(texcoord/RENDER_SCALE, z, DH_depth1), isDHrange, normalize(WsunVec*mat3(gbufferModelViewInverse)), interleaved_gradientNoise(), sunSSS_density > 0.0 && shadowMapFalloff2 < 1.0, hand);
				
				// combine shadowmap with a minumum shadow determined by the screenspace shadows.
				Shadows = min(Shadows, SS_directLight.r);
				
				// combine shadowmap blocker depth with a minumum determined by the screenspace shadows, starting after the shadowmap ends
				ShadowBlockerDepth = mix(SS_directLight.g, ShadowBlockerDepth, shadowMapFalloff2);
			#endif

			Direct_SSS = SubsurfaceScattering_sun(albedo, ShadowBlockerDepth, sunSSS_density, clamp(dot(feetPlayerPos_normalized, WsunVec),0.0,1.0), SSS_shadow);
			Direct_SSS *= mix(LM_shadowMapFallback, 1.0, shadowMapFalloff2);
			if (isEyeInWater == 0) Direct_SSS *= lightLeakFix;

			#ifndef SCREENSPACE_CONTACT_SHADOWS
				Direct_SSS = mix(vec3(0.0), Direct_SSS, shadowMapFalloff2);
			#endif

			#ifdef CLOUDS_SHADOWS
				cloudShadow = GetCloudShadow(feetPlayerPos);
				Shadows *= cloudShadow;
				Direct_SSS *= cloudShadow;
			#endif

		#endif

	/////////////////////////////////////////////////////////////////////////
	/////////////////////////////	FINALIZE	/////////////////////////////
	/////////////////////////////////////////////////////////////////////////


		#ifdef SSS_view
			albedo = vec3(1);
			NdotL = 0;
		#endif

		#ifdef OVERWORLD_SHADER
			Direct_lighting =  max(DirectLightColor * NdotL * Shadows, DirectLightColor * Direct_SSS);
		#endif

		gl_FragData[0].rgb = (Indirect_lighting + Direct_lighting) * albedo;

		#ifdef Specular_Reflections	
			vec2 specularNoises = vec2(noise, R2_dither());
			DoSpecularReflections(gl_FragData[0].rgb, viewPos, feetPlayerPos_normalized, WsunVec, specularNoises, normal, SpecularTex.r, SpecularTex.g, albedo, DirectLightColor*Shadows*NdotL, lightmap.y, hand);
		#endif
		
		Emission(gl_FragData[0].rgb, albedo, SpecularTex.a, exposure);
		
		if(lightningBolt) gl_FragData[0].rgb = vec3(77.0, 153.0, 255.0);

		gl_FragData[0].rgb *= Absorbtion;
	}
	

	if(translucentMasks > 0.0){
		#ifdef DISTANT_HORIZONS
    	  vec4 vlBehingTranslucents = BilateralUpscale_DH(colortex13, colortex12, gl_FragCoord.xy, sqrt(texture2D(colortex12,texcoord).a/65000.0));
    	#else
    	  vec4 vlBehingTranslucents = BilateralUpscale(colortex13, depthtex1, gl_FragCoord.xy, ld(z));
    	#endif

    	gl_FragData[0].rgb = gl_FragData[0].rgb * vlBehingTranslucents.a + vlBehingTranslucents.rgb;
	}

	// gl_FragData[0].rgb = vec3(1.0) * clamp(1.0 - filteredShadow.y/1,0,1);
	// if(hideGUI > 0) gl_FragData[0].rgb = vec3(1.0) * Shadows;
	////// DEBUG VIEW STUFF
	// #if DEBUG_VIEW == debug_SHADOWMAP
	// 	vec3 OutsideShadowMap_and_DH_shadow = (shadowMapFalloff > 0.0 && z >= 1.0) ? vec3(0.25,1.0,0.25) : vec3(1.0,0.25,0.25);
	// 	vec3 Normal_Shadowmap =  z < 1.0 ? vec3(1.0,1.0,1.0) : OutsideShadowMap_and_DH_shadow;
	// 	gl_FragData[0].rgb = mix(vec3(0.1) * (normal.y * 0.1 +0.9), Normal_Shadowmap,  shadowMap) * 30.0;
	// #endif
	#if DEBUG_VIEW == debug_NORMALS
		if(swappedDepth >= 1.0) Direct_lighting = vec3(1.0);
		gl_FragData[0].rgb = normalize(worldToView(normal));
	#endif
	#if DEBUG_VIEW == debug_SPECULAR
		if(swappedDepth >= 1.0) Direct_lighting = vec3(1.0);
		gl_FragData[0].rgb = SpecularTex.rgb;
	#endif
	#if DEBUG_VIEW == debug_INDIRECT
		if(swappedDepth >= 1.0) Direct_lighting = vec3(5.0);
		gl_FragData[0].rgb = Indirect_lighting;
	#endif
	#if DEBUG_VIEW == debug_DIRECT
		if(swappedDepth >= 1.0) Direct_lighting = vec3(15.0);
		gl_FragData[0].rgb = Direct_lighting + 0.5;
	#endif
	#if DEBUG_VIEW == debug_VIEW_POSITION
		gl_FragData[0].rgb = viewPos * 0.001;
	#endif
	#if DEBUG_VIEW == debug_FILTERED_STUFF
	 	if(hideGUI == 1)  gl_FragData[0].rgb = vec3(1)	* (1.0 - SSAO_SSS.y);
	 	if(hideGUI == 0)  gl_FragData[0].rgb = vec3(1)	* (1.0 - SSAO_SSS.x);
	 	// if(hideGUI == 0)  gl_FragData[0].rgb = vec3(1)	* filteredShadow.z;//exp(-7*(1-clamp(1.0 - filteredShadow.x,0.0,1.0)));
	#endif
	

	// float shadew = clamp(1.0 - filteredShadow.y/1,0.0,1.0);
	// // if(hideGUI == 1) 

	

	#ifdef CLOUDS_INFRONT_OF_WORLD
		gl_FragData[1] = texture2D(colortex2, texcoord);
		if(heightRelativeToClouds > 0.0 && !hand){
			gl_FragData[0].rgb = gl_FragData[0].rgb * Clouds.a + Clouds.rgb;
			gl_FragData[1].a = gl_FragData[1].a*Clouds.a*Clouds.a*Clouds.a;
		}

/* DRAWBUFFERS:32 */

	#else

/* DRAWBUFFERS:3 */

	#endif
}