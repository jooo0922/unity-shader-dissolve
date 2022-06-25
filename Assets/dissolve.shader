Shader "Custom/dissolve"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _NoiseTex ("NoiseTex", 2D) = "white" {} // 노이즈 텍스쳐를 받기 위한 인터페이스 추가
    }
    SubShader
    {
        // 타들어가는 효과를 적용하려면 알파가 필요함. 따라서 현재 쉐이더를 alpha blending 쉐이더로 지정함.
        Tags { "RenderType"="Transparent" "Queue"="Transparent"} 

        CGPROGRAM
        #pragma surface surf Lambert alpha:fade // alpha:fade 까지 추가해줘야 반투명이 적용됨

        sampler2D _MainTex;
        sampler2D _NoiseTex; // 노이즈 텍스쳐를 담는 샘플러 변수 선언

        struct Input
        {
            float2 uv_MainTex;
            float2 uv_NoiseTex; // 노이즈 텍스쳐를 샘플링할 버텍스 uv 좌표 선언
        };

        void surf (Input IN, inout SurfaceOutput o)
        {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
            float4 noise = tex2D(_NoiseTex, IN.uv_NoiseTex); // 노이즈 텍스쳐의 각 부분을 샘플링한 텍셀값 (각 텍셀의 명도에 따라 동일한 r, g, b 값을 받겠지?)
            o.Albedo = c.rgb;
            o.Alpha = noise.r; // o.Alpha 에 노이즈 텍스쳐 텍셀의 r값을 할당함. -> 샘플링된 노이즈 텍스쳐의 명도에 따라 투명도가 다르게 적용되겠군
        }
        ENDCG
    }
    FallBack "Diffuse"
}
