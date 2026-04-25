#version 120

uniform sampler2D iChannel0;
uniform vec2 center;
uniform float radius;

#include "shaders/logic.glsl"

void main()
{
	float dist = length(center - gl_FragCoord.xy);

	gl_FragColor = gl_Color*gt(dist,radius);
}