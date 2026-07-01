Shader "Nature/Procedural Tree URP"
{
    Properties
    {
        _BarkMap("Bark Texture", 2D) = "white" {}
        _BarkColor("Bark Color", Color) = (1,1,1,1)
        _BarkSmoothness("Bark Smoothness", Range(0,1)) = 0.12
        _LeafMap("Leaf Texture", 2D) = "white" {}
        _LeafColor("Leaf Color", Color) = (1,1,1,1)
        _LeafBottomTint("Leaf Bottom Tint", Color) = (0.24,0.42,0.20,1)
        _LeafTopTint("Leaf Top Tint", Color) = (0.58,0.82,0.34,1)
        _Cutoff("Alpha Cutoff", Range(0,1)) = 0.4
        _LeafTranslucency("Leaf Translucency", Range(0,2)) = 0.4
        _LeafSmoothness("Leaf Smoothness", Range(0,1)) = 0.05
        _WindStrength("Wind Strength", Range(0,0.5)) = 0.025
        _WindSpeed("Wind Speed", Range(0,10)) = 1.6
        _WindScale("Wind Scale", Range(0.1,10)) = 1.8
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "TransparentCutout"
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "AlphaTest"
        }
        LOD 250
        Cull Off

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4 _BarkMap_ST;
            float4 _LeafMap_ST;
            float4 _BarkColor;
            float4 _LeafColor;
            float4 _LeafBottomTint;
            float4 _LeafTopTint;
            float _BarkSmoothness;
            float _LeafSmoothness;
            float _LeafTranslucency;
            float _Cutoff;
            float _WindStrength;
            float _WindSpeed;
            float _WindScale;
        CBUFFER_END

        TEXTURE2D(_BarkMap); SAMPLER(sampler_BarkMap);
        TEXTURE2D(_LeafMap); SAMPLER(sampler_LeafMap);

        struct Attributes
        {
            float4 positionOS : POSITION;
            float3 normalOS   : NORMAL;
            float4 color      : COLOR;
            float2 uv         : TEXCOORD0;
        };

        struct Varyings
        {
            float4 positionHCS : SV_POSITION;
            float2 uv          : TEXCOORD0;
            float4 color       : TEXCOORD1;
            float3 normalWS    : TEXCOORD2;
            float3 positionWS  : TEXCOORD3;
        };

        Varyings vert(Attributes IN)
        {
            Varyings OUT;

            float3 posOS = IN.positionOS.xyz;

            half leafMask = saturate(IN.color.a);
            half inheritedWind = saturate(IN.color.b);
            half leafFlutter = saturate(IN.uv.y) * leafMask;

            float timeValue = _Time.y * _WindSpeed;
            float waveA = sin((posOS.x + posOS.z) * _WindScale + timeValue);
            float waveB = cos(posOS.z * (_WindScale * 1.37) + timeValue * 1.19);
            float waveC = sin(posOS.y * (_WindScale * 0.73) + timeValue * 0.81);
            float sway = (waveA + waveB + waveC) * 0.33333334;

            posOS.x += sway * (_WindStrength * 0.55) * inheritedWind;
            posOS.z += waveA * (_WindStrength * 0.28) * inheritedWind;
            posOS.y += waveB * (_WindStrength * 0.08) * inheritedWind;

            posOS.x += sway * _WindStrength * leafFlutter;
            posOS.z += waveA * (_WindStrength * 0.45) * leafFlutter;
            posOS.y += waveB * (_WindStrength * 0.18) * leafFlutter;

            VertexPositionInputs vertexInput = GetVertexPositionInputs(posOS);
            OUT.positionHCS = vertexInput.positionCS;
            OUT.positionWS = vertexInput.positionWS;
            OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
            OUT.uv = IN.uv;
            OUT.color = IN.color;
            return OUT;
        }

        half4 frag(Varyings IN, half facing : VFACE) : SV_Target
        {
            half leafMask = saturate(IN.color.a);

            half2 barkUV = IN.uv * _BarkMap_ST.xy + _BarkMap_ST.zw;
            half2 leafUV = IN.uv * _LeafMap_ST.xy + _LeafMap_ST.zw;

            half4 barkSample = SAMPLE_TEXTURE2D(_BarkMap, sampler_BarkMap, barkUV) * _BarkColor;
            half4 leafSample = SAMPLE_TEXTURE2D(_LeafMap, sampler_LeafMap, leafUV) * _LeafColor;

            half3 leafGradient = lerp(_LeafBottomTint.rgb, _LeafTopTint.rgb, saturate(leafUV.y));
            half leafVariation = lerp(0.9h, 1.1h, saturate(IN.color.r));

            half3 barkAlbedo = barkSample.rgb;
            half3 leafAlbedo = leafSample.rgb * leafGradient * leafVariation;

            half alpha = lerp(1.0h, leafSample.a, leafMask);
            clip(alpha - _Cutoff);

            half faceSign = facing >= 0.0h ? 1.0h : -1.0h;
            half3 normalWS = normalize(IN.normalWS) * faceSign;

            Light mainLight = GetMainLight();
            half3 lightDir = normalize(mainLight.direction);
            half backLighting = saturate(dot(-normalWS, lightDir));

            half3 albedo = lerp(barkAlbedo, leafAlbedo, leafMask);

            // éclairage diffuse simple (Lambert) + translucence des feuilles
            half NdotL = saturate(dot(normalWS, lightDir));
            half3 diffuse = albedo * mainLight.color * (NdotL * mainLight.shadowAttenuation + 0.05h);
            half3 emission = leafAlbedo * backLighting * _LeafTranslucency * leafMask * mainLight.color;

            half3 finalColor = diffuse + emission;
            return half4(finalColor, 1.0h);
        }
        ENDHLSL

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            ZWrite On
            ColorMask 0
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDHLSL
        }
    }
    FallBack "Universal Render Pipeline/Lit"
}
