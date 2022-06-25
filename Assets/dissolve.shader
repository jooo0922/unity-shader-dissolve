Shader "Custom/dissolve"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _NoiseTex ("NoiseTex", 2D) = "white" {} // ������ �ؽ��ĸ� �ޱ� ���� �������̽� �߰�
    }
    SubShader
    {
        // Ÿ���� ȿ���� �����Ϸ��� ���İ� �ʿ���. ���� ���� ���̴��� alpha blending ���̴��� ������.
        Tags { "RenderType"="Transparent" "Queue"="Transparent"} 

        CGPROGRAM
        #pragma surface surf Lambert alpha:fade // alpha:fade ���� �߰������ �������� �����

        sampler2D _MainTex;
        sampler2D _NoiseTex; // ������ �ؽ��ĸ� ��� ���÷� ���� ����

        struct Input
        {
            float2 uv_MainTex;
            float2 uv_NoiseTex; // ������ �ؽ��ĸ� ���ø��� ���ؽ� uv ��ǥ ����
        };

        void surf (Input IN, inout SurfaceOutput o)
        {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
            float4 noise = tex2D(_NoiseTex, IN.uv_NoiseTex); // ������ �ؽ����� �� �κ��� ���ø��� �ؼ��� (�� �ؼ��� ���� ���� ������ r, g, b ���� �ް���?)
            o.Albedo = c.rgb;
            o.Alpha = noise.r; // o.Alpha �� ������ �ؽ��� �ؼ��� r���� �Ҵ���. -> ���ø��� ������ �ؽ����� ���� ���� ������ �ٸ��� ����ǰڱ�
        }
        ENDCG
    }
    FallBack "Diffuse"
}
