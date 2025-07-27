unit Unit1;

{$mode objfpc}{$H+}

interface

const
  SHADER =
  '#version 330' + #10 +
  '' + #10 +
  '// Автоматически сконвертировано из ShaderToy в raylib формат.' + #10 +
  '' + #10 +
  '// Входные переменные от raylib' + #10 +
  'in vec2 fragCoord;' + #10 +
  'out vec4 fragColor;' + #10 +
  '' + #10 +
  '// Uniform-переменные ShaderToy' + #10 +
  'uniform float iTime;        // shader playback time (s)' + #10 +
  'uniform vec3 iResolution;   // viewport resolution (pixels)' + #10 +
  '' + #10 +
  '#define green vec3(0.0,.3,0.6)' + #10 +
  '' + #10 +
  '// returns a vec3 color from every pixel requested.' + #10 +
  '// Generates a BnW Ping on normalized 2d coordinate system' + #10 +
  'vec3 RadarPing(in vec2 uv, in vec2 center, in float innerTail,' + #10 +
  '               in float frontierBorder, in float timeResetSeconds,' + #10 +
  '               in float radarPingSpeed, in float fadeDistance, float t)' + #10 +
  '{' + #10 +
  '    vec2 diff = center-uv;' + #10 +
  '    float r = length(diff);' + #10 +
  '    float time = mod(t, timeResetSeconds) * radarPingSpeed;' + #10 +
  '' + #10 +
  '    float circle;' + #10 +
  '    // r is the distance to the center.' + #10 +
  '    // circle = BipCenter---//---innerTail---time---frontierBorder' + #10 +
  '    //illustration' + #10 +
  '    //https://sketch.io/render/sk-14b54f90080084bad1602f81cadd4d07.jpeg' + #10 +
  '    circle += smoothstep(time - innerTail, time, r) * smoothstep(time + frontierBorder,time, r);' + #10 +
  '	circle *= smoothstep(fadeDistance, 0.0, r); // fade to 0 after fadeDistance' + #10 +
  '' + #10 +
  '    return vec3(circle);' + #10 +
  '}' + #10 +
  '' + #10 +
  'void mainImage( out vec4 fragColor, in vec2 fragCoord )' + #10 +
  '{' + #10 +
  '    //normalize coordinates' + #10 +
  '    vec2 uv = fragCoord.xy / iResolution.xy; //move coordinates to 0..1' + #10 +
  '    uv = uv.xy*2.; // translate to the center' + #10 +
  '    uv += vec2(-1.0, -1.0);' + #10 +
  '    uv.x *= iResolution.x/iResolution.y; //correct the aspect ratio' + #10 +
  '' + #10 +
  '	vec3 color;' + #10 +
  '    // generate some radar pings' + #10 +
  '    float fadeDistance = 0.8;' + #10 +
  '    float resetTimeSec = 3.0;' + #10 +
  '    float radarPingSpeed = 0.2;' + #10 +
  '    vec2 greenPing = vec2(0.0, 0.0);' + #10 +
  '    color += RadarPing(uv, greenPing, 0.08, 0.00025, resetTimeSec, radarPingSpeed, fadeDistance, iTime) * green;' + #10 +
  '    color += RadarPing(uv, greenPing, 0.08, 0.00025, resetTimeSec, radarPingSpeed, fadeDistance, iTime + 1.) * green;' + #10 +
  '    color += RadarPing(uv, greenPing, 0.08, 0.00025, resetTimeSec, radarPingSpeed, fadeDistance, iTime + 2.) * green;' + #10 +
  '    //return the new color' + #10 +
  '	fragColor = vec4(color,1.0);' + #10 +
  '}' + #10 +
  '' + #10 +
  '' + #10 +
  '// Главная функция, которую вызывает raylib' + #10 +
  'void main()' + #10 +
  '{' + #10 +
  '    // Вызываем оригинальную функцию из ShaderToy с нормализованными координатами' + #10 +
  '    mainImage(fragColor, gl_FragCoord.xy);' + #10 +
  '}'
  ;

implementation

end.



