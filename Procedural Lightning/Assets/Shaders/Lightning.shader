//Code is converted to use in Unity(ShaderLab) from
//Lightining by asti
//on Shadertoy(https://www.shadertoy.com/view/Xds3Rj)

Shader "Custom/Lightning"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
	_CustomTime("TimeDiff", Float) = 0.5
	}
		SubShader
	{
		//Tags { "RenderType"="Opaque" }
		//LOD 100

		Tags{ "Queue" = "Transparent" "RenderType" = "Transparent" }
		LOD 100

		ZWrite Off
		Blend OneMinusDstColor One

		Pass
	{
		CGPROGRAM
#pragma vertex vert
#pragma fragment frag

#include "UnityCG.cginc"

#define LIGHTNING_PARTS 10

		struct appdata
	{
		float4 vertex : POSITION;
		float2 uv : TEXCOORD0;
	};

	struct v2f
	{
		float2 uv : TEXCOORD0;
		float4 vertex : SV_POSITION;
	};

	sampler2D _MainTex;
	float4 _MainTex_ST;
	float _CustomTime;

	v2f vert(appdata v)
	{
		v2f o;
		o.vertex = UnityObjectToClipPos(v.vertex);
		o.uv = v.uv;
		return o;
	}

	float hash(in float x)
	{
		return frac(21654.6512 * sin(385.51 * x));
	}

	float hash(float2 p)
	{
		return frac(21654.65155 * sin(35.51 * p.x + 45.51 * p.y));
	}

	float lhash(float x, float y)
	{
		float h = 0.0;
		[unroll(5)]for (int i = 0; i < 5; i++)
		{
			h += (frac(21654.65155 * float(i) * sin(35.51 * x + 45.51 * float(i) * y * (5.0 / float(i))))* 2.0 - 1.0) / 10.0;
		}
		return h / 5.0 + 0.02;
	}

	float noise(in float2 p)
	{
		float2 fl = floor(p);
		float2 fr = frac(p);

		fr.x = smoothstep(0.0, 1.0, fr.x);
		fr.y = smoothstep(0.0, 1.0, fr.y);

		float a = lerp(hash(fl + float2(0.0, 0.0)), hash(fl + float2(1.0, 0.0)), fr.x);
		float b = lerp(hash(fl + float2(0.0, 1.0)), hash(fl + float2(1.0, 1.0)), fr.x);

		return lerp(a, b, fr.y);
	}

	float distanceToSegment(float2 a, float2 b, float2 p)
	{
		float2 pa = p - a;
		float2 ba = b - a;
		float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);

		return length(pa - ba*h);
	}

	float lightning2(float2 ls, float2 le, float intensity, float2 uv)
	{
		float f = 1.0;

		[unroll(10)]for (int i = 0; i < LIGHTNING_PARTS; i++)
		{

			float2 ltemp1 = lerp(ls, le, float(i) / float(LIGHTNING_PARTS));
			float2 ltemp2 = lerp(ls, le, float(i + 1) / float(LIGHTNING_PARTS));
			float h3 = frac(21654.65155 * sin(35.51 * ls.x));
			float lh1 = lhash(ltemp1.y, _Time.y);
			float lh2 = lhash(ltemp2.y, _Time.y);
			ltemp1.x += lh1;
			ltemp2.x += lh2;

			if (i == 0) {
				f = min(f, distanceToSegment(ls, ltemp2, uv));
			}

			//else if(i == LIGHTNING_PARTS - 1)
			//f = min(f,distanceToSegment(ltemp1, le, uv ));
			else {
				f = min(f, distanceToSegment(ltemp1, ltemp2, uv));
			}

			//if(abs(h3) > 0.07 && intensity > 0.1)
			//f = min(f,lightning(ltemp1, vec2(mix(ltemp1, le, 0.5) + vec2(lh1 * 3.0 - h3 * 5.0,h3 * 5.0)),intensity * 0.5,uv));

			//	f = min(f,distanceToSegment(ltemp1, vec2(mix(ltemp1, le, 0.5) + vec2(lh1 * 3.0 - h3 * 5.0,h3 * 5.0)),uv));
		}

		return f;
	}

	float lightning(float2 ls, float2 le, float intensity, float2 uv)
	{
		float f = 1.0;

		for (int i = 0; i < LIGHTNING_PARTS; i++)
		{

			float2 ltemp1 = lerp(ls, le, float(i) / float(LIGHTNING_PARTS));
			float2 ltemp2 = lerp(ls, le, float(i + 1) / float(LIGHTNING_PARTS));
			float h3 = frac(22654.65155 * ls.x * sin(3542.51 * ltemp1.y * le.y)) - sqrt(ltemp1.y) + 0.6;
			float lh1 = lhash(ltemp1.y + ltemp1.x, _Time.y);
			float lh2 = lhash(ltemp2.y + ltemp2.x, _Time.y);
			ltemp1.x += lh1;
			ltemp2.x += lh2;

			if (i == 0)
				f = min(f, distanceToSegment(ls, ltemp2, uv));
			else
				f = min(f, distanceToSegment(ltemp1, ltemp2, uv));
			if (h3 > 0.9)
				f = min(f, sqrt(float(i + 2)) * lightning2(ltemp1, float2(le.x + ltemp1.y + sqrt(h3) - 1.0 + lh1 * 7.0, le.y), intensity * 0.5, uv));
		}

		return f;
	}


	fixed4 frag(v2f i) : SV_Target
	{
		float2 vignetteUv = i.uv;
		//vec2 uv = fragCoord.xy / iResolution.xy;
		float2 uv = i.uv;

		uv = uv*2.0 - 1.0;
		uv.x *= _ScreenParams.x / _ScreenParams.y;
		uv.x *= 0.5;

		float4 col = float4(0.0, 0.0, 0.0, 0.0);

		float2 ls = float2(0.0, 1.01);
		float2 le = float2(0.0, -1.0);

		float f = 1.0;
		[unroll(10)]for (int i = 0; i < 10; i++)
		{
			//Lightning Seeds
			float h = hash(float2(sqrt(float(i)), floor((_Time.y + _CustomTime) * 7.0 + (float(i) / 10.0)) * float(i)));
			//ls.x = hash(h) * 3.0 - fmod(_Time.y, 3.0);
			// place the lightning in the center area
			ls.x = hash(h) * 0.1 - fmod(_Time.y + _CustomTime, 0.1);
			le.x = ls.x + sqrt(hash(sqrt(h + i))) - 0.5;

			if (h > 0.98) {
				f = min(f, lightning(ls, le, 1.0, uv));
			}
		}

		col = lerp(col, float4(0.2, 0.0, 0.9, 1.0), 1.0 - smoothstep(0.0, 0.5, pow(f / 2.0, 0.5) - uv.y / 40.0));
		// glow effect
		col = lerp(col, float4(0.9, 0.9, 0.9, 1.0), 1.0 - smoothstep(0.0, 0.2, pow(f / 2.0, 0.5) - uv.y / 40.0));

		if (vignetteUv.y > 0.7)
		{
			float dist = vignetteUv.y - 0.7;
			col = lerp(col, float4(0.0, 0.0, 0.0, 0.0), smoothstep(0.0, 0.3, dist));
			//col = float4(0.0, 0.0, 0.0, 0.0);
		}

		if (vignetteUv.y < 0.3)
		{
			float dist = 0.3 - vignetteUv.y;
			col = lerp(col, float4(0.0, 0.0, 0.0, 0.0), smoothstep(0.0, 0.3, dist));
		}

		fixed4 color = fixed4(col);
		return color;
	}
		ENDCG
	}
	}
}
