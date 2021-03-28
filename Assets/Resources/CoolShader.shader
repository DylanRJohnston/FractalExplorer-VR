Shader "Unlit/CoolShader"
{
  Properties
  {
    _MainTex ("Texture", 2D) = "white" {}
  }
  SubShader
  {
    Tags { "RenderType"="Opaque" }
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

      struct appdata
      {
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;
      };

      struct v2f
      {
        float2 uv : TEXCOORD0;
        float4 vertex : SV_POSITION;
        float3 rayOrigin : TEXCOORD1;
        float3 hitPosition : TEXCOORD2;
      };

      sampler2D _MainTex;
      float4 _MainTex_ST;

      v2f vert (appdata v)
      {
        v2f o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        o.rayOrigin = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
        o.hitPosition = v.vertex;
        return o;
      }

      float getDistanceToScene(float3 p, out float4 resColor)
      {
        float3 w = p;
        float m = dot(w,w);

        float4 trap = float4(abs(w),m);
        float dz = 1.0;
        
        for(int i=0; i<15; i++)
        { 
          float power = 8;

          dz = 8 * pow(m, 3.5) * dz + 1;

          float r = length(w);
          float b = power * acos(w.y / r) + _Time.y;
          float a = power * atan2(w.x, w.z);
          w = p + pow(r, 8) * float3(sin(b) * sin(a), cos(b), sin(b) * cos(a));
          
          trap = min(trap, float4(abs(w), m));

          m = dot(w,w);
          if( m > 256.0 ) break;
        }

        resColor = float4(m, trap.yzw);

        // distance estimation (through the Hubbard-Douady potential)
        return 0.25 * log(m) * sqrt(m) / dz;
      }

      float2 Raymarch(float3 rayOrigin, float3 rayDirection, out float4 resColor) {
        float rayLength = 0.0;
        
        int steps;
        for (steps = 0; steps < MAX_STEPS; steps++) {
          float3 p = rayOrigin + rayLength * rayDirection;
          float distanceToScene = getDistanceToScene(p, resColor);
          
          rayLength += distanceToScene;
          
          if (distanceToScene < MIN_SURFACE_DISTANCE) break;
          if (rayLength > MAX_DIST) break;
        }

        return float2(rayLength, steps);
      }

      // float3 GetNormal(float3 p) {
      //   float epsilon = 0.001;

      //   float x = getDistanceToScene(float3(p.x+epsilon,p.y,p.z)) - getDistanceToScene(float3(p.x-epsilon,p.y,p.z));
      //   float y = getDistanceToScene(float3(p.x,p.y+epsilon,p.z)) - getDistanceToScene(float3(p.x,p.y-epsilon,p.z));
      //   float z = getDistanceToScene(float3(p.x,p.y,p.z+epsilon)) - getDistanceToScene(float3(p.x,p.y,p.z-epsilon));

      //   return normalize(float3(x,y,z));
      // }

      fixed4 frag (v2f i) : SV_Target
      {
        float3 rayOrigin = i.rayOrigin;
        float3 rayDirection = normalize(i.hitPosition - i.rayOrigin);
        
        float4 col = 1;
        float4 trap = 0;
        float2 output = Raymarch(rayOrigin * 2.5, rayDirection, trap);
        float distance = output.x;
        float steps = output.y;

        col = steps / MAX_STEPS;    


        // if (distance > MAX_DIST) discard;
        
        // float3 p = rayOrigin + rayDirection * distance;
        // float3 normal = GetNormal(p);

        // float colourA = saturate(dot(normal * 0.5 + 0.5, float3(1.0, 0, 0)));
        // float colourB = saturate(esca)

        return col;
      }
      ENDCG
    }
  }
}
