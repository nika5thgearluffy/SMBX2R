#version 120
uniform sampler2D iChannel0;
uniform float time;
uniform float intensity;
uniform vec4 sectionBounds;
uniform vec4 cameraBounds;
uniform vec2 framebufferSize = vec2(800.0, 600.0);
uniform vec2 speed;
uniform sampler2D mask;
uniform sampler2D tex1;

void main()
{	
	vec2 uv = gl_TexCoord[0].xy;
	vec4 c = texture2D(iChannel0, uv);
	vec4 m = texture2D(mask, uv);
	
	float msk = clamp(m.r+m.g+m.b,0,1);
	float bg = 1-clamp(m.r+m.g,0,1);
	
	vec2 camcoord = mod((uv*framebufferSize + cameraBounds.xy)/vec2(800,600), vec2(1));
	vec2 uv2 = mod(camcoord + (time + bg*64)*vec2(0.0005, 0.0007) * speed.x, vec2(1));
	vec2 uv3 = mod(-camcoord + (time + bg*64)*vec2(-0.0004, 0.00025) * speed.y, vec2(1));
	
	float cs = pow(min(texture2D(tex1, uv2).r, texture2D(tex1, uv3).r), 0.8);
	gl_FragColor = c*gl_Color + intensity*(cs*msk*vec4(0.8, 0.95, 1, 1));
}