// <copyright file="InsideShader.cs" company="Google Inc.">
// Copyright (C) 2016 Google Inc. All Rights Reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//    limitations under the License.
// </copyright>

//
// This shader switches the culling to the front side and inverts the normal so
// textures are drawn on the inside or back of the object.
//
Shader "VR/Stereo 360 parallax" {
    Properties {
        _Gamma ("Video gamma", Range(0.01,3.0)) = 1.0
        _MainTex("Base (RGB)", 2D) = "white" {}
        _StereoVideo("Render Stereo Video", Int) = 1
        _RenderedEye("RenderedEye", Int) = 0
        [Header(Parallax)]
        _DepthTex("Depth", 2D) = "white" {}
        _RelativePosition("Position", Range(-1.0,1.0)) = 0
        _ParallaxAmount("Amount", Range(0.0,1.0)) = 0.3
    }

    SubShader {
        Pass {
            Tags { "RenderType" = "Opaque" }

            // cull the outside, since we want to draw on the inside of the mesh.
            Cull Front

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float4 _MainTex_ST;
            sampler2D _MainTex;
            sampler2D _DepthTex;
            uniform float4 _DepthTex_TexelSize;
            int _StereoVideo;
            float _Gamma;
            float _RelativePosition;
            float _ParallaxAmount;
            int _RenderedEye;

            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 viewDir : NORMAL;
            };

            float3 gammaCorrect(float3 v)
            {
                return pow(v, 1.0/_Gamma);
            }

            float3 gammaCorrectApprox(float3 v) {
                return rsqrt(v);
            }

            // Apply the gamma correction.  One possible optimization that could
            // be applied is if _Gamma == 2.0, then use gammaCorrectApprox since sqrt will be faster.
            // Also, if _Gamma == 1.0, then there is no effect, so this call could be skipped all together.
            float4 gammaCorrect(float4 v)
            {
                return float4( gammaCorrect(v.xyz), v.w );
            }

            v2f vert (appdata_base v) {
                v2f o;
                // invert the normal of the vertex
                v.normal.xyz = v.normal * -1;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX (v.texcoord, _MainTex);
                if (_StereoVideo > 0) {
                    o.uv.y *= 0.5f;
                    if(unity_StereoEyeIndex == _RenderedEye) {
                        o.uv.y += 0.5f;
                    }
                }
                o.uv.x = 1 - o.uv.x;

                // apply MV matrix
                o.viewDir = UnityObjectToViewPos(v.normal);

                return o;
            }

            float4 frag (v2f i) : SV_Target {
                //half h = DecodeFloatRGBA(tex2D(_DepthTex, IN.uv_BumpMap));
                //float2 offset = ParallaxOffset(h, _Parallax, IN.viewDir);

                
                float height = DecodeFloatRGBA(tex2D(_DepthTex, i.uv));

                float maxHeight = 0;
                float2 bestUV = 0;
                float u = 0;
                int it = 0;
                bool found = false;
                float texelSignedSize = sign(-_RelativePosition) * _DepthTex_TexelSize.x;

                //float targetPositionFactor = dot(normalize(i.viewDir), float3(0.0f, 0.0f, 1.0f));

                float displacementFactor = _ParallaxAmount * -_RelativePosition * _DepthTex_TexelSize.x * 40;

                for (int itCount = 0; itCount < 40; itCount++) {
                    float2 currUV = i.uv + float2(u, 0);
                    float currCellHeight = DecodeFloatRGBA(tex2D(_DepthTex, currUV));
                    float currCelluDispl = currCellHeight * displacementFactor;
                    float2 newUV = currUV + float2(currCelluDispl, 0);
                    if (abs(newUV.x - i.uv.x) <= _DepthTex_TexelSize.x) {
                        if (currCellHeight >= maxHeight) {
                            maxHeight = currCellHeight;
                            bestUV = currUV;
                            found = true;
                        }
                    }
                    u -= texelSignedSize;
                }
                return found ? gammaCorrect(tex2D(_MainTex, bestUV)) : float4(1.0, 0.0, 1.0, 1.0);
                
                

            /*  
                // aproximacion decente
                float sn = _RelativePosition/2;
                float cs = sqrt(1 - sn*sn);
                //consideramos verlo todo un poco mas girado en funcion de la posición de la simulación de la cabeza
                float3 newViewDir = float3(i.viewDir.x * cs - i.viewDir.z * sn, i.viewDir.y, i.viewDir.x * sn - i.viewDir.z * cs);

                float uDisplacement = ParallaxOffset(height, _ParallaxAmount * 0.1, newViewDir);
            */
                //int mipLevel = 0;
                //if (mipLevel == 0) {
                    //return DecodeFloatRGBA(tex2Dlod(_DepthTex, float4(i.uv + float2(uDisplacement, 0), mipLevel, mipLevel)));
                //}
                //return tex2Dlod(_DepthTex, float4(i.uv + float2(uDisplacement, 0), mipLevel, mipLevel)).rrrr;
                
                //Version 1
                float h = DecodeFloatRGBA(tex2D(_DepthTex, i.uv));
                float uDisplacement = h * _ParallaxAmount * _RelativePosition * _DepthTex_TexelSize.x * 40;
                return gammaCorrect(tex2D(_MainTex, i.uv + float2(uDisplacement, 0)));
                

                //https://docs.unity3d.com/2018.1/Documentation/Manual/SL-PropertiesInPrograms.html
                float dist = (uDisplacement / _DepthTex_TexelSize.x);
                /*return fixed4( 
                                   1.0 * (dist/10),
                    dist > 10.0f ? 1.0 * ((dist-10)/10) : 0.0,
                    dist > 10.0f ? 1.0 * ((dist-20)/5) : 0.0,
                    1.0);*/
                if (dist > 25) {
                    return fixed4(
                        dist <= 30.0f ? 1.0 * ((dist - 25) / 5) : dist > 35.0f && dist <= 40.0f ? 1.0 * ((dist - 35) / 5) : 0.0,
                        dist <= 30.0f ? 1.0 * ((dist - 25) / 5) : dist <= 35.0f ? 1.0 * ((dist - 30) / 5) : 0.0,
                        dist > 30.0f && dist <= 35.0f ? 1.0 * ((dist - 30) / 5) : dist > 35.0f && dist <= 40.0f ? 1.0 * ((dist - 35) / 5) : 0.0,
                        1.0);
                }
                if (dist > 35) {
                    return fixed4(1.0, 1.0, 1.0, 1.0);
                }
                return fixed4(
                    dist <= 10.0f ? 1.0 * (dist / 10) : 0,
                    dist > 10.0f && dist <= 20.0f ? 1.0 * ((dist - 10) / 10) : 0.0,
                    dist > 20.0f && dist <= 25.0f ? 1.0 * ((dist - 20) / 5) : 0.0,
                    1.0);

                //return DecodeFloatRGBA(tex2D(_DepthTex, i.uv));

                // debug for not colored pixels
                return float4(sin(_Time.yzw * 4), 1.0);
            }
            ENDCG
        }
    }
    Fallback "Unlit/Texture"
}
