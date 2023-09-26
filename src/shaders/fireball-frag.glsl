#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform vec3 u_Color1;
uniform vec3 u_Color2;
uniform float u_Time;
uniform float u_FBMAmplitude;
uniform float u_FBMFrequency;
uniform float u_FBMAmplitudeMultiplier;
uniform float u_FBMFrequencyMultiplier;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec3 fs_Nor;
in vec3 fs_Pos;
in vec3 fs_Col;
in vec3 fs_OrigPos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

const float Pi = 3.1415926535897932;
const float PiInv = 1.0 / Pi;

vec2 sphereToPlane(vec3 uv) {
	float theta = atan(uv.y, uv.x);
	if (theta < 0.0) {
        theta += Pi * 2.0;
    }
	float phi = atan(length(uv.xy), uv.z);
	return vec2(theta * PiInv * 0.5, phi * PiInv);
}

vec2 toConcentricDisk(vec2 v) {
	if (v.x == 0.0 && v.y == 0.0) {
        return vec2(0.0, 0.0);
    }
	v = v * 2.0 - 1.0;
	float phi, r;

	if (v.x * v.x > v.y * v.y) {
		r = v.x;
		phi = Pi * v.y / v.x * 0.25;
	}
	else {
		r = v.y;
		phi = Pi * 0.5 - Pi * v.x / v.y * 0.25;
	}
	return vec2(r * cos(phi), r * sin(phi));
}

vec3 colorWheel(float x) {
	const float Div = 1.0 / 4.0;

	if (x < Div) {
		return vec3(0.0, x / Div, 1.0);
    }
	else if (x < Div * 2.0) {
		return vec3(0.0, 1.0, 2.0 - x / Div);
    }
	else if (x < Div * 3.0) {
		return vec3(x / Div - 2.0, 1.0, 0.0);
    }
	else {
		return vec3(1.0, 4.0 - x / Div, 0.0);
    }
}

uint hash(uint seed) {
    seed = (seed ^ uint(61)) ^ (seed >> uint(16));
    seed *= uint(9);
    seed = seed ^ (seed >> uint(4));
    seed *= uint(0x27d4eb2d);
    seed = seed ^ (seed >> uint(15));
    return seed;
}

float rand(uint seed) {
    seed = hash(seed);
    return float(seed) * (1.0 / 4294967296.0);
}

float noise1(float x) {
    uint seed = floatBitsToUint(x);
    uint seed1 = floatBitsToUint(rand(seed));
    return rand(seed1);
}

float noise2(vec2 p) {
    uint seed = floatBitsToUint(p.x) * floatBitsToUint(p.y);
    return rand(seed);
}

float noise3(vec3 p) {
    uint seed = floatBitsToUint(p.x);
    seed = floatBitsToUint(rand(seed)) ^ floatBitsToUint(p.y);
    seed = floatBitsToUint(rand(seed)) ^ floatBitsToUint(p.z);
    return rand(seed);
}

void main()
{
    vec2 uv = sphereToPlane(normalize(fs_OrigPos));

    //float noise = FBM3(fs_Pos + vec3(1, 1, 1) * float(u_Time));

    float r = length(fs_OrigPos);

    vec3 diffuseColor = mix(u_Color1, u_Color2, (r - 1.0));


    float ambientTerm = 0.2;

    float diffuseTerm = 1.0;

    float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

    // Compute final shaded color
    out_Col = vec4(diffuseColor * lightIntensity, 1.0);
    //out_Col = vec4(vec3(floor(u_FragmentTime)), 1.0);
}
