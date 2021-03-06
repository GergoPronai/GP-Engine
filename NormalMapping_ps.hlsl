//--------------------------------------------------------------------------------------
// Texture Pixel Shader
//--------------------------------------------------------------------------------------
// Pixel shader simply samples a diffuse texture map and tints with colours from vertex shadeer

#include "Common.hlsli" // Shaders can also use include files - note the extension


//--------------------------------------------------------------------------------------
// Textures (texture maps)
//--------------------------------------------------------------------------------------

// Here we allow the shader access to a texture that has been loaded from the C++ side and stored in GPU memory.
// Note that textures are often called maps (because texture mapping describes wrapping a texture round a mesh).
// Get used to people using the word "texture" and "map" interchangably.
Texture2D DiffuseSpecularMap : register(t0); // Diffuse map (main colour) in rgb and specular map (shininess level) in gAlpha - C++ must load this into slot 0
Texture2D NormalMap          : register(t1); // Normal map in rgb - C++ must load this into slot 1

Texture2D DiffuseSpecularMap2 : register(t2);
Texture2D NormalMap2		  : register(t3);

SamplerState TexSampler : register(s0); // A sampler is a filter for a texture like bilinear, trilinear or anisotropic


//--------------------------------------------------------------------------------------
// Shader code
//--------------------------------------------------------------------------------------

float4 main(NormalMappingPixelShaderInput input) : SV_Target
{
	//************************
	// Normal Map Extraction
	//************************

	// Will use the model normal/tangent to calculate matrix for tangent space. The normals for each pixel are *interpolated* from the
	// vertex normals/tangents. This means they will not be length 1, so they need to be renormalised (same as per-pixel lighting issue)
	float3 modelNormal = normalize(input.modelNormal);
	float3 modelTangent = normalize(input.modelTangent);

	// Calculate bi-tangent to complete the three axes of tangent space - then create the *inverse* tangent matrix to convert *from*
	// tangent space into model space. This is just a matrix built from the three axes (very advanced note - by default shader matrices
	// are stored as columns rather than in rows as in the C++. This means that this matrix is created "transposed" from what we would
	// expect. However, for a 3x3 rotation matrix the transpose is equal to the inverse, which is just what we require)
	float3 modelBiTangent = cross(modelNormal, modelTangent);
	float3x3 invTangentMatrix = float3x3(modelTangent, modelBiTangent, modelNormal);

	// Get the texture normal from the normal map. The r,g,b pixel values actually store x,y,z components of a normal. However, r,g,b
	// values are stored in the range 0->1, whereas the x, y & z components should be in the range -1->1. So some scaling is needed
	float3 textureNormal = 2.0f * NormalMap.Sample(TexSampler, input.uv).rgb - 1.0f; // Scale from 0->1 to -1->1
	float3 textureNormal2 = 2.0f * NormalMap2.Sample(TexSampler, input.uv).rgb - 1.0f; // Scale from 0->1 to -1->1

	
	// Now convert the texture normal into model space using the inverse tangent matrix, and then convert into world space using the world
	// matrix. Normalise, because of the effects of texture filtering and in case the world matrix contains scaling
	float3 worldNormal = normalize(mul((float3x3)gWorldMatrix, mul(textureNormal, invTangentMatrix)));
	float3 worldNormal2 = normalize(mul((float3x3)gWorldMatrix, mul(textureNormal2, invTangentMatrix)));


	///////////////////////
	// Calculate lighting

   // Lighting equations
	float3 cameraDirection = normalize(gCameraPosition - input.worldPosition);

	// Light 1
	float3 light1Vector = gLight1Position - input.worldPosition;
	float  light1Distance = length(light1Vector);
	float3 light1Direction = light1Vector / light1Distance; // Quicker than normalising as we have length for attenuation
	float3 diffuseLight1 = gLight1Colour * max(dot(worldNormal, light1Direction), 0) / light1Distance;

	float3 diffuseLight1_2 = gLight1Colour * max(dot(worldNormal2, light1Direction), 0) / light1Distance;

	float3 halfway = normalize(light1Direction + cameraDirection);
	float3 specularLight1 = diffuseLight1 * pow(max(dot(worldNormal, halfway), 0), gSpecularPower);
	
	float3 specularLight1_2 = diffuseLight1 * pow(max(dot(worldNormal2, halfway), 0), gSpecularPower);


	// Light 2
	float3 light2Vector = gLight2Position - input.worldPosition;
	float  light2Distance = length(light2Vector);
	float3 light2Direction = light2Vector / light2Distance;
	float3 diffuseLight2 = gLight2Colour * max(dot(worldNormal, light2Direction), 0) / light2Distance;
	
	float3 diffuseLight2_2 = gLight2Colour * max(dot(worldNormal2, light2Direction), 0) / light2Distance;

	halfway = normalize(light2Direction + cameraDirection);
	float3 specularLight2 = diffuseLight2 * pow(max(dot(worldNormal, halfway), 0), gSpecularPower);

	float3 specularLight2_2 = diffuseLight2 * pow(max(dot(worldNormal2, halfway), 0), gSpecularPower);


	// Sample diffuse material colour for this pixel from a texture using a given sampler that you set up in the C++ code
	// Ignoring any gAlpha in the texture, just reading RGB
	float4 textureColour = DiffuseSpecularMap.Sample(TexSampler, input.uv);
	float4 textureColour2 = DiffuseSpecularMap2.Sample(TexSampler, input.uv);

	textureColour.a = gAlpha;
	if(textureColour2.a > textureColour.a)
	{
		textureColour = textureColour2;
		diffuseLight1 = diffuseLight1_2;
		diffuseLight2 = diffuseLight2_2;

		specularLight1 = specularLight1_2;
		specularLight2 = specularLight2_2;
	}
	
	float3 diffuseMaterialColour = textureColour.rgb;
	float specularMaterialColour = textureColour.a;

	float3 finalColour = (gAmbientColour + diffuseLight1 + diffuseLight2) * diffuseMaterialColour +
						 (specularLight1 + specularLight2) * specularMaterialColour;

	return float4(finalColour, 1.0f); // Always use 1.0f for gAlpha - no gAlpha blending in this lab
}