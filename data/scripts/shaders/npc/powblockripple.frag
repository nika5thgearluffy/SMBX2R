#version 120

#if _MAXRIPPLES > 0
uniform vec4 [_MAXRIPPLES] rippleData;
#endif

uniform sampler2D iChannel0;
uniform vec2 iResolution;
uniform vec2 iCameraPosition;

float EffectFadeInTimeFactor = 0.15;
float EffectMaxTexelOffset = 20.0;

void main()
{
    vec2 clampedOffsetCoords = gl_TexCoord[0].xy;

    #if _MAXRIPPLES > 0
		for (int i = 0; i < _MAXRIPPLES; i++)
		{
            vec2 center = (rippleData[i].xy - iCameraPosition.xy)/iResolution.xy;
            float radMod = max(1, rippleData[i].z);
            float time = rippleData[i].a / ((50.0*400.0)/radMod);
            vec2 radius = rippleData[i].zz / iResolution.xy;

            vec2 halfScreenSize = iResolution.xy / 2.0;

            vec2 offsetFromCenter = (gl_FragCoord.xy)/iResolution.xy - center;
            vec2 offsetDirection = normalize(-offsetFromCenter);
            float offsetDistance = length(offsetFromCenter);

            float radTime = max(0.1, rippleData[i].z/400.0);
            float progress = mod(time, radTime) / radTime;
            
            float halfWidth = radius.x / 8.0;
            float lower = 1.0 - smoothstep(progress - halfWidth, progress, offsetDistance);
            float upper = smoothstep(progress, progress + halfWidth, offsetDistance);
            
            float band = 1.0 - (upper + lower);
            
            
            float strength = 1.0 - progress;
            float fadeStrength = smoothstep(0.0, 0.15 , progress);
            
            float distortion = band * strength * fadeStrength;
            
            
            vec2 offset = distortion * offsetDirection * (20.0*400.0/(320.0 + (radMod*0.2)));
    
            vec2 coords = clampedOffsetCoords;

            vec2 texelSize = 1.0 / iResolution.xy;
            vec2 offsetCoords = coords + texelSize * offset;
            
            vec2 halfTexelSize = texelSize / 2.0;
            clampedOffsetCoords = clamp(offsetCoords, halfTexelSize, 1.0 - halfTexelSize);
		}

    #endif

    gl_FragColor = texture2D(iChannel0, clampedOffsetCoords.xy);
}
