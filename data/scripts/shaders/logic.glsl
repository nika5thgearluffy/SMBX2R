//Less than conditional
float lt(float x, float y) 
{
  return max(sign(y - x), 0.0);
}

//Greater or equal conditional
float ge(float x, float y) 
{
  return 1.0 - max(sign(y - x), 0.0);
}

//Greater than conditional
float gt(float x, float y)
{
	return max(sign(x - y), 0.0);
}

//Less or equal conditional
float le(float x, float y) 
{
  return 1.0 - max(sign(x - y), 0.0);
}

//Condition conjunction
float and(float a, float b)
{
	return a*b;
}

//Condition disjunction
float or(float a, float b)
{
	return min(a + b, 1.0);
}

//Condition negation
float nt(float a)
{
	return 1.0 - a;
}

//Equality
float eq(float a, float b)
{
	return (1.0 - max(sign(b - a), 0.0)) * (1.0 - max(sign(a - b), 0.0));
}

//Not equal
float neq(float a, float b)
{
	return 1.0 - ((1.0 - max(sign(b - a), 0.0)) * (1.0 - max(sign(a - b), 0.0)));
}

//Condition exclusive disjunction
float xor(float a, float b)
{
	return 1.0 - abs(a + b - 1.0);
}