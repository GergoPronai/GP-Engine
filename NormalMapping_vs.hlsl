//--------------------------------------------------------------------------------------
// Basic Transformation and Lighting Vertex Shader
//--------------------------------------------------------------------------------------

#include "Common.hlsli" // Shaders can also use include files - note the extension


//--------------------------------------------------------------------------------------
// Shader code
//--------------------------------------------------------------------------------------


NormalMappingPixelShaderInput main(TangentVertex modelVertex)
{
    NormalMappingPixelShaderInput output; // This is the data the pixel shader requires from this vertex shader
    
    float4 modelPosition = float4(modelVertex.position, 1);
    
    float4 worldPosition = mul(gWorldMatrix, modelPosition);
    float4 viewPosition = mul(gViewMatrix, worldPosition);
    output.projectedPosition = mul(gProjectionMatrix, viewPosition);

    output.worldPosition = worldPosition.xyz; // Also pass world position to pixel shader for lighting

    // Unlike the position, send the model's normal and tangent untransformed (in model space). The pixel shader will do the matrix work on normals
    output.modelNormal = modelVertex.normal;
    output.modelTangent = modelVertex.tangent;

    // Pass texture coordinates (UVs) on to the pixel shader, the vertex shader doesn't need them
    output.uv = modelVertex.uv;

    return output; // Ouput data sent down the pipeline (to the pixel shader)
}
