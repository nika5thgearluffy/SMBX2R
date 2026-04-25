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
	
	for (int i = 0; i < stepnum; i++)
    {
		newpos -= stp;
		
		float m = texture2D(mask, clamp((newpos-cameraPos)/screenSize,0.001,0.999)).r;
		
		if(m > 0.5)
		{
			return vec3(0);
		}
		
		stp = -(lightpos-newpos);
		//stp can be the zero vector, so impose a minimum length to avoid division by 0
		stp /= shadowResolution * max(length(stp),0.0000001);
	}
	return col;
}