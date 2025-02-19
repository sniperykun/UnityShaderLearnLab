﻿// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

//
// Blinn-Phong Light Model
// 

// 
// final color =  ambient + diffuse + specular
//

// 
// PBS :  also calculate diffuse and specular in PBR way to get more real looking
//

// Blinn-Phong Light Model
// 1. diffuse
// 2. specular
// 3. recevice shadow
// 4. cast shadow

Shader "roadtoshaderdog/lighting/BasicLightMode-Blinn-Phong"
{
    Properties
    {
        _MainTex ("Albedo", 2D) = "white" {}
        _AlbedoColor("Albedo Color", Color) = (1, 1, 1, 1)
        _NormalMap("Normal", 2D) = "bump" {}
        _SpecularTex("Specular", 2D) = "white" {}
        _Gloss("Gloss", Float) = 1.0
        _SpecularColor("Specular Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        
        // forward base shader
        Pass
        {
            Tags 
            { 
                "LightMode" = "ForwardBase"
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 pos   : SV_POSITION;
                float2 uv       : TEXCOORD0;
                float3 eyeDir   : TEXCOORD1;
                float3 lightDir : TEXCOORD2;
                float3 normal   : TEXCOORD3;
                float3 tangent  : TEXCOORD4;
                float3 binormal : TEXCOORD5;
                SHADOW_COORDS(6)
                // half3 worldPos  : TEXCOORD6;
            };

            sampler2D _MainTex;
            sampler2D _NormalMap;
            sampler2D _SpecularTex;
            half3 _SpecularColor;
            half3 _AlbedoColor;
            half _Gloss;
            
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.eyeDir = normalize(UnityWorldSpaceViewDir(worldPos));
                // o.worldPos = worldPos;
                // Directional lights[_WorldSpaceLightPos0]
                o.lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.tangent.xyz = UnityObjectToWorldDir(v.tangent.xyz);

                // w is usually 1.0, or -1.0 for odd-negative scale transforms
                half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                // we create binormal in vertex shader
                o.binormal = cross(o.normal, o.tangent.xyz) * tangentSign;
                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                half3 tangentSpaceNormal = UnpackNormal(tex2D(_NormalMap, i.uv));
                half3 worldNormal;

                float3 vff01 = float3(i.tangent.x, i.binormal.x, i.normal.x);
                float3 vff02 = float3(i.tangent.y, i.binormal.y, i.normal.y);
                float3 vff03 = float3(i.tangent.z, i.binormal.z, i.normal.z);
                
                worldNormal.x = dot(vff01, tangentSpaceNormal);
                worldNormal.y = dot(vff02, tangentSpaceNormal);
                worldNormal.z = dot(vff03, tangentSpaceNormal);
                
                // Build Matrix
                // float3x3(first column, second column, thired column)
                // build transformation with three basis vector(normal, tangent, binormal)
                half3x3 tangentSpaceToWorldSpace = half3x3(
                    i.tangent,
                    i.binormal,
                    i.normal);
                
                // convert normal texture's normal rotate to world normal
                // worldNormal = normalize(mul(tangentSpaceNormal, tangentSpaceToWorldSpace));
                // must be this
                // https://forum.unity.com/threads/mul-function-and-matrices.445266/
                // worldNormal = normalize(mul(tangentSpaceNormal, tangentSpaceToWorldSpace));

                // return fixed4(normalVec, 1.0);
                fixed3 diffuseColor = tex2D(_MainTex, i.uv);
                // return fixed4(normalVec, 1.0);
                // return fixed4(diffuseColor, 1.0);
                diffuseColor = _LightColor0.rgb
                    * diffuseColor
                    * max(0, dot(worldNormal, i.lightDir))
                    * _AlbedoColor;

                // return fixed4(diffuseColor, 1.0);

                // SKY_BOX_COLOR REFLECTION
                // Specular
                // No need to calculate viewdir and lightdir in fragment shader
                // calculate in vertex shader
                // half3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                // half3 lightDir= normalize(UnityWorldSpaceLightDir(i.worldPos));

                half3 viewDir = i.eyeDir;
                half3 lightDir = i.lightDir;

                // phong light model
                #ifndef PHONE_LIGHt_MODEL
                    fixed3 reflectdir = reflect(-lightDir, worldNormal);
                    float spevalue = pow(saturate(dot(viewDir, reflectdir)), _Gloss);
                #else
                    // blinn-phong light model
                    half3 hVector = normalize(viewDir + lightDir);
                    float spevalue = pow(saturate(dot(hVector, worldNormal)), _Gloss);
                #endif

                half4 specularSamplercolor = tex2D(_SpecularTex, i.uv);
                // specular saved in alpha channel
                half3 specularcolor = half3(specularSamplercolor.a, specularSamplercolor.a, specularSamplercolor.a);
                // return fixed4(specularcolor, 1.0);
                specularcolor = specularcolor * _SpecularColor * spevalue;
                // return fixed4(worldNormal, 1.0);
                fixed shadow = SHADOW_ATTENUATION(i);
                // return fixed4(i.binormal, 1.0);
                return fixed4(diffuseColor * shadow + specularcolor, 1.0);
            }
            ENDCG
        }
        
        // pass for shadow caster
        Pass
        {
            Tags{"LightMode" = "ShadowCaster"}
            CGPROGRAM
            #pragma vertex vert
			#pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
	            float4 position : POSITION;
            };

            float4 vert (appdata v) : SV_POSITION
            {
	            float4 position = UnityObjectToClipPos(v.position);
                // return position;
                // need apply shadow bias offset
                return UnityApplyLinearShadowBias(position);
            }

            half4 frag () : SV_TARGET
            {
	            return 0;
            }
            ENDCG
        }
    }
}
