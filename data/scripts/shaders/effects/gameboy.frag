#version 120
uniform sampler2D iChannel0;

uniform vec4 col1;
uniform vec4 col2;
uniform vec4 col3;
uniform vec4 col4;

uniform vec2 framebufferSize = vec2(800.0, 600.0);

#include "shaders/logic.glsl"

void main()
{
	//Downsample
	vec2 scale = framebufferSize*0.5;

	vec2 uv = floor(gl_TexCoord[0].xy * scale + 0.5);
	vec2 iscale = 1/scale;
	uv *= iscale;
	vec2 d = iscale*0.5;
	vec3 m = vec3(1,-1,0);
	vec4 c = texture2D(iChannel0, uv)*3;
	c += texture2D(iChannel0, uv+d*m.zx);
	c += texture2D(iChannel0, uv+d*m.xx);
	c += texture2D(iChannel0, uv+d*m.xy);
	c += texture2D(iChannel0, uv+d*m.yx);
	c += texture2D(iChannel0, uv+d*m.yy);
	
	c += texture2D(iChannel0, uv+d*m.xz);
	c += texture2D(iChannel0, uv+d*m.zz);
	c += texture2D(iChannel0, uv+d*m.zy);
	c += texture2D(iChannel0, uv+d*m.yz);
	
	c /= 12;
	
	//Quantize
	vec4 col1col2 = mix(col1,col2,gt(distance(c,col1), distance(c,col2)));
	vec4 col1col3 = mix(col1,col3,gt(distance(c,col1), distance(c,col3)));
	vec4 col1col4 = mix(col1,col4,gt(distance(c,col1), distance(c,col4)));
	
	vec4 col1col2col3 = mix(col1col2,col1col3,gt(distance(c,col1col2), distance(c,col1col3)));
	
	c = mix(col1col2col3,col1col4,gt(distance(c,col1col2col3), distance(c,col1col4)));
	
	gl_FragColor = c*gl_Color;
}