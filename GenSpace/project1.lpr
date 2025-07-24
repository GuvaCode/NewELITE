program SkyboxGenerator;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, CustApp, raylib, math;

type
  { TSkyboxApplication }
  TSkyboxApplication = class(TCustomApplication)
  protected
    procedure GenerateSpaceImage;

    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
  end;

{ TSkyboxApplication }

constructor TSkyboxApplication.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  InitWindow(800, 600, 'Генератор космического скайбокса');
  SetTargetFPS(60);
end;

procedure TSkyboxApplication.GenerateSpaceImage;
var
  Layer1: TImage;
  AlphaDust: array [0..1] of TImage;
  i, x, y, dustIndex, dustWidth, dustHeight: Integer;
  layerWidth, layerHeight: Integer;
  destRec, sourceRec: TRectangle;
  dustColor: TColor;
begin
  // 1. Создаем базовое изображение космоса
  layerWidth := 8192;
  layerHeight := 4096;
  Layer1 := GenImageColor(layerWidth, layerHeight, BLACK);

  // 2. Загружаем текстуры пыли
  AlphaDust[0] := LoadImage('data/space/nebula_1.png');
  AlphaDust[1] := LoadImage('data/space/nebula_2.png');

  // 3. Устанавливаем seed для воспроизводимости
  SetRandomSeed(1234);

  // 4. Генерация космической пыли
  for i := 0 to 50 do // Больше частиц для skybox
  begin
    dustIndex := GetRandomValue(0, 1);
    dustWidth := AlphaDust[dustIndex].width;
    dustHeight := AlphaDust[dustIndex].height;

    x := GetRandomValue(0, layerWidth - dustWidth);
    y := GetRandomValue(0, layerHeight - dustHeight);

    // Создаем цвет с оттенком синего/фиолетового
    dustColor := ColorFromHSV(GetRandomValue(220, 280), 0.7, 0.9);
    dustColor.a := GetRandomValue(150, 230);

    sourceRec := RectangleCreate(0, 0, dustWidth, dustHeight);
    destRec := RectangleCreate(x, y, dustWidth, dustHeight);

    ImageDraw(@Layer1, AlphaDust[dustIndex], sourceRec, destRec, dustColor);
  end;

  // 5. Сохраняем сгенерированное изображение
  ExportImage(Layer1, 'test.png');

  // 6. Очищаем память
  UnloadImage(Layer1);
  UnloadImage(AlphaDust[0]);
  UnloadImage(AlphaDust[1]);
end;


procedure TSkyboxApplication.DoRun;
begin
  // 1. Генерируем изображение космоса
  GenerateSpaceImage;

  // 2. Создаем skybox из сгенерированного изображения


  // 3. Показываем результат
  while not WindowShouldClose do
  begin
    BeginDrawing;
      ClearBackground(BLACK);
      DrawText('Skybox сгенерирован!', 100, 100, 40, GREEN);
      DrawText('Файлы: space_atlas.png и skybox_final.png', 100, 150, 20, WHITE);
    EndDrawing;
  end;

  Terminate;
end;

destructor TSkyboxApplication.Destroy;
begin
  CloseWindow;
  inherited Destroy;
end;

var
  Application: TSkyboxApplication;
begin
  Application := TSkyboxApplication.Create(nil);
  Application.Title := 'Генератор Skybox';
  Application.Run;
  Application.Free;
end.
