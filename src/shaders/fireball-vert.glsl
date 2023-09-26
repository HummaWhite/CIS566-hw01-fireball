#version 300 es

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself

uniform mat4 u_ModelView;

uniform highp float u_Time;
uniform highp float u_Displacement;
uniform highp float u_FBMAmplitude;
uniform highp float u_FBMFrequency;
uniform highp float u_FBMAmplitudeMultiplier;
uniform highp float u_FBMFrequencyMultiplier;
uniform highp float u_Layer;
uniform highp float u_SineIntensity;
uniform highp float u_Blend1;
uniform highp float u_Blend2;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader
in vec4 vs_Nor;             // The array of vertex normals passed to the shader
in vec4 vs_Col;             // The array of vertex colors passed to the shader.
in vec2 vs_Uv;

out vec3 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec3 fs_Pos;
out vec3 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec3 fs_OrigPos;

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

float noise3Interpl(vec3 p) {
    vec3 pi = floor(p);
    vec3 pf = fract(p);

    return mix(
        mix(
            mix(noise3(pi + vec3(0, 0, 0)), noise3(pi + vec3(1, 0, 0)), pf.x),
            mix(noise3(pi + vec3(0, 1, 0)), noise3(pi + vec3(1, 1, 0)), pf.x),
            pf.y
        ),
        mix(
            mix(noise3(pi + vec3(0, 0, 1)), noise3(pi + vec3(1, 0, 1)), pf.x),
            mix(noise3(pi + vec3(0, 1, 1)), noise3(pi + vec3(1, 1, 1)), pf.x),
            pf.y
        ),
        pf.z
    );
}

float sawtooth(float x) {
    return fract(x);
}

float triangle(float x) {
    return abs(fract(x) - 0.5) + 0.5;
}

float FBM3(vec3 p) {
    const int Octaves = 5;

    float val = 0.0;
    float amp = u_FBMAmplitude;
    float freq = u_FBMFrequency * 0.25;

    for (int i = 0; i < Octaves; i++) {
        val += amp * noise3Interpl(p * freq);
        freq *= 2.0;
        amp *= u_FBMAmplitudeMultiplier;
    }
    return val;
}

float displacement(vec3 n, vec2 uv, float time) {
    float r = 1.0 - uv.y;
    float shape = r * r - 1.0;
    float circum = FBM3(vec3(triangle(uv.x + time * 0.2), 0, 0));
    float layer = sawtooth((r + circum + uv.x) * 10.0) * -u_Layer;
    float sin1 = mix(-0.5, 0.3, sin(time) * 0.5 + 0.5) * u_SineIntensity + FBM3(vec3(time)) * u_Displacement;
    float sin2 = mix(-0.5, 0.3, sin(time) * 0.5 + 0.5) * u_SineIntensity;
    float sin3 = mix(-0.5, 0.3, smoothstep(-0.5, 0.3, sin(time))) * u_SineIntensity;
    return FBM3(n + vec3(0.1, -1, 0) * time) * u_Displacement + shape + layer + mix(mix(sin1, sin2, u_Blend1), sin3, u_Blend2);
}

void main()
{
    fs_Col = vs_Col.xyz;                         // Pass the vertex colors to the fragment shader for interpolation
    
    vec2 uv = sphereToPlane(normalize(vs_Pos.xzy));

    //vec2 uv = sphereToPlane(normalize(vec3(vs_Uv * 2.0 - 1.0, 1.0)));
    vec3 pos = vs_Pos.xyz + vs_Nor.xyz * displacement(vs_Nor.xyz, uv, u_Time);

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = normalize(invTranspose * vec3(vs_Nor));          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.
    fs_OrigPos = pos.xyz;
    vec4 trPos = u_Model * vec4(pos, 1.0);   // Temporarily store the transformed vertex positions for use below
    fs_Pos = trPos.xyz;

    gl_Position = u_ViewProj * trPos;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
