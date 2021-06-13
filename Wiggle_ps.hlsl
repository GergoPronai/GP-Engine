#include "Common.hlsli"
#include "Light_ps.hlsl"
//--------------------------------------------------------------------------------------
/// Wiggle effect with shadows according to the rotating light
/// The side of the object gets lit up that faces the light
/// while the other side stays dark
//--------------------------------------------------------------------------------------


float4 main(LightingPixelShaderInput input) : SV_Target
{
	//----------------------------------------------------------------------------------
	// Wiggle effect
	//----------------------------------------------------------------------------------
	float sinY = sin(input.uv.y * radians(360.0f) + wiggle);
	float sinX = sin(input.uv.x * radians(360.0f) + wiggle);
	input.uv.x += 0.1f * sinY;
	input.uv.y += 0.1f * sinX;
	
	return Light(input); // Returns the Shadows based on Light_ps.hlsl
}