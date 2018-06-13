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
Shader "VR/Stereo 360 parallax v/v2" {
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

            #define KERNEL_SIZE_X 80
            #define KERNEL_SIZE_Y 40

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
            float4 gammaCorrect(float4 v) {
                return float4( gammaCorrect(v.xyz), v.w );
            }

            float3 Displacement(float2 id, float height, float3 displacementVector) {
                float depth = 1 - height;

                float _PI   = 3.14159265358979323846264338327;
                float _PI_2 = 1.57079632679;
                float _2PI  = 6.28318530718958647692528676654;

                float2 theta_phi = (id.xy * float2(_2PI, _PI)) - float2(_PI, _PI_2);

                float2 sin_theta_phi = sin(theta_phi);
                float2 cos_theta_phi = cos(theta_phi);

                float3 worldPos = float3(cos_theta_phi.y*sin_theta_phi.x, //cos(phi) * sin(theta)
                                         sin_theta_phi.y, // sin(theta)
                                         cos_theta_phi.y*cos_theta_phi.x //cos(phi) * cos(theta)
                                        ) * depth; 
                worldPos += displacementVector;

                float newDepth = length(worldPos);
                float3 newWorldNorm = worldPos / newDepth; // normalized

                float atan2ThetaPhi = atan2(newWorldNorm.x, newWorldNorm.z);

                theta_phi = float2(atan2ThetaPhi, asin(newWorldNorm.y));
                theta_phi = (theta_phi / float2(_2PI, _PI) + 0.5);

                return float3(theta_phi, 1 - newDepth);
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
                
                float height = tex2D(_DepthTex, i.uv).r;

                float maxHeight = 0;
                float2 bestUV = 0;
                int it = 0;
                bool found = false;
                /*float2 texelSignedSize = float2(sign(_RelativePosition) * _DepthTex_TexelSize.x, 
                                                  sign(_RelativePosition) * _DepthTex_TexelSize.y);*/
                
                float2 uv = float2(-_DepthTex_TexelSize.x * (KERNEL_SIZE_X / 2),
                                   -_DepthTex_TexelSize.y * (KERNEL_SIZE_Y / 2));
                                   
                //float2 uv = float2(0, 0);
                //float targetPositionFactor = dot(normalize(i.viewDir), float3(0.0f, 0.0f, 1.0f));

                float displacementFactor = _ParallaxAmount * -_RelativePosition * _DepthTex_TexelSize.x * 100;

                for (int itCountV = 0; itCountV < KERNEL_SIZE_Y; itCountV++) {
                    for (int itCountU = 0; itCountU < KERNEL_SIZE_X; itCountU++) {
                        float2 currUV = i.uv + uv;
                        
                        if (currUV.x < 0) currUV.x += 1.0;
                        if (currUV.y < 0) currUV.y += 1.0;
                        if (currUV.x > 1) currUV.x -= 1.0;
                        if (currUV.x > 1) currUV.y -= 1.0;
                        
                        float3 currCellDispl = Displacement(currUV, 
                                                            tex2D(_DepthTex, currUV).r, // depth
                                                            float3(displacementFactor, 0, 0));

                        if (abs(currCellDispl.x - i.uv.x) <= _DepthTex_TexelSize.x &&
                            abs(currCellDispl.y - i.uv.y) <= _DepthTex_TexelSize.y) {
                            if (currCellDispl.z >= maxHeight) {
                                maxHeight = currCellDispl.z;
                                bestUV = currUV;
                                found = true;
                            }
                        }

                        uv.x += _DepthTex_TexelSize.x;
                    }
                    uv.x = 0;
                    uv.y += _DepthTex_TexelSize.y;
                }
                return found ? gammaCorrect(tex2D(_MainTex, bestUV)) : float4(1.0, 0.0, 1.0, 1.0);

            }
            ENDCG
        }
    }
    Fallback "Unlit/Texture"
}
