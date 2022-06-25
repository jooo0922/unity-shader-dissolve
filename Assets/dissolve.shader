Shader "Custom/dissolve"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _NoiseTex ("NoiseTex", 2D) = "white" {} // 노이즈 텍스쳐를 받기 위한 인터페이스 추가
        _Cut ("Alpha Cut", Range(0, 1)) = 0 // alpha 를 숨길지 말지를 결정할 기준값을 받는 인터페이스 추가
        [HDR]_OutColor ("OutColor", Color) = (1, 1, 1, 1) // HDR 색상(1보다 크거나 0보다 큰 색상값)을 받는 인터페이스 추가
        _OutlineThickness ("0utlineThickness", Range(1, 1.5)) = 1.15 // 기준값을 얼만큼 늘릴것인지 (늘리는 만큼 테두리 영역이 늘어남) 결정하는 값을 받는 인터페이스 추가
    }
    SubShader
    {
        // 타들어가는 효과를 적용하려면 알파가 필요함. 따라서 현재 쉐이더를 alpha blending 쉐이더로 지정함.
        Tags { "RenderType"="Transparent" "Queue"="Transparent"} 

        CGPROGRAM
        #pragma surface surf Lambert alpha:fade // alpha:fade 까지 추가해줘야 반투명이 적용됨

        sampler2D _MainTex;
        sampler2D _NoiseTex; // 노이즈 텍스쳐를 담는 샘플러 변수 선언
        float _Cut; // 노이즈 텍스쳐 샘플링 값과 비교하여 alpha 를 숨길지 말지를 결정할 기준값
        float4 _OutColor; // Bloom 효과를 위해 받는 HDR 색상값
        float _OutlineThickness; // 기준값애 곱해서 기준값을 늘리는 값 (늘리는 만큼 테두리 영역이 늘어남)

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
            //o.Alpha = noise.r; // o.Alpha 에 노이즈 텍스쳐 텍셀의 r값을 할당함. -> 샘플링된 노이즈 텍스쳐의 명도에 따라 투명도가 다르게 적용되겠군

            // 인터페이스로부터 받은 특정 cutoff 값을 기준으로 각 픽셀의 투명도를 다르게 계산해주는 로직
            float alpha;
            // 샘플링한 노이즈 텍스쳐의 r값과 비교해서 기준값보다 크면 픽셀을 보여주고, 작으면 알파를 0으로 떨궈서 숨김.
            // 이렇게 함으로써, _Cut 값의 변화에 따라 보여지는 픽셀과 숨겨지는 픽셀이 매번 달라지겠지! -> 아주 간단한 원리
            if (noise.r >= _Cut) alpha = 1; // 기준값을 통과하는 영역은 투명도 100%
            else alpha = 0; // 기준값을 통과하지 못하는 영역은 투명도 0%
            o.Alpha = alpha;

            // 이번엔 기준값을 좀 더 키워서 (즉, 기준값보다 큰 영역을 좀 더 줄여서~) 안쪽은 검정색, 바깥쪽은 흰색으로 칠해봄.
            float color; // 책에서는 outline 이라는 변수명을 사용했지만, color 라고 이름짓는게 좀 더 직관적이고 이해가 쉬움.
            if (noise.r >= _Cut * _OutlineThickness) color = 0; // 증가된 기준값을 통과하는 영역은 검정색
            else color = 1; // 증가된 기준값을 통과하지 못하는 영역은 흰색 (이미 _Cut 기준값을 통과하지 못한 영역은 투명해지므로, 나머지 영역 중 1.15배 만큼 증가한 영역만이 흰색으로 찍히겠지. 색상은 1.15배 증가한 기준값을 사용하니까!)
            o.Emission = color * _OutColor.rgb; // HDR 컬러에 기준값에 따라 0 또는 1이 할당된 color값을 곱함으로써 1이 찍힌 영역만 Emission 을 HDR Bloom 효과를 내며 렌더할 수 있도록 함.
        }
        ENDCG
    }
    FallBack "Diffuse"
}

/*
    1.15배 증가된 기준값을 사용하는 이유

    1. 기준값을 증가시켜야 더 적은 영역이 해당됨.
    기준값을 증가시키면, 앞서 원래의 기준값으로 알파를 1로 적용한 영역보다
    더 좁은 영역만큼에 검정색을 칠함으로써, 나머지 영역을 테두리처럼 흰색으로 채울 수 있음.

    이 원리는 기본적으로 원래의 기준값을 인터페이스로 조절할 시
    기준값이 커질수록 더 좁은 영역만이 알파가 1로 적용되는 걸 보면 알 수 있음.


    2. 0.15 정도의 값을 더하는 대신 1.15배 곱해서 기준값을 증가시킨 이유
    기준값을 0.15만큼 더해서 증가시켜주면, 원래의 기준값이 0일 때, 
    증가된 기준값도 0이 아니게 됨.

    이거로 인해 무슨 문제가 생기냐면,
    원래의 기준값은 0이라서 모든 영역의 알파값이 1이 되어 
    모든 픽셀들이 다 렌더링되는데

    증가된 기준값은 0.15가 될테니,
    0.15보다 작은 영역은 흰색으로 칠해지고,
    그거보다 큰 영역은 검정색으로 칠해져서
    원하는 결과가 나오지 않음.

    원하는 결과란, 알파값이 전부 적용되는 상황에서는
    색상도 전부 검정색으로 나와야 함.

    왜냐하면, 이 상태를 기반으로 해서
    이제 색상에는 c.rgb, 즉 원래 색상을 더해줄거고,
    나머지 테두리 영역에 Emission 에 특정 색상을 더해서 디졸브 효과를 구현할거임.

    근데, 기준값이 0인 상태에서는 오로지 c.rgb 만 나와야 되는데
    증가된 기준값이 0.15 정도로 애매하게 남아버리면
    c.rgb 가 깔린 상태에서 일부분에 Emission 이 적용되어서
    깔끔하지 못하게 렌더링 되어버림.
*/