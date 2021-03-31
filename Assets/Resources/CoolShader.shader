Shader "Unlit/CoolShader"
{
  Properties
  {
    _Power ("Power", Range(0.1, 4.0)) = 1.0
    _Darkness ("Darkness", Float) = 100
    _ColorA ("ColorA", Color) = (1.0, 1.0, 1.0, 1.0)
    _ColorB ("ColorB", Color) = (1.0, 1.0, 1.0, 1.0)
    _ColorX ("ColorX", Color) = (1.0, 1.0, 1.0, 1.0)
    _ColorY ("ColorY", Color) = (1.0, 1.0, 1.0, 1.0)
    _ColorZ ("ColorZ", Color) = (1.0, 1.0, 1.0, 1.0)
    _ColorW ("ColorW", Color) = (1.0, 1.0, 1.0, 1.0)
    _LightDirection ("Light Direction", Vector) = (1.0, 1.0, 1.0)
  }
  SubShader
  {
    Tags { "RenderType" = "Opaque" }
    Cull Off
    LOD 100

    Pass
    {
      CGPROGRAM

      #pragma vertex vert
      #pragma fragment frag

      #include "UnityCG.cginc"

      #define MAX_STEPS 50
      #define MAX_DIST 100
      #define MIN_SURFACE_DISTANCE 1e-3

      uniform float _Power;
      uniform float _Darkness;
      uniform float4 _ColorA;
      uniform float4 _ColorB;
      uniform float4 _ColorX;
      uniform float4 _ColorY;
      uniform float4 _ColorZ;
      uniform float4 _ColorW;
      uniform float4 _LightDirection;

      struct appdata
      {
        float4 vertex: POSITION;
        float2 uv: TEXCOORD0;
      };

      struct v2f
      {
        float2 uv: TEXCOORD0;
        float4 vertex: SV_POSITION;
        float3 rayOrigin: TEXCOORD1;
        float3 hitPosition: TEXCOORD2;
      };

      sampler2D _MainTex;
      float4 _MainTex_ST;

      v2f vert(appdata v)
      {
        v2f o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        o.rayOrigin = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
        o.hitPosition = v.vertex;
        return o;
      }

      float2 distanceToScene(float3 p, out float4 resColor)
      {
        float3 w = p;
        float m = dot(w, w);

        float4 trap = float4(abs(w), m);
        float dz = 1.0;
        
        int i = 0;
        for (i = 0; i < 15; i++)
        {
          float power = 8;

          dz = 8 * pow(m, (3.5)) * dz + 1;

          float r = length(w);
          float theta = power * acos(w.y / r) + _Time.y;
          float phi = power * atan2(w.x, w.z);
          w = p + pow(r, 8) * float3(sin(theta) * sin(phi), cos(theta), sin(theta) * cos(phi));
          
          trap = min(trap, float4(abs(w), m));

          m = dot(w, w);
          if (m > 256.0) break;
        }

        resColor = trap;

        return float2(0.25 * log(m) * sqrt(m) / dz, i);
      }

      float3 Raymarch(float3 rayOrigin, float3 rayDirection, out float4 resColor)
      {
        float rayLength = 0.0;
        float iteration = 0;
        
        int steps;
        for (steps = 0; steps < MAX_STEPS; steps++)
        {
          float3 p = rayOrigin + rayLength * rayDirection;
          float2 output = distanceToScene(p, resColor);

          iteration = output.y;
          rayLength += output.x;
          
          if (output.x < MIN_SURFACE_DISTANCE) break;
          if (rayLength > MAX_DIST) break;
        }

        return float3(rayLength, steps, iteration);
      }

      float3 normalEstimation(float3 pos)
      {
        float4 resColor = 0;

        float dist = distanceToScene(pos, resColor);
        float3 xDir = float3(dist, 0, 0);
        float3 yDir = float3(0, dist, 0);
        float3 zDir = float3(0, 0, dist);

        float3 foo = float3(distanceToScene(pos + xDir, resColor).x, distanceToScene(pos + yDir, resColor).x, distanceToScene(pos + zDir, resColor).x);

        return normalize(foo - float3(dist, dist, dist));
      }


      fixed4 frag(v2f i): SV_Target
      {
        float3 rayOrigin = i.rayOrigin * 2.5;
        float3 rayDirection = normalize(i.hitPosition * 2.5 - i.rayOrigin * 2.5);
        
        // float4 result = lerp(float4(51, 3, 20, 1), float4(16, 6, 28, 1), i.uv.y) / 255.0;
        float4 result = 0;
        
        float4 col = 0;
        float3 output = Raymarch(rayOrigin, rayDirection, col);

        float distance = output.x;
        float steps = output.y;
        float iteration = output.z;

        if (distance < MAX_DIST)
        {
          float3 normal = normalEstimation(rayOrigin + rayDirection * distance);

          float2 colorMix = float2(dot(normal * 0.5 + 0.5, _LightDirection.xyz), iteration);

          colorMix = normalize(colorMix);


          float4 colourMix = saturate(
            colorMix.x * _ColorA
            + colorMix.y * _ColorB
            // + col.x * _ColorX
            // + col.y * _ColorY
            // + col.z * _ColorZ
            // + col.w * _ColorW
          );

          float rim = steps / _Darkness;
          
          result = saturate(colourMix * pow(rim, _Power));
        }
        
        return result;
      }
      ENDCG

    }
  }
}