uniform float shadowSoftness = 0.95;
uniform float shadowResolution = 0.5;

uniform vec2 screenSize;

vec3 shadow(vec3 col, vec2 lightpos, vec2 pixpos)
{
	vec2 stp = -(lightpos-pixpos);
	float stepnum = floor(length(stp)*shadowResolution);
	stepnum = max(1.0,stepnum);
	
	//stp can be the zero vector, so impose a minimum length to avoid division by 0
	stp /= shadowResolution * max(length(stp),0.0000001);
	
	vec2 newpos = pixpos;
	vec3 adder = col/stepnum;
	vec3 agg = vec3(0);
	float mult = 1.0;
	for (int i = 0; i < stepnum; i++)
    {
		newpos -= stp;
		float m = 1.0 - texture2D(mask, clamp((newpos-cameraPos)/screenSize,0.001,0.999)).r;
		
		agg += adder*m;
		mult *= mix(shadowSoftness, 1.0, m);
	}
	agg *= mult;
	
	return agg;
}