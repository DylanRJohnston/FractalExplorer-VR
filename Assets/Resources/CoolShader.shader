Shader "Unlit/CoolShader"
{
  Properties
  {
    _Power ("Power", Range(0.1, 4.0)) = 1.0
    _Darkness ("Darkness", Float) = 100
    _BaseColor ("BaseColor", Color) = (1.0, 1.0, 1.0, 1.0)
    _IterationColorLow ("IterationColorLow", Color) = (1.0, 1.0, 1.0, 1.0)
    _IterationColorHigh ("IterationColorHigh", Color) = (1.0, 1.0, 1.0, 1.0)
    _LightDirection ("Light Direction", Vector) = (1.0, 1.0, 1.0)
    _JuliaParams ("Julia Params", Vector) = (1.0, 1.0, 1.0)
  }
  SubShader
  {
    Tags { "RenderType" = "Opaque" }
    Cull Front
    ZTest Off
    ZWrite On
    LOD 100

    Pass
    {
      CGPROGRAM

      #pragma vertex vert
      #pragma fragment frag

      #include "UnityCG.cginc"

      #define MAX_STEPS 50
      #define MAX_DIST 100
      #define MIN_SURFACE_DISTANCE 5e-4

      uniform float _Power;
      uniform float _Darkness;
      uniform float4  _BaseColor;
      uniform float4 _IterationColorLow;
      uniform float4 _IterationColorHigh;
      uniform float3 _JuliaParams;

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
        float3 lightDirection: TEXCOORD3;
      };

      sampler2D _MainTex;
      float4 _MainTex_ST;

      v2f vert(appdata v)
      {
        v2f o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        o.rayOrigin = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
        o.lightDirection = _LightDirection;
        o.hitPosition = v.vertex;

        return o;
      }

      // float2 distanceToScene(float3 p)
      // {
        //   float3 w = p;
        //   float m = dot(w, w);

        //   float dz = 1.0;
        
        //   int i = 0;
        //   for (i = 0; i < 20; i++)
        //   {
          //     float power = 8;

          //     dz = 8 * pow(m, (3.5)) * dz + 1;

          //     float r = length(w);
          //     float theta = power * acos(w.y / r) + _Time.y;
          //     float phi = power * atan2(w.x, w.z);
          //     w = pow(r, 8) * float3(sin(theta) * sin(phi), cos(theta), sin(theta) * cos(phi)) + _JuliaParams;
          

          //     m = dot(w, w);
          //     if (m > 256.0) break;
          //   }

          //   return float2(abs(0.25 * log(m) * sqrt(m) / dz), i);
          // }

          float2 distanceToScene(float3 p)
          {
            float3 orbit = p;
            float dz = 1.0;

            int i = 0;
            for (i = 0; i < 10; i++)
            {
              float radius = length(orbit);
              float theta = 8.0 * acos(orbit.z / radius) + _Time.y;
              float phi = 8.0 * atan2(orbit.y, orbit.x);

              dz = 8.0 * pow(radius, 7) * dz;

              orbit = p + pow(radius, 8) * float3(sin(theta) * cos(phi), sin(theta) * sin(phi), cos(theta));

              if (dot(orbit, orbit) > 4.0) break;
            }

            float z = length(orbit);

            return float2(0.5 * z * log(z) / dz, i);
          }

          float3 Raymarch(float3 rayOrigin, float3 rayDirection)
          {
            float rayLength = 0.0;
            float iteration = 0;
            
            int steps;
            for (steps = 0; steps < MAX_STEPS; steps++)
            {
              float3 p = rayOrigin + rayLength * rayDirection;
              float2 output = distanceToScene(p);

              iteration = output.y;
              rayLength += output.x;
              
              if (output.x < MIN_SURFACE_DISTANCE) break;
              if (rayLength > MAX_DIST) break;
            }

            return float3(rayLength, steps, iteration);
          }

          float3 normalEstimation(float3 pos)
          {
            float dist = distanceToScene(pos).x;
            float3 xDir = float3(dist, 0, 0);
            float3 yDir = float3(0, dist, 0);
            float3 zDir = float3(0, 0, dist);

            float3 foo = float3(distanceToScene(pos + xDir).x, distanceToScene(pos + yDir).x, distanceToScene(pos + zDir).x);

            return normalize(foo - float3(dist, dist, dist));
          }

          struct output
          {
            fixed4 color;
            float depth;
          };


          output frag(v2f i): SV_Target
          {
            float3 rayOrigin = i.rayOrigin * 2.5;
            float3 rayDirection = normalize(i.hitPosition * 2.5 - i.rayOrigin * 2.5);
            

            // _JuliaParams = float3(0.6 * sin(0.5 * _Time.y), 0.6 * cos(0.784 * _Time.y - 1.203), 0.6 * sin(_Time.y * 0.439485));
            
            // float4 result = lerp(float4(51, 3, 20, 1), float4(16, 6, 28, 1), i.uv.y) / 255.0;
            output result;
            result.color = 0;

            float3 output = Raymarch(rayOrigin, rayDirection);

            float distance = output.x;
            float steps = output.y;
            float iteration = output.z;

            float3 pos = rayOrigin + rayDirection * distance;
            float4 clip_pos = mul(UNITY_MATRIX_VP, float4(pos, 1.0));
            result.depth = clip_pos.z / clip_pos.w;

            if (distance <= MAX_DIST)
            {
              float3 normal = normalEstimation(pos);

              float _baseColorMix = dot(normal * 0.5 + 0.5, i.lightDirection);

              float iterationColorMix = saturate(iteration / 10);

              float4 colourMix = lerp(_IterationColorLow, _IterationColorHigh, iterationColorMix);
              

              // float rim = steps / _Darkness;
              float rim = 1 - steps / _Darkness;
              
              result.color = (colourMix * iterationColorMix) * pow(rim, _Power);
              
              
              // result.color = float4(rim, rim, rim, 1.0);
            }
            return result;
          }
          ENDCG

        }
      }
    }