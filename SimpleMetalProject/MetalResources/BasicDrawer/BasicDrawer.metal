//
//  BasicDrawer.metal
//  PhotoEditor
//
//  Created by Md. Rifat Haider Chowdhury on 24/8/22.
//

#include <metal_stdlib>

using namespace metal;

struct CalculatedVertex{
    float4 position [[position]];
    float2 texturecoord;
};

vertex CalculatedVertex basicDrawerVertex(const device packed_float2 *position [[buffer(0)]],
                                    const device packed_float2 *textureCoord [[buffer(1)]],
                                    uint vid [[vertex_id]]) {

    CalculatedVertex out;
    out.texturecoord = textureCoord[vid];
    out.position = float4(position[vid], 0, 1);
    return out;
}

fragment half4 basicDrawerFragment(CalculatedVertex fragmentInput [[stage_in]],
                                  texture2d<half> texture [[texture(0)]],
                                   texture2d<half> texture2 [[texture(1)]],
                                   const device float& opacity [[buffer(0)]]
                                   ){
                                
    constexpr sampler quadSampler;

    half4 textureColor = texture.sample(quadSampler, fragmentInput.texturecoord);
    half4 textureColor2 = texture2.sample(quadSampler, fragmentInput.texturecoord);

    return textureColor * opacity + textureColor2 * (1 - opacity);
}
