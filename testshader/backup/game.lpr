program RadarShaderExample;

uses
  raylib, math, sysutils;

const
  SCREEN_WIDTH = 800;
  SCREEN_HEIGHT = 600;
  SHADER_FILE = 'radar5.fs';
  MAX_BOGEYS = 32; // Должно соответствовать значению в шейдере
  NUM_BOGEY_COLORS = 8; // Количество цветов для объектов

type
  TBogeyData = record
    center: array [0..1] of Single;  // vec2
    xDev: Single;
    yDev: Single;
    speed: Single;
    tOffset: Single;
    colorIndex: Integer;
  end;

var
  Shader: TShader;
  TimeLoc, ResolutionLoc, BogeysCountLoc: Integer;
  BogeysLoc: array[0..MAX_BOGEYS-1] of record
    center, xDev, yDev, speed, tOffset, colorIndex: Integer;
  end;
  Time: Single;
  Target: TRenderTexture2D;
  resolution: array [0..2] of Single;
  Bogeys: array[0..MAX_BOGEYS-1] of TBogeyData;
  BogeysCount: Integer;

procedure AddBogey(centerX, centerY, xDev, yDev, speed, tOffset: Single; colorIndex: Integer);
begin
  if BogeysCount < MAX_BOGEYS then
  begin
    Bogeys[BogeysCount].center[0] := centerX;
    Bogeys[BogeysCount].center[1] := centerY;
    Bogeys[BogeysCount].xDev := xDev;
    Bogeys[BogeysCount].yDev := yDev;
    Bogeys[BogeysCount].speed := speed;
    Bogeys[BogeysCount].tOffset := tOffset;
    Bogeys[BogeysCount].colorIndex := colorIndex;
    Inc(BogeysCount);
  end;
end;

procedure UpdateShaderBogeys;
var
  i: Integer;
  center: array[0..1] of Single;
begin
  // Установка количества объектов
  SetShaderValue(Shader, BogeysCountLoc, @BogeysCount, SHADER_UNIFORM_INT);

  // Передача данных об объектах
  for i := 0 to BogeysCount-1 do
  begin
    // Центр объекта
    center[0] := Bogeys[i].center[0];
    center[1] := Bogeys[i].center[0];
    SetShaderValue(Shader, BogeysLoc[i].center, @center, SHADER_UNIFORM_VEC2);

    // Остальные параметры
    SetShaderValue(Shader, BogeysLoc[i].xDev, @Bogeys[i].xDev, SHADER_UNIFORM_FLOAT);
    SetShaderValue(Shader, BogeysLoc[i].yDev, @Bogeys[i].yDev, SHADER_UNIFORM_FLOAT);
    SetShaderValue(Shader, BogeysLoc[i].speed, @Bogeys[i].speed, SHADER_UNIFORM_FLOAT);
    SetShaderValue(Shader, BogeysLoc[i].tOffset, @Bogeys[i].tOffset, SHADER_UNIFORM_FLOAT);
    SetShaderValue(Shader, BogeysLoc[i].colorIndex, @Bogeys[i].colorIndex, SHADER_UNIFORM_INT);
  end;
end;

procedure InitializeBogeys;
var
  i: Integer;
  angle: Single;
begin
  BogeysCount := 0;
  Randomize;

  // Создаем 8 объектов по кругу с разными цветами
  for i := 0 to 7 do
  begin
    angle := i * 2 * PI / 8;
    AddBogey(
      Cos(angle) * 0.5,    // centerX
      Sin(angle) * 0.5,    // centerY
      0.1 + Random * 0.2,  // xDev
      0.1 + Random * 0.2,  // yDev
      0.2 + Random * 0.3,  // speed
      Random * 10,         // tOffset
      i mod NUM_BOGEY_COLORS // colorIndex
    );
  end;

  // Добавляем несколько случайных объектов
  for i := 0 to 3 do
  begin
    AddBogey(
      Random * 1.6 - 0.8,  // centerX (-0.8..0.8)
      Random * 1.6 - 0.8,  // centerY (-0.8..0.8)
      Random * 0.3,        // xDev
      Random * 0.3,        // yDev
      0.1 + Random * 0.4,  // speed
      Random * 10,         // tOffset
      Random(NUM_BOGEY_COLORS) // colorIndex
    );
  end;
end;

procedure InitializeShaderLocations;
var
  i: Integer;
  uniformName: string;
begin
  // Получение location uniform-переменных
  TimeLoc := GetShaderLocation(Shader, 'iTime');
  ResolutionLoc := GetShaderLocation(Shader, 'iResolution');
  BogeysCountLoc := GetShaderLocation(Shader, 'bogeysCount');

  // Получаем location для каждого элемента массива bogeys
  for i := 0 to MAX_BOGEYS-1 do
  begin
    uniformName := 'bogeys[' + IntToStr(i) + '].center';
    BogeysLoc[i].center := GetShaderLocation(Shader, PChar(uniformName));

    uniformName := 'bogeys[' + IntToStr(i) + '].xDev';
    BogeysLoc[i].xDev := GetShaderLocation(Shader, PChar(uniformName));

    uniformName := 'bogeys[' + IntToStr(i) + '].yDev';
    BogeysLoc[i].yDev := GetShaderLocation(Shader, PChar(uniformName));

    uniformName := 'bogeys[' + IntToStr(i) + '].speed';
    BogeysLoc[i].speed := GetShaderLocation(Shader, PChar(uniformName));

    uniformName := 'bogeys[' + IntToStr(i) + '].tOffset';
    BogeysLoc[i].tOffset := GetShaderLocation(Shader, PChar(uniformName));

    uniformName := 'bogeys[' + IntToStr(i) + '].colorIndex';
    BogeysLoc[i].colorIndex := GetShaderLocation(Shader, PChar(uniformName));
  end;
end;

begin
  // Инициализация окна
  InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, 'Raylib Radar Shader with Colored Bogeys');
  SetTargetFPS(60);

  // Загрузка шейдера
  Shader := LoadShader(nil, SHADER_FILE);

  // Установка значения разрешения
  resolution[0] := SCREEN_WIDTH;
  resolution[1] := SCREEN_HEIGHT;
  resolution[2] := 0;
  SetShaderValue(Shader, GetShaderLocation(Shader, 'iResolution'), @resolution, SHADER_UNIFORM_VEC3);

  // Инициализация locations uniform-переменных
  InitializeShaderLocations;

  // Инициализация объектов радара
  InitializeBogeys;

  // Создаем текстуру для рендеринга
  Target := LoadRenderTexture(SCREEN_WIDTH, SCREEN_HEIGHT);

  // Основной цикл
  while not WindowShouldClose() do
  begin
    // Обновление времени
    Time := GetTime();
    SetShaderValue(Shader, TimeLoc, @Time, SHADER_UNIFORM_FLOAT);

    // Обновление данных об объектах в шейдере
    UpdateShaderBogeys;

    // Начинаем рендеринг в текстуру
    BeginTextureMode(Target);
      ClearBackground(BLACK);
      DrawRectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, WHITE);
    EndTextureMode();

    // Рендеринг на экран
    BeginDrawing();
      ClearBackground(BLACK);

      // Применяем шейдер к текстуре
      BeginShaderMode(Shader);
        DrawTextureRec(Target.texture,
                      RectangleCreate(0, 0, SCREEN_WIDTH, -SCREEN_HEIGHT),
                      Vector2Create(0, 0), WHITE);
      EndShaderMode();

      // Выводим информацию
      DrawFPS(10, 10);
      DrawText('Radar with Colored Bogeys', 10, 40, 20, GREEN);
      DrawText(PChar('Objects: ' + IntToStr(BogeysCount)), 10, 70, 20, GREEN);
    EndDrawing();
  end;

  // Очистка ресурсов
  UnloadShader(Shader);
  UnloadRenderTexture(Target);
  CloseWindow();
end.
