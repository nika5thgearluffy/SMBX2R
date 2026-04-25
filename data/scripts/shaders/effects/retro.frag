#version 120
uniform sampler2D iChannel0;
uniform sampler2D tex1;
uniform float time;

const vec2 iResolution = vec2(800, 600);

#define SEQUENCE_LENGTH 84.0
#define FPS 12.

vec4 vignette(vec2 uv, float t) 
{
    uv *=  1.0 - uv.yx;   
    float vig = uv.x*uv.y * 15.0;
    float t2 = sin(t * 12.) * cos(t * 41. + .5);
    vig = pow(vig, 0.8 + t2 * .045)+ 1.3;
    return vec4(vig, vig, vig, 1);
}

float easeIn(float t0, float t1, float t) 
{
	return 2.0*smoothstep(t0,2.*t1-t0,t);
}

vec4 blackAndWhite(vec4 color) 
{
	float d = dot(color.xyz, vec3(.299, .587, .114));
    return vec4(d,d,d,1);
}

float filmDirt(vec2 pp, float t) 
{
	float aaRad = 0.1;
	if (mod((t * t * t/2), 1) < 0.9) {
		return 1;
	}
	vec2 nseLookup2 = pp + vec2(.5,.9) + t*44.349734;
	nseLookup2.xy = nseLookup2.xy * 18.4;
	vec4 nse2 =
		texture2D(tex1,mod(0.1*nseLookup2.xy + t * 0.1, vec2(1))) +
		texture2D(tex1,mod(.01*nseLookup2.xy + t * 0.000045823, vec2(1))) +
		texture2D(tex1,mod(.004*nseLookup2.xy+0.4 + t * 0.025653, vec2(1)));
	float thresh = .6;
	float mul1 = smoothstep(thresh-aaRad,thresh+aaRad,nse2.x);
	float mul2 = smoothstep(thresh-aaRad,thresh+aaRad,nse2.y);
	float mul3 = smoothstep(thresh-aaRad,thresh+aaRad,nse2.z);
	
	float seed = texture2D(tex1,vec2(t*.35,t * t * .12328356204)).x;
	
	float result = clamp(0.,1.,seed+.7) + .3*smoothstep(0.,SEQUENCE_LENGTH,t);
	
	result += .06*easeIn(19.2,19.4,t);

	float band = .05;
	if( 0.3 < seed && .3+band > seed )
		return clamp(mul1 * nse2.r * result, 0, 1);
	if( 0.6 < seed && .6+band > seed )
		return clamp(mul2 * nse2.g * result, 0, 1);
	if( 0.9 < seed && .9+band > seed )
		return clamp(mul3 * nse2.b * result, 0, 1);
	return clamp(result * nse2.r, 0, 1);
}

vec4 jumpCut(float seqTime) 
{
	float toffset = 0.;
	vec3 camoffset = vec3(0.);
	
	float jct = seqTime;
	float jct1 = 7.7;
	float jct2 = 8.2;
	float jc1 = step( jct1, jct );
	float jc2 = step( jct2, jct );
	
	camoffset += vec3(.8,.0,.0) * jc1;
	camoffset += vec3(-.8,0.,.0) * jc2;
	
	toffset += 0.8 * jc1;
	toffset -= (jc2-jc1)*(jct-jct1);
	toffset -= 0.9 * jc2;
	
	return vec4(camoffset, toffset);
}

float limitFPS(float t, float fps) 
{
    t = mod(t, SEQUENCE_LENGTH);
    return float(int(t * fps)) / fps;
}

vec2 moveImage(vec2 uv, float t) 
{
    uv.x += .002 * (cos(t * 3.) * sin(t * 12. + .25));
    uv.y += .002 * (sin(t * 1. + .5) * cos(t * 15. + .25));
    return uv;
}

void main() 
{
	float t = mod(time, SEQUENCE_LENGTH);
    vec2 uv = gl_TexCoord[0].xy;
    vec2 qq = -1.0 + 2.0*uv;
    
	t = limitFPS(time, FPS);

	vec4 jumpCutData = jumpCut(t);
    vec4 dirt = vec4(filmDirt(qq, t + jumpCutData.w));     
    vec4 image = texture2D(iChannel0, uv);  
    vec4 vig = vignette(uv, t);
    
    gl_FragColor = image * dirt * vig;
    gl_FragColor = blackAndWhite(gl_FragColor);
}