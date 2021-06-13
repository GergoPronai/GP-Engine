
//--------------------------------------------------------------------------------------
// Per-Pixel Lighting Pixel Shader
//--------------------------------------------------------------------------------------
// Pixel shader receives position and normal from the vertex shader and uses them to calculate
// lighting per pixel. Also samples a samples a diffuse + specular texture map and combines with light colour.

#include "Common.hlsli" // Shaders can also use include files - note the extension

Texture2D DiffuseSpecularMap : register(t0); // Textures here can contain a diffuse map (main colour) in their rgb channels and a specular map (shininess) in the a channel
SamplerState Tril      : register(s0); // Trilinear

float4 main(BasicVertex input) : SV_Target
{
    // Sample diffuse material colour for this pixel from a texture using a given sampler that you set up in the C++ code
    // Ignoring any gAlpha in the texture, just reading RGB
    float3 diffuseMapColour = DiffuseSpecularMap.Sample(Tril, input.uv).rgb;

    // Blend texture colour with fixed per-object colour
    float3 finalColour = gObjectColour * diffuseMapColour;
	
	return float4(finalColour, 1.0); // Returns the Shadows based on Light_ps.hlsl
}