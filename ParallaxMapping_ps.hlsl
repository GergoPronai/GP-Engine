#include "Common.hlsli"


//--------------------------------------------------------------------------------------
// Textures (texture maps)
//--------------------------------------------------------------------------------------

Texture2D DiffuseSpecularMap : register(t0);
Texture2D NormalHeightMap    : register(t1); 
SamplerState TexSampler : register(s0); 


//--------------------------------------------------------------------------------------
// Shader code
//--------------------------------------------------------------------------------------


float4 main(NormalMappingPixelShaderInput input) : SV_Target
{
	//************************
	// Normal Map Extraction
	//************************


	float3 modelNormal = normalize(input.modelNormal);
	float3 modelTangent = normalize(input.modelTangent);


	float3 modelBiTangent = cross(modelNormal, modelTangent);
	float3x3 invTangentMatrix = float3x3(modelTangent, modelBiTangent, modelNormal);


	float3 cameraDirection = normalize(gCameraPosition - input.worldPosition);


	float3x3 invWorldMatrix = transpose((float3x3)gWorldMatrix);
	float3 cameraModelDir = normalize(mul(invWorldMatrix, cameraDirection));


	float3x3 tangentMatrix = transpose(invTangentMatrix);
	float2 textureOffsetDir = mul(cameraModelDir, tangentMatrix).xy;

	float textureHeight = gParallaxDepth * (NormalHeightMap.Sample(TexSampler, input.uv).a - 0.5f);


	float2 offsetTexCoord = input.uv + textureHeight * textureOffsetDir;

	float3 textureNormal = 2.0f * NormalHeightMap.Sample(TexSampler, offsetTexCoord).rgb - 1.0f; // Scale from 0->1 to -1->1


	float3 worldNormal = normalize(mul((float3x3)gWorldMatrix, mul(textureNormal, invTangentMatrix)));


	// Light 1
	float3 light1Vector = gLight1Position - input.worldPosition;
	float  light1Distance = length(light1Vector);
	float3 light1Direction = light1Vector / light1Distance; // Quicker than normalising as we have length for attenuation
	float3 diffuseLight1 = gLight1Colour * max(dot(worldNormal, light1Direction), 0) / light1Distance;

	float3 halfway = normalize(light1Direction + cameraDirection);
	float3 specularLight1 = diffuseLight1 * pow(max(dot(worldNormal, halfway), 0), gSpecularPower);


	// Light 2
	float3 light2Vector = gLight2Position - input.worldPosition;
	float  light2Distance = length(light2Vector);
	float3 light2Direction = light2Vector / light2Distance;
	float3 diffuseLight2 = gLight2Colour * max(dot(worldNormal, light2Direction), 0) / light2Distance;

	halfway = normalize(light2Direction + cameraDirection);
	float3 specularLight2 = diffuseLight2 * pow(max(dot(worldNormal, halfway), 0), gSpecularPower);


	float4 textureColour = DiffuseSpecularMap.Sample(TexSampler, offsetTexCoord); // Use offset texture coordinate from parallax mapping
	float3 diffuseMaterialColour = textureColour.rgb;
	float specularMaterialColour = textureColour.a;

	float3 finalColour = (gAmbientColour + diffuseLight1 + diffuseLight2) * diffuseMaterialColour +
						 (specularLight1 + specularLight2) * specularMaterialColour;

	return float4(finalColour, 1.0f); // Always use 1.0f for gAlpha - no gAlpha blending in this lab
}