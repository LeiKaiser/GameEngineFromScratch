#version 310 es
precision mediump float;
precision highp int;

struct basic_vert_output
{
    highp vec4 pos;
    highp vec4 normal;
    highp vec4 normal_world;
    highp vec4 v;
    highp vec4 v_world;
    highp vec2 uv;
};

struct Light
{
    highp float lightIntensity;
    uint lightType;
    int lightCastShadow;
    int lightShadowMapIndex;
    uint lightAngleAttenCurveType;
    uint lightDistAttenCurveType;
    highp vec2 lightSize;
    uvec4 lightGuid;
    highp vec4 lightPosition;
    highp vec4 lightColor;
    highp vec4 lightDirection;
    highp vec4 lightDistAttenCurveParams[2];
    highp vec4 lightAngleAttenCurveParams[2];
    highp mat4 lightVP;
    highp vec4 padding[2];
};

layout(binding = 10, std140) uniform PerFrameConstants
{
    highp mat4 viewMatrix;
    highp mat4 projectionMatrix;
    highp mat4 arbitraryMatrix;
    highp vec4 camPos;
    uint numLights;
} _280;

layout(binding = 12, std140) uniform LightInfo
{
    Light lights[100];
} _681;

uniform highp sampler2D SPIRV_Cross_CombineddiffuseMapsamp0;
uniform highp samplerCubeArray SPIRV_Cross_Combinedskyboxsamp0;

layout(location = 0) in highp vec4 input_normal;
layout(location = 1) in highp vec4 input_normal_world;
layout(location = 2) in highp vec4 input_v;
layout(location = 3) in highp vec4 input_v_world;
layout(location = 4) in highp vec2 input_uv;
layout(location = 0) out highp vec4 _entryPointOutput;

float _130;

highp vec3 projectOnPlane(highp vec3 _point, highp vec3 center_of_plane, highp vec3 normal_of_plane)
{
    return _point - (normal_of_plane * dot(_point - center_of_plane, normal_of_plane));
}

highp float linear_interpolate(highp float t, highp float begin, highp float end)
{
    if (t < begin)
    {
        return 1.0;
    }
    else
    {
        if (t > end)
        {
            return 0.0;
        }
        else
        {
            return (end - t) / (end - begin);
        }
    }
}

highp float apply_atten_curve(highp float dist, int atten_curve_type, highp vec4 atten_params[2])
{
    highp float atten = 1.0;
    switch (atten_curve_type)
    {
        case 1:
        {
            highp float begin_atten = atten_params[0].x;
            highp float end_atten = atten_params[0].y;
            highp float param = dist;
            highp float param_1 = begin_atten;
            highp float param_2 = end_atten;
            highp float param_3 = param;
            highp float param_4 = param_1;
            highp float param_5 = param_2;
            atten = linear_interpolate(param_3, param_4, param_5);
            break;
        }
        case 2:
        {
            highp float begin_atten_1 = atten_params[0].x;
            highp float end_atten_1 = atten_params[0].y;
            highp float param_3_1 = dist;
            highp float param_4_1 = begin_atten_1;
            highp float param_5_1 = end_atten_1;
            highp float param_6 = param_3_1;
            highp float param_7 = param_4_1;
            highp float param_8 = param_5_1;
            highp float tmp = linear_interpolate(param_6, param_7, param_8);
            atten = (3.0 * pow(tmp, 2.0)) - (2.0 * pow(tmp, 3.0));
            break;
        }
        case 3:
        {
            highp float scale = atten_params[0].x;
            highp float offset = atten_params[0].y;
            highp float kl = atten_params[0].z;
            highp float kc = atten_params[0].w;
            atten = clamp((scale / ((kl * dist) + (kc * scale))) + offset, 0.0, 1.0);
            break;
        }
        case 4:
        {
            highp float scale_1 = atten_params[0].x;
            highp float offset_1 = atten_params[0].y;
            highp float kq = atten_params[0].z;
            highp float kl_1 = atten_params[0].w;
            highp float kc_1 = atten_params[1].x;
            atten = clamp(pow(scale_1, 2.0) / ((((kq * pow(dist, 2.0)) + ((kl_1 * dist) * scale_1)) + (kc_1 * pow(scale_1, 2.0))) + offset_1), 0.0, 1.0);
            break;
        }
        case 0:
        {
            break;
        }
        default:
        {
            break;
        }
    }
    return atten;
}

bool isAbovePlane(highp vec3 _point, highp vec3 center_of_plane, highp vec3 normal_of_plane)
{
    return dot(_point - center_of_plane, normal_of_plane) > 0.0;
}

highp vec3 linePlaneIntersect(highp vec3 line_start, highp vec3 line_dir, highp vec3 center_of_plane, highp vec3 normal_of_plane)
{
    return line_start + (line_dir * (dot(center_of_plane - line_start, normal_of_plane) / dot(line_dir, normal_of_plane)));
}

highp vec3 apply_areaLight(Light light, basic_vert_output _input)
{
    highp vec3 N = normalize(_input.normal.xyz);
    highp vec3 right = normalize((_280.viewMatrix * vec4(1.0, 0.0, 0.0, 0.0)).xyz);
    highp vec3 pnormal = normalize((_280.viewMatrix * light.lightDirection).xyz);
    highp vec3 ppos = (_280.viewMatrix * light.lightPosition).xyz;
    highp vec3 up = normalize(cross(pnormal, right));
    right = normalize(cross(up, pnormal));
    highp float width = light.lightSize.x;
    highp float height = light.lightSize.y;
    highp vec3 param = _input.v.xyz;
    highp vec3 param_1 = ppos;
    highp vec3 param_2 = pnormal;
    highp vec3 projection = projectOnPlane(param, param_1, param_2);
    highp vec3 dir = projection - ppos;
    highp vec2 diagonal = vec2(dot(dir, right), dot(dir, up));
    highp vec2 nearest2D = vec2(clamp(diagonal.x, -width, width), clamp(diagonal.y, -height, height));
    highp vec3 nearestPointInside = (ppos + (right * nearest2D.x)) + (up * nearest2D.y);
    highp vec3 L = nearestPointInside - _input.v.xyz;
    highp float lightToSurfDist = length(L);
    L = normalize(L);
    highp float param_3 = lightToSurfDist;
    int param_4 = int(light.lightDistAttenCurveType);
    highp vec4 param_5[2] = light.lightDistAttenCurveParams;
    highp float atten = apply_atten_curve(param_3, param_4, param_5);
    highp vec3 linearColor = vec3(0.0);
    highp float pnDotL = dot(pnormal, -L);
    highp float nDotL = dot(N, L);
    highp vec3 param_6 = _input.v.xyz;
    highp vec3 param_7 = ppos;
    highp vec3 param_8 = pnormal;
    if ((nDotL > 0.0) && isAbovePlane(param_6, param_7, param_8))
    {
        highp vec3 V = normalize(-_input.v.xyz);
        highp vec3 R = normalize((N * (2.0 * dot(V, N))) - V);
        highp vec3 R2 = normalize((N * (2.0 * dot(L, N))) - L);
        highp vec3 param_9 = _input.v.xyz;
        highp vec3 param_10 = R;
        highp vec3 param_11 = ppos;
        highp vec3 param_12 = pnormal;
        highp vec3 E = linePlaneIntersect(param_9, param_10, param_11, param_12);
        highp float specAngle = clamp(dot(-R, pnormal), 0.0, 1.0);
        highp vec3 dirSpec = E - ppos;
        highp vec2 dirSpec2D = vec2(dot(dirSpec, right), dot(dirSpec, up));
        highp vec2 nearestSpec2D = vec2(clamp(dirSpec2D.x, -width, width), clamp(dirSpec2D.y, -height, height));
        highp float specFactor = 1.0 - clamp(length(nearestSpec2D - dirSpec2D), 0.0, 1.0);
        highp vec3 admit_light = light.lightColor.xyz * (light.lightIntensity * atten);
        linearColor = (texture(SPIRV_Cross_CombineddiffuseMapsamp0, _input.uv).xyz * nDotL) * pnDotL;
        linearColor += (((vec3(0.800000011920928955078125) * pow(clamp(dot(R2, V), 0.0, 1.0), 50.0)) * specFactor) * specAngle);
        linearColor *= admit_light;
    }
    return linearColor;
}

highp vec3 apply_light(Light light, basic_vert_output _input)
{
    highp vec3 N = normalize(_input.normal.xyz);
    highp vec3 light_dir = normalize((_280.viewMatrix * light.lightDirection).xyz);
    highp vec3 L;
    if (light.lightPosition.w == 0.0)
    {
        L = -light_dir;
    }
    else
    {
        L = (_280.viewMatrix * light.lightPosition).xyz - _input.v.xyz;
    }
    highp float lightToSurfDist = length(L);
    L = normalize(L);
    highp float cosTheta = clamp(dot(N, L), 0.0, 1.0);
    highp float visibility = 1.0;
    highp float lightToSurfAngle = acos(dot(L, -light_dir));
    highp float param = lightToSurfAngle;
    int param_1 = int(light.lightAngleAttenCurveType);
    highp vec4 param_2[2] = light.lightAngleAttenCurveParams;
    highp float atten = apply_atten_curve(param, param_1, param_2);
    highp float param_3 = lightToSurfDist;
    int param_4 = int(light.lightDistAttenCurveType);
    highp vec4 param_5[2] = light.lightDistAttenCurveParams;
    atten *= apply_atten_curve(param_3, param_4, param_5);
    highp vec3 R = normalize((N * (2.0 * dot(L, N))) - L);
    highp vec3 V = normalize(-_input.v.xyz);
    highp vec3 admit_light = light.lightColor.xyz * (light.lightIntensity * atten);
    highp vec3 linearColor = texture(SPIRV_Cross_CombineddiffuseMapsamp0, _input.uv).xyz * cosTheta;
    if (visibility > 0.20000000298023223876953125)
    {
        linearColor += vec3(0.800000011920928955078125 * pow(clamp(dot(R, V), 0.0, 1.0), 50.0));
    }
    linearColor *= admit_light;
    return linearColor * visibility;
}

highp vec3 exposure_tone_mapping(highp vec3 color)
{
    return vec3(1.0) - exp((-color) * 1.0);
}

highp vec4 _basic_frag_main(basic_vert_output _input)
{
    highp vec3 linearColor = vec3(0.0);
    for (uint i = 0u; i < _280.numLights; i++)
    {
        if (_681.lights[i].lightType == 3u)
        {
            Light arg;
            arg.lightIntensity = _681.lights[i].lightIntensity;
            arg.lightType = _681.lights[i].lightType;
            arg.lightCastShadow = _681.lights[i].lightCastShadow;
            arg.lightShadowMapIndex = _681.lights[i].lightShadowMapIndex;
            arg.lightAngleAttenCurveType = _681.lights[i].lightAngleAttenCurveType;
            arg.lightDistAttenCurveType = _681.lights[i].lightDistAttenCurveType;
            arg.lightSize = _681.lights[i].lightSize;
            arg.lightGuid = _681.lights[i].lightGuid;
            arg.lightPosition = _681.lights[i].lightPosition;
            arg.lightColor = _681.lights[i].lightColor;
            arg.lightDirection = _681.lights[i].lightDirection;
            arg.lightDistAttenCurveParams[0] = _681.lights[i].lightDistAttenCurveParams[0];
            arg.lightDistAttenCurveParams[1] = _681.lights[i].lightDistAttenCurveParams[1];
            arg.lightAngleAttenCurveParams[0] = _681.lights[i].lightAngleAttenCurveParams[0];
            arg.lightAngleAttenCurveParams[1] = _681.lights[i].lightAngleAttenCurveParams[1];
            arg.lightVP = _681.lights[i].lightVP;
            arg.padding[0] = _681.lights[i].padding[0];
            arg.padding[1] = _681.lights[i].padding[1];
            basic_vert_output param = _input;
            linearColor += apply_areaLight(arg, param);
        }
        else
        {
            Light arg_1;
            arg_1.lightIntensity = _681.lights[i].lightIntensity;
            arg_1.lightType = _681.lights[i].lightType;
            arg_1.lightCastShadow = _681.lights[i].lightCastShadow;
            arg_1.lightShadowMapIndex = _681.lights[i].lightShadowMapIndex;
            arg_1.lightAngleAttenCurveType = _681.lights[i].lightAngleAttenCurveType;
            arg_1.lightDistAttenCurveType = _681.lights[i].lightDistAttenCurveType;
            arg_1.lightSize = _681.lights[i].lightSize;
            arg_1.lightGuid = _681.lights[i].lightGuid;
            arg_1.lightPosition = _681.lights[i].lightPosition;
            arg_1.lightColor = _681.lights[i].lightColor;
            arg_1.lightDirection = _681.lights[i].lightDirection;
            arg_1.lightDistAttenCurveParams[0] = _681.lights[i].lightDistAttenCurveParams[0];
            arg_1.lightDistAttenCurveParams[1] = _681.lights[i].lightDistAttenCurveParams[1];
            arg_1.lightAngleAttenCurveParams[0] = _681.lights[i].lightAngleAttenCurveParams[0];
            arg_1.lightAngleAttenCurveParams[1] = _681.lights[i].lightAngleAttenCurveParams[1];
            arg_1.lightVP = _681.lights[i].lightVP;
            arg_1.padding[0] = _681.lights[i].padding[0];
            arg_1.padding[1] = _681.lights[i].padding[1];
            basic_vert_output param_1 = _input;
            linearColor += apply_light(arg_1, param_1);
        }
    }
    linearColor += (textureLod(SPIRV_Cross_Combinedskyboxsamp0, vec4(_input.normal_world.xyz, 0.0), 2.0).xyz * vec3(0.20000000298023223876953125));
    highp vec3 param_2 = linearColor;
    linearColor = exposure_tone_mapping(param_2);
    return vec4(linearColor, 1.0);
}

void main()
{
    basic_vert_output _input;
    _input.pos = gl_FragCoord;
    _input.normal = input_normal;
    _input.normal_world = input_normal_world;
    _input.v = input_v;
    _input.v_world = input_v_world;
    _input.uv = input_uv;
    basic_vert_output param = _input;
    _entryPointOutput = _basic_frag_main(param);
}

