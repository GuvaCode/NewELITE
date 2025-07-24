program SphericalRadarExample;

uses
  raylib, math;

const
  SCREEN_WIDTH = 800;
  SCREEN_HEIGHT = 600;
  SHADER_FILE = 'sphere.fs';
  MAX_BOGEYS = 32;
  NUM_BOGEY_COLORS = 8;

type
  TBogeyData = record
    position: array [0..2] of Single; // x, y, z
    colorIndex: Integer;
    size: Single;
  end;

  TPlayer = record
    position: array [0..2] of Single;
    rotation: array [0..2] of Single; // pitch, yaw, roll
  end;

var
  Shader: TShader;
  TimeLoc, ResolutionLoc, BogeysCountLoc: Integer;
  PlayerPosLoc, PlayerRotLoc: Integer;
  BogeysLoc: array[0..MAX_BOGEYS-1] of record
    position, colorIndex, size: Integer;
  end;
  Time: Single;
  Target: TRenderTexture2D;
  resolution: array [0..2] of Single;
  Bogeys: array[0..MAX_BOGEYS-1] of TBogeyData;
  BogeysCount: Integer;
  Player: TPlayer;
  LastUpdate: single;

procedure AddBogey(x, y, z, size: Single; colorIndex: Integer);
begin
  if BogeysCount < MAX_BOGEYS then
  begin
    Bogeys[BogeysCount].position[0] := x;
    Bogeys[BogeysCount].position[1] := y;
    Bogeys[BogeysCount].position[2] := z;
    Bogeys[BogeysCount].colorIndex := colorIndex;
    Bogeys[BogeysCount].size := size;
    Inc(BogeysCount);
  end;
end;

procedure UpdatePlayerPosition(x, y, z: Single);
begin
  Player.position[0] := x;
  Player.position[1] := y;
  Player.position[2] := z;
  SetShaderValue(Shader, PlayerPosLoc, @Player.position, SHADER_UNIFORM_VEC3);
end;

procedure UpdatePlayerRotation(pitch, yaw, roll: Single);
begin
  Player.rotation[0] := pitch;
  Player.rotation[1] := yaw;
  Player.rotation[2] := roll;
  SetShaderValue(Shader, PlayerRotLoc, @Player.rotation, SHADER_UNIFORM_VEC3);
end;

procedure InitializeBogeys;
var
  i: Integer;
  angle: Single;
begin
  BogeysCount := 0;
  Randomize;

  // Создаем объекты на сфере
  for i := 0 to 15 do
  begin
    angle := i * 2 * PI / 16;
    AddBogey(
      Cos(angle) * 10,       // x
      0.5 + Sin(Time * 0.1 + angle) * 3, // y
      Sin(angle) * 10,       // z
      0.03 + Random * 0.02,  // size
      i mod NUM_BOGEY_COLORS // colorIndex
    );
  end;
end;

begin
  InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, '3D Spherical Radar');
  SetTargetFPS(60);

  // Инициализация шейдера
  Shader := LoadShader(nil, SHADER_FILE);

  // Установка разрешения
  resolution[0] := SCREEN_WIDTH;
  resolution[1] := SCREEN_HEIGHT;
  resolution[2] := 0;
  SetShaderValue(Shader, GetShaderLocation(Shader, 'iResolution'), @resolution, SHADER_UNIFORM_VEC3);

  // Получение location uniform-переменных
  TimeLoc := GetShaderLocation(Shader, 'iTime');
  PlayerPosLoc := GetShaderLocation(Shader, 'playerPosition');
  PlayerRotLoc := GetShaderLocation(Shader, 'playerRotation');
  BogeysCountLoc := GetShaderLocation(Shader, 'bogeysCount');

  // Инициализация игрока
  UpdatePlayerPosition(0, 0, 0);
  UpdatePlayerRotation(0, 0, 0);

  // Инициализация объектов
  InitializeBogeys;

  Target := LoadRenderTexture(SCREEN_WIDTH, SCREEN_HEIGHT);

  while not WindowShouldClose() do
begin
  // Обновление
  Time := GetTime();

  // Оптимизированное обновление uniform-переменных
  // LastUpdate: Single = 0;
  if (Time - LastUpdate > 0.016) then // ~60Hz
  begin
    SetShaderValue(Shader, TimeLoc, @Time, SHADER_UNIFORM_FLOAT);
    UpdatePlayerRotation(sin(Time * 0.3) * 0.2, Time * 0.5, 0.0);
    LastUpdate := Time;
  end;

  // Рендеринг
  BeginDrawing();
    ClearBackground(BLACK);

    // Рендеринг радара
    BeginShaderMode(Shader);
      DrawRectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, WHITE);
    EndShaderMode();

    // Интерфейс поверх
    DrawFPS(10, 10);
    DrawText('Radar Active', 10, 40, 20, LIME);
    DrawText(TextFormat('Objects: %d', BogeysCount, 10, 100, 20, GREEN);
    // Отладочная информация
    if IsKeyDown(KEY_F1) then
    begin
     // DrawText(TextFormat('FPS: %d', [GetFPS()]), 10, 70, 20, GREEN);
      //DrawText(TextFormat('Objects: %d', [BogeysCount]), 10, 100, 20, GREEN);
    end;
  EndDrawing();
end;

  UnloadShader(Shader);
  UnloadRenderTexture(Target);
  CloseWindow();
end.
