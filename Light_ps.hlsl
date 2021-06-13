#ifndef LIGHT_PS_LHLS
#define LIGHT_PS_LHLS

#include "Common.hlsli"

Texture2D DiffuseSpecularMap1 : register(t0); // Textures here can contain a diffuse map (main colour) in their rgb channels and a specular map (shininess) in the a channel
SamplerState TexSampler      : register(s0); // A sampler is a filter for a texture like bilinear, trilinear or anisotropic - this is the sampler used for the texture above

Texture2D ShadowMapLight1 : register(t1); // Texture holding the view of the scene from a light
SamplerState PointClamp   : register(s1); // No filtering for shadow maps (you might think you could use trilinear or similar, but it will filter light depths not the shadows cast...)


// This main function should never get executed
float4 main() : SV_TARGET
{
	return float4(1.0f, 1.0f, 1.0f, 1.0f);
}

float4 Light(LightingPixelShaderInput input) // Calculates Shadow Mapping
{
	// Slight adjustment to calculated depth of pixels so they don't shadow themselves
	const float DepthAdjust = 0.0005f;

	// Normal might have been scaled by model scaling or interpolation so renormalise
	input.worldNormal = normalize(input.worldNormal);

	///////////////////////
	// Calculate lighting

	// Direction from pixel to camera
	float3 cameraDirection = normalize(gCameraPosition - input.worldPosition);

	//----------
	// LIGHT 1

	float3 diffuseLight1 = 0; // Initialy assume no contribution from this light
	float3 specularLight1 = 0;

	// Direction from pixel to light
	float3 light1Direction = normalize(gLight1Position - input.worldPosition);

	// Check if pixel is within light cone
	if (1) 
		   //           As well as the variables above, you also will need values from the constant buffers in "common.hlsli"
	{
		// Using the world position of the current pixel and the matrices of the light (as a camera), find the 2D position of the
		// pixel *as seen from the light*. Will use this to find which part of the shadow map to look at.
		// These are the same as the view / projection matrix multiplies in a vertex shader (can improve performance by putting these lines in vertex shader)
		float4 light1ViewPosition = mul(gLight1ViewMatrix, float4(input.worldPosition, 1.0f));
		float4 light1Projection = mul(gLight1ProjectionMatrix, light1ViewPosition);

		// Convert 2D pixel position as viewed from light into texture coordinates for shadow map - an advanced topic related to the projection step
		// Detail: 2D position x & y get perspective divide, then converted from range -1->1 to UV range 0->1. Also flip V axis
		float2 shadowMapUV = 0.5f * light1Projection.xy / light1Projection.w + float2(0.5f, 0.5f);
		shadowMapUV.y = 1.0f - shadowMapUV.y;	// Check if pixel is within light cone

		// Get depth of this pixel if it were visible from the light (another advanced projection step)
		float depthFromLight = light1Projection.z / light1Projection.w;// - DepthAdjust; //*** Adjustment so polygons don't shadow themselves

		// Compare pixel depth from light with depth held in shadow map of the light. If shadow map depth is less than something is nearer
		// to the light than this pixel - so the pixel gets no effect from this light
		if (depthFromLight < ShadowMapLight1.Sample(PointClamp, shadowMapUV).r)
		{
			float3 light1Dist = length(gLight1Position - input.worldPosition);
			diffuseLight1 = gLight1Colour * max(dot(input.worldNormal, light1Direction), 0) / light1Dist; // Equations from lighting lecture
			float3 halfway = normalize(light1Direction + cameraDirection);
			specularLight1 = diffuseLight1 * pow(max(dot(input.worldNormal, halfway), 0), gSpecularPower); // Multiplying by diffuseLight instead of light colour - my own personal preference
		}
	}

	// Sum the effect of the lights - add the ambient at this stage rather than for each light (or we will get too much ambient)
	float3 diffuseLight = gAmbientColour + diffuseLight1;
	float3 specularLight = specularLight1;


	////////////////////
	// Combine lighting and textures


	// Sample diffuse material and specular material colour for this pixel from a texture using a given sampler that you set up in the C++ code
	float4 textureColour = DiffuseSpecularMap1.Sample(TexSampler, input.uv);
	float3 diffuseMaterialColour = textureColour.rgb; // Diffuse material colour in texture RGB (base colour of model)
	float specularMaterialColour = textureColour.a;   // Specular material colour in texture A (shininess of the surface)

	// Combine lighting with texture colours
	float3 finalColour = diffuseLight * diffuseMaterialColour + specularLight * specularMaterialColour;

	return float4(finalColour, 1.0f); // Always use 1.0f for output gAlpha - no gAlpha blending in this lab
}

#endif
