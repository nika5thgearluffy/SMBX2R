#version 120
uniform sampler2D iChannel0;
uniform float time;
uniform vec4 cameraBounds;
uniform vec2 framebufferSize = vec2(800.0, 600.0);
uniform sampler2D perlin;

void main()
{	
	vec2 uv = gl_TexCoord[0].xy;
	vec4 c = texture2D(iChannel0, uv);
	
	vec2 camcoord = mod((uv*framebufferSize + cameraBounds.xy)/vec2(800,600), vec2(1));
	vec2 uv2 = mod(camcoord + sin(time * 0.53 + uv.x * 0.24113)*vec2(0.009, 0.07), vec2(1));
	uv2.y = 0;
	vec2 uv3 = mod(camcoord + sin(-time * 0.31 - uv.x * 0.1234)*vec2(0.007, -0.045) + vec2(0.3), vec2(1));
	uv3.y = 0;
	vec2 uv4 = mod(-camcoord + sin(-time * 0.42 + uv.x * 0.32934)*vec2(0.008, -0.045) + vec2(0.7), vec2(1));
	uv4.y = 0;
	
	float colA = texture2D(perlin, uv2).r * (0.7 + 0.2 * sin(time * 0.31));
	float colB = (texture2D(perlin, uv3).r + 0.1) * (0.5 + sin((time + 0.152) * 0.5) * (0.6));
	float colC = (texture2D(perlin, uv4).r + 0.1) * (0.4 - sin(time * 0.5) * 0.4);

	c.b += colA * max(0,0.45 + 0.05 * sin(time * 0.01) -uv.y);
	c.g += colB * max(0,0.4 - 0.05 * sin(time * 0.06923) -uv.y);
	c.r += colC * max(0,0.5 - 0.05 * sin(time * 0.07231) -uv.y);
	gl_FragColor = c*gl_Color;
}