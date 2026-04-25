#version 120
uniform vec4 cameraBounds;

uniform vec2 framebufferSize = vec2(800.0, 600.0);

void main()
{    
    gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;
	gl_TexCoord[0].xy *= (cameraBounds.zw - cameraBounds.xy)/framebufferSize;
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
	gl_FrontColor = gl_Color;
}