#include "Common.hlsli"

Texture2D DiffuseSpecularMap1 : register(t0); // Textures here can contain a diffuse map (main colour) in their rgb channels and a specular map (shininess) in the a channel
SamplerState TexSampler      : register(s0); // A sampler is a filter for a texture like bilinear, trilinear or anisotropic - this is the sampler used for the texture above

Texture2D ShadowMapLight1 : register(t1); // Texture holding the view of the scene from a light
SamplerState PointClamp   : register(s1); // No filtering for shadow maps (you might think you could use trilinear or similar, but it will filter light depths not the shadows cast...)

float4 main(LightingPixelShaderInput input) : SV_TARGET
{

///////////////////////
// Calculate lighting

// Direction from pixel to camera
float3 p = input.worldPosition;
float3 q = gLight1Position;

float3 distance = (q - p) / normalize(q - p);
float strength1 = (gSpecularPower / 100 ) / length(distance);

q = gLight2Position;

distance = (q - p) / normalize(q - p);
float strength2 = (gSpecularPower / 100) / length(distance);

q = gLight3Position;

distance = (q - p) / normalize(q - p);
float strength3 = (gSpecularPower / 100) / length(distance);
	
   // Sample diffuse material and specular material colour for this pixel from a texture using a given sampler that you set up in the C++ code
   float4 textureColour = DiffuseSpecularMap1.Sample(TexSampler, input.uv);
   float3 diffuseMaterialColour = textureColour.rgb; // Diffuse material colour in texture RGB (base colour of model)
   float specularMaterialColour = textureColour.a;   // Specular material colour in texture A (shininess of the surface)
   
   // Combine lighting with texture colours
   //float3 finalColour = diffuseLight * diffuseMaterialColour + specularLight * specularMaterialColour;

   float3 light1Colour = strength1 * gLight1Colour;
   float3 light2Colour = strength2 * gLight2Colour;
   float3 light3Colour = strength3 * gLight3Colour;
   float3 finalColour = diffuseMaterialColour * (light1Colour + light2Colour + light3Colour) * gAmbientColour;
	
   return float4(finalColour, specularMaterialColour); // Always use 1.0f for output gAlpha - no gAlpha blending in this lab
}
