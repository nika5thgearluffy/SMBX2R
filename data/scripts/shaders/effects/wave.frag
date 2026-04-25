#version 120
uniform sampler2D iChannel0;
uniform float time;
uniform float intensity;
uniform float type;

void main()
{	
	vec2 uv = mix(
		vec2(clamp(gl_TexCoord[0].x + 0.0025 * intensity * sin(gl_TexCoord[0].y*8 + time * 0.1),0,0.999), gl_TexCoord[0].y),
		vec2(
			gl_TexCoord[0].x, 
			gl_TexCoord[0].y + 0.0025 * intensity * sin(gl_TexCoord[0].y * 48 + time * 0.125) * 1.5 + cos(gl_TexCoord[0].x + time * 0.062) * 0.0025
		), type);


	vec4 c = texture2D( iChannel0, uv);
	
	gl_FragColor = c*gl_Color;
}