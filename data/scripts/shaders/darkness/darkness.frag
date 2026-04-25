#version 120

uniform sampler2D iChannel0;
uniform vec2 cameraPos;

#if _MAXLIGHTS > 0
//  PosX		ColR		ED1
//	PosY		ColG		ED2
//	Radius		ColB		ED3
//	MinRadius	Brightness	LightType
uniform mat3x4 [_MAXLIGHTS] lightData;
#endif

//Uses of ExtraData (ED):
//Spot Lights
	//ED1: Spot Power
	//ED2: Light Angle
	//ED3: Spot Angle
//Box Lights
	//ED1: Width
	//ED2: Height
//Line Lights
	//ED1: EndX (relative)
	//ED2: EndY (relative)


uniform sampler2D mask;
uniform vec4 ambient;

uniform vec4 bounds;
uniform float useBounds = 0;
uniform float boundBlend = 64;

#include FALLOFF
#include SHADOWS

void main()
{
	vec4 c = texture2D( iChannel0, gl_TexCoord[0].xy);
	vec3 light = vec3(0);
	vec3 addlight = vec3(0);
	vec2 pos = gl_FragCoord.xy + cameraPos;
	
	light.rgb = vec3(mix(0, clamp(smoothstep(bounds.x+boundBlend, bounds.x, pos.x) + smoothstep(bounds.z-boundBlend, bounds.z, pos.x) + smoothstep(bounds.y+boundBlend, bounds.y, pos.y) + smoothstep(bounds.w-boundBlend, bounds.w, pos.y),0,1), useBounds));
		
	#if _MAXLIGHTS > 0
		for (int i = 0; i < _MAXLIGHTS; i++)
		{
			float d;
			vec2 source;
			
			//Box Falloff
			if(lightData[i][2].w == 2.)
			{
				source = vec2(max(min(pos.x, lightData[i][0].x+lightData[i][2].x*0.5), lightData[i][0].x-lightData[i][2].x*0.5), max(min(pos.y, lightData[i][0].y+lightData[i][2].y*0.5), lightData[i][0].y-lightData[i][2].y*0.5));
			}
			//Line Falloff
			else if(lightData[i][2].w == 3.)
			{
				float t = ((pos.x-lightData[i][0].x)*lightData[i][2].x + (pos.y-lightData[i][0].y)*lightData[i][2].y)/(lightData[i][2].x*lightData[i][2].x + lightData[i][2].y*lightData[i][2].y);
				source = mix(mix(lightData[i][0].xy + lightData[i][2].xy*t, lightData[i][0].xy, max(sign(-t), 0.0)), lightData[i][0].xy+lightData[i][2].xy, max(sign(t-1.), 0.0));
			}
			//Point/Spot Falloff
			else
			{	
				source = lightData[i][0].xy;
			}
			
			d = distance(pos,source);
			
			//d += clamp(1.- d/lightData[i][0].w,0.,1.)*lightData[i][0].z;
			d /= lightData[i][0].w > 0 ? clamp(d/lightData[i][0].w-1., 0., 1.) : 1.;
			
			//Spot Falloff
			if (lightData[i][2].w == 1.)
			{	
				d = mix(d, lightData[i][0].z+0.05 /*add an offset to ensure we don't get artifacts*/, clamp(pow(1.0-max(((dot(vec2(cos(lightData[i][2].y), sin(lightData[i][2].y)), normalize(pos - lightData[i][0].xy))+1.0) * 0.5) - 1.0 + lightData[i][2].z, 0.0)/lightData[i][2].z, lightData[i][2].x) - pow(max(lightData[i][2].z-1.0, 0.0), lightData[i][2].x*2.0), 0.0, 1.0));
			}
					
			light.rgb += d < lightData[i][0].z ? shadow(falloff(lightData[i][1], d, lightData[i][0].z), source, pos) : vec3(0.);
			
		}
		
	#if ADDITIVE_BRIGHTNESS == 1
		addlight.rgb = max(light.rgb - 1.0, 0.0);
		vec3 bloomlight = max(addlight.rgb - 1.0, 0.0);
		bloomlight.rgb = vec3((bloomlight.r + bloomlight.g + bloomlight.b)/3.0);
		addlight.rgb = min(addlight, 1.0) + bloomlight;
		addlight.rgb *= mix(1.0, 1.0 - clamp(smoothstep(bounds.x+boundBlend, bounds.x, pos.x) + smoothstep(bounds.z-boundBlend, bounds.z, pos.x) + smoothstep(bounds.y+boundBlend, bounds.y, pos.y) + smoothstep(bounds.w-boundBlend, bounds.w, pos.y),0,1), useBounds);
	#endif
	
	#endif
		
	light.rgb = clamp(light.rgb,0,1);
	
	gl_FragColor = (c*clamp(vec4(light,1)+ambient,0,1) + vec4(addlight/2.5,0))*gl_Color;
}