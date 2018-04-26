// Cg #define info: https://gist.github.com/hecomi/9580605

Shader "Hidden/Camera-DepthTexture" {
    Properties{
        _MainTex("", 2D) = "white" {}
        _Cutoff("", Float) = 0.5
        _Color("", Color) = (1,1,1,1)
        _MaxDepth("", Range(0.001, 1)) = 0.1

    }
    CGINCLUDE
        ///reusable stuff here
//#define RETURN_DEPTH(a,depthMod) fixed outZ = clamp((Linear01Depth(1-a)-1) * (1/depthMod) + 1, 0, 1); return fixed4(outZ, outZ, outZ, 1.0f);
//#define RETURN_DEPTH(a,depthMod) fixed outZ = a; return fixed4(outZ, outZ, outZ, 1.0f);
//#define RETURN_DEPTH(a,depthMod) fixed outZ = 1 - max((depthMod - a) * (1/depthMod), 0); return fixed4(outZ, outZ, outZ, 1.0f);

// fooplot function
// http://fooplot.com/?lang=es#W3sidHlwZSI6MCwiZXEiOiJtaW4obWF4KCh4LTEpKigxLzAuMykrMSwwKSwxKSIsImNvbG9yIjoiIzAwMDAwMCJ9LHsidHlwZSI6MTAwMCwid2luZG93IjpbIi0wLjU5MjQ2Njk0NTM0MDUwNzUiLCIxLjU4ODU3MTEzNDY1OTQ4NzMiLCItMC4wOTM4MjIxOTI1OTI3MzY3OCIsIjEuMjQ4MzU1MDg3NDA3MjYiXSwic2l6ZSI6WzExMDAsNjUwXX1d
#define RETURN_DEPTH(a,depthMod) fixed outZ = clamp((a - 1) * (1/depthMod) + 1, 0, 1); return fixed4(outZ, 0, 0, 1.0f); //return EncodeFloatRGBA(outZ); 

// formula got from this url to interpolate between near and far:
// https://github.com/robertcupisz/LightShafts/blob/master/Depth.shader
// Linear01Depth make depth linear "from 0 to far" instead of "from near to far"
#define VERTEX_DEPTH(depth) float d; COMPUTE_EYEDEPTH(d); depth = 1 - ((d - _ProjectionParams.y) / (_ProjectionParams.z - _ProjectionParams.y));

    ENDCG
    Category {
        Fog{ Mode Off }

        SubShader{
            Tags{ "RenderType" = "Opaque" }
            Pass{
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"
                struct v2f {
                    float4 pos : POSITION;
                    float depth : TEXCOORD0;
                };
                v2f vert(appdata_base v) {
                    v2f o;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    VERTEX_DEPTH(o.depth);
                    return o;
                }
                uniform fixed _MaxDepth;
                fixed4 frag(v2f i) : COLOR { 
                    //UNITY_OUTPUT_DEPTH(i.depth);
                    //return fixed4(i.pos.z / _MaxDepth, i.pos.z / _MaxDepth, i.pos.z / _MaxDepth, 1);
                    RETURN_DEPTH(i.depth, _MaxDepth);
                }
                ENDCG
            }
        }

        SubShader{
            Tags{ "RenderType" = "TransparentButHasDepth" }
            Pass{
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"
                struct v2f {
                    float4 pos : POSITION;
                    float depth : TEXCOORD0;
                };
                v2f vert(appdata_base v) {
                    v2f o;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    VERTEX_DEPTH(o.depth);
                    return o;
                }
                uniform fixed _MaxDepth;
                fixed4 frag(v2f i) : COLOR{
                    //UNITY_OUTPUT_DEPTH(i.depth);
                    //return fixed4(i.pos.z / _MaxDepth, i.pos.z / _MaxDepth, i.pos.z / _MaxDepth, 1);
                    RETURN_DEPTH(i.depth, _MaxDepth);
                }
                ENDCG
            }
        }

        SubShader{
            Tags{ "RenderType" = "TransparentCutout" }
            Pass{
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"
                struct v2f {
                    float4 pos : POSITION;
                    float2 uv : TEXCOORD0;
                    float depth : TEXCOORD1;
                };
                uniform float4 _MainTex_ST;
                v2f vert(appdata_base v) {
                    v2f o;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                    VERTEX_DEPTH(o.depth);
                    return o;
                }
                uniform sampler2D _MainTex;
                uniform fixed _Cutoff;
                uniform fixed4 _Color;
                uniform fixed _MaxDepth;
                fixed4 frag(v2f i) : COLOR{
                    fixed4 texcol = tex2D(_MainTex, i.uv);
                    clip(texcol.a*_Color.a - _Cutoff);
                    //UNITY_OUTPUT_DEPTH(i.depth);
                    //return fixed4(i.pos.z / _MaxDepth, i.pos.z / _MaxDepth, i.pos.z / _MaxDepth, 1);
                    RETURN_DEPTH(i.depth, _MaxDepth);
                }
                ENDCG
            }
        }

        SubShader {
            Tags { "RenderType" = "TransparentCutoutTwoSided" }
            Pass {
                Cull Off
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"
                struct v2f {
                    float4 pos : POSITION;
                    float2 uv : TEXCOORD0;
                    float depth : TEXCOORD1;
                };
                uniform float4 _MainTex_ST;
                v2f vert(appdata_base v) {
                    v2f o;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                    VERTEX_DEPTH(o.depth);
                    return o;
                }
                uniform sampler2D _MainTex;
                uniform fixed _Cutoff;
                uniform fixed4 _Color;
                uniform fixed _MaxDepth;
                fixed4 frag(v2f i) : COLOR {
                    fixed4 texcol = tex2D(_MainTex, i.uv);
                    clip(texcol.a*_Color.a - _Cutoff);
                    //UNITY_OUTPUT_DEPTH(i.depth);
                    //return fixed4(i.pos.z / _MaxDepth, i.pos.z / _MaxDepth, i.pos.z / _MaxDepth, 1);
                    RETURN_DEPTH(i.depth, _MaxDepth);
                }
                ENDCG
            }
        }


        SubShader {
            Tags { "RenderType" = "TreeOpaque" }
            Pass {
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"
                #include "TerrainEngine.cginc"
                struct v2f {
                    float4 pos : POSITION;
                    float depth : TEXCOORD0;
                };
                struct appdata {
                    float4 vertex : POSITION;
                    fixed4 color : COLOR;
                };
                v2f vert(appdata v) {
                    v2f o;
                    TerrainAnimateTree(v.vertex, v.color.w);
                    o.pos = UnityObjectToClipPos(v.vertex);
                    VERTEX_DEPTH(o.depth);
                    return o;
                }
                uniform fixed _MaxDepth;
                fixed4 frag(v2f i) : COLOR {
                    //UNITY_OUTPUT_DEPTH(i.depth);
                    //return fixed4(i.pos.z / _MaxDepth, i.pos.z / _MaxDepth, i.pos.z / _MaxDepth, 1);
                    RETURN_DEPTH(i.depth, _MaxDepth);
                }
                ENDCG
            }
        }

        SubShader {
            Tags { "RenderType" = "TreeTransparentCutout" }
            Pass {
                Cull Off
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"
                #include "TerrainEngine.cginc"

                struct v2f {
                    float4 pos : POSITION;
                    float2 uv : TEXCOORD0;
                    float depth : TEXCOORD1;
                };
                struct appdata {
                    float4 vertex : POSITION;
                    fixed4 color : COLOR;
                    float4 texcoord : TEXCOORD0;
                };
                v2f vert(appdata v) {
                    v2f o;
                    TerrainAnimateTree(v.vertex, v.color.w);
                    o.pos = UnityObjectToClipPos(v.vertex);
                    o.uv = v.texcoord.xy;
                    VERTEX_DEPTH(o.depth);
                    return o;
                }
                uniform sampler2D _MainTex;
                uniform fixed _Cutoff;
                uniform fixed _MaxDepth;
                fixed4 frag(v2f i) : COLOR{
                    half alpha = tex2D(_MainTex, i.uv).a;

                    clip(alpha - _Cutoff);
                    //UNITY_OUTPUT_DEPTH(i.depth);
                    //return fixed4(i.pos.z / _MaxDepth, i.pos.z / _MaxDepth, i.pos.z / _MaxDepth, 1);
                    RETURN_DEPTH(i.depth, _MaxDepth);
                }
                ENDCG
            }
        }

        SubShader {
            Tags { "RenderType" = "TreeBillboard" }
            Pass {
                Cull Off
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"
                #include "TerrainEngine.cginc"
                struct v2f {
                    float4 pos : POSITION;
                    float2 uv : TEXCOORD0;
                    float depth : TEXCOORD1;
                };
                v2f vert(appdata_tree_billboard v) {
                    v2f o;
                    TerrainBillboardTree(v.vertex, v.texcoord1.xy, v.texcoord.y);
                    o.pos = UnityObjectToClipPos(v.vertex);
                    o.uv.x = v.texcoord.x;
                    o.uv.y = v.texcoord.y > 0;
                    VERTEX_DEPTH(o.depth);
                    return o;
                }
                uniform sampler2D _MainTex;
                uniform fixed _MaxDepth;
                fixed4 frag(v2f i) : COLOR {
                    fixed4 texcol = tex2D(_MainTex, i.uv);
                    clip(texcol.a - 0.001);
                    //UNITY_OUTPUT_DEPTH(i.depth);
                    //return fixed4(i.pos.z / _MaxDepth, i.pos.z / _MaxDepth, i.pos.z / _MaxDepth, 1);
                    RETURN_DEPTH(i.depth, _MaxDepth);
                }
                ENDCG
            }
        }

        SubShader {
            Tags { "RenderType" = "GrassBillboard" }
            Pass {
                Cull Off
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"
                #include "TerrainEngine.cginc"
                #pragma glsl_no_auto_normalization

                struct v2f {
                    float4 pos : POSITION;
                    fixed4 color : COLOR;
                    float2 uv : TEXCOORD0;
                    float depth : TEXCOORD1;
                };

                v2f vert(appdata_full v) {
                    v2f o;
                    WavingGrassBillboardVert(v);
                    o.color = v.color;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    o.uv = v.texcoord.xy;
                    VERTEX_DEPTH(o.depth);
                    return o;
                }
                uniform sampler2D _MainTex;
                uniform fixed _Cutoff;
                uniform fixed _MaxDepth;
                fixed4 frag(v2f i) : COLOR {
                    fixed4 texcol = tex2D(_MainTex, i.uv);
                    fixed alpha = texcol.a * i.color.a;
                    clip(alpha - _Cutoff);
                    //UNITY_OUTPUT_DEPTH(i.depth);
                    //return fixed4(i.pos.z / _MaxDepth, i.pos.z / _MaxDepth, i.pos.z / _MaxDepth, 1);
                    RETURN_DEPTH(i.depth, _MaxDepth);
                }
                ENDCG
            }
        }

        SubShader {
            Tags { "RenderType" = "Grass" }
            Pass {
                Cull Off
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"
                #include "TerrainEngine.cginc"
                struct v2f {
                    float4 pos : POSITION;
                    fixed4 color : COLOR;
                    float2 uv : TEXCOORD0;
                    float depth : TEXCOORD1;
                };
                v2f vert(appdata_full v) {
                    v2f o;
                    WavingGrassVert(v);
                    o.color = v.color;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    o.uv = v.texcoord;
                    VERTEX_DEPTH(o.depth);
                    return o;
                }
                uniform sampler2D _MainTex;
                uniform fixed _Cutoff;
                uniform fixed _MaxDepth;
                fixed4 frag(v2f i) : COLOR{
                    fixed4 texcol = tex2D(_MainTex, i.uv);
                    fixed alpha = texcol.a * i.color.a;
                    clip(alpha - _Cutoff);
                    //UNITY_OUTPUT_DEPTH(i.depth);
                    //return fixed4(i.pos.z / _MaxDepth, i.pos.z / _MaxDepth, i.pos.z / _MaxDepth, 1);
                    RETURN_DEPTH(i.depth, _MaxDepth);
                }
                ENDCG
            }
        }
    }
    Fallback Off
}