#include "bridge.h"
#include <metal_stdlib>
using namespace metal;

// TODO: accept multiple meshes

struct VertexOutput {
    float4 position [[position]];
    half3 color;
};

vertex VertexOutput vertexMain(Vertex v [[stage_in]],
                               constant SceneUniforms &scene [[buffer(1)]],
                               constant InstanceUniforms *models [[buffer(2)]],
                               uint instanceID [[instance_id]]) {
    VertexOutput data;
    InstanceUniforms model = models[instanceID];
    float4 position = float4(v.position, 1.0);
    data.position = scene.projection * scene.view * model.translation * position;
    data.color = half3(model.color);
    return data;
};

fragment half4 fragmentMain(VertexOutput frag [[stage_in]]){
    return half4(frag.color, 1.0);
};
