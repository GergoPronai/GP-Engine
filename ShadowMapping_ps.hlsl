
//--------------------------------------------------------------------------------------
// Per-Pixel Lighting Pixel Shader
//--------------------------------------------------------------------------------------
// Pixel shader receives position and normal from the vertex shader and uses them to calculate
// lighting per pixel. Also samples a samples a diffuse + specular texture map and combines with light colour.

#include "Common.hlsli" // Shaders can also use include files - note the extension
#include "Light_ps.hlsl"


float4 main(LightingPixelShaderInput input) : SV_Target
{
	 
	return DiffuseSpecularMap1.Sample(TexSampler, input.uv);
	//return Light(input); // Returns the Shadows based on Light_ps.hlsl
}
