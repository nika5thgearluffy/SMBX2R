#version 120
uniform sampler2D iChannel0;
uniform float time;

vec4 vignette(vec2 uv, float t) 
{
    uv *=  1.0 - uv.yx;   
    float vig = uv.x*uv.y * 15.0;
    vig = pow(vig, -0.27 + sin(t * 0.35) * 0.1545)- 0.3;
    return vec4(vig, vig, vig, vig);
}

void main() 
{
    vec2 uv = gl_TexCoord[0].xy;
    vec4 image = texture2D(iChannel0, uv);  
    vec4 vig = vignette(uv, time);
    
    gl_FragColor = image * vig;
}