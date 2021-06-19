Shader "Custom/Cloud"
{
    Properties
    {
        _TopColor("Cloud Top Color", Color) = (1,1,1,1)
        _CloudColor("Cloud Color", Color) = (1,1,1,1)
        _RimColorClear("Rim Color Clear", Color) = (1,1,1,1)
        _RimColorStormy("Rim Color Stormy", Color) = (1,1,1,1)
        _StormyStrength("Stormy Strength", Range(0,1)) = 0.0
        _RimPower("Rim Power", Range(0,40)) = 20
        _NoiseTex("Noise (RGB)", 2D) = "gray" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Height ("Cloud Height", Range(0,2)) = 0.8
        _Strength("Noise Strength", Range(0,0.1)) = 0.005
        _EmissionStrength("Noise Emission Strength", Range(0,2)) = 0.3
        _TimePass("Pass Time from Script", Float) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows vertex:vert addshadow

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex, _NoiseTex;
        half _Glossiness;
        half _Metallic;
        fixed4 _Color, _CloudColor, _TopColor, _RimColorClear, _RimColorStormy;
        float _EmissionStrength, _RimPower, _Height, _Strength, _StormyStrength, _TimePass;

        struct Input
        {
            float2 uv_MainTex;
            float4 color;
            float3 viewDir;
            float3 worldNormal;
        };

        void vert(inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);

            float3 worldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0)).xyz;
            float4 noiseXY = tex2Dlod(_NoiseTex, float4(worldPos.xy * _Strength + _TimePass, 1.0, 1.0));
            float4 noiseXZ = tex2Dlod(_NoiseTex, float4(worldPos.xz * _Strength + _TimePass, 1.0, 1.0));
            float4 noiseYZ = tex2Dlod(_NoiseTex, float4(worldPos.yz * _Strength + _TimePass, 1.0, 1.0));

            float4 noiseCombine = noiseXY;
            noiseCombine = lerp(noiseCombine, noiseXZ, o.worldNormal.z);
            noiseCombine = lerp(noiseCombine, noiseYZ, o.worldNormal.x);

            v.vertex.xyz += (v.normal * (noiseCombine * _Height));

            o.color = lerp(_CloudColor, _TopColor, v.vertex.z); // USE Z-AXIS BECAUSE BLENDER IS SPECIAL AND NEEDS TO USE Z-AXIS FOR UP-DOWN
        }

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = IN.color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
            half rim = 1.0 - saturate(dot(normalize(IN.viewDir), o.Normal * _EmissionStrength)); // Calculate Rim effect from Unity Docs
            float3 cloudC = lerp(_RimColorClear, _RimColorStormy, _StormyStrength); // Change color between clear and stormy (Change from script _StormyStrength)
            o.Emission = cloudC * pow(rim, _RimPower); // Pass Rim color and affect it by a power to change its intensity
        }
        ENDCG
    }
    FallBack "Diffuse"
}
