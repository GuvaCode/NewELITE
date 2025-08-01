// Free pascal like elite games

program fplite;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  CThreads,
  {$ENDIF}
  Classes, SysUtils, CustApp, RayLib, ScreenManager, ScreenSpace, SpaceEngine,
  r3d, radarshader;

const
  // константы для экранов
  //SCREEN_MAINMENU = $0001;
  SCREEN_SPACE = $0002;

type
  { TRayApplication }
  TRayApplication = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    FScreenManager: TScreenManager; // Менеджер экранов
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
  end;

  const AppTitle = 'raylib - basic window';

{ TRayApplication }

constructor TRayApplication.Create(TheOwner: TComponent);
//var light: TR3D_Light;
begin
  inherited Create(TheOwner);

  InitWindow({GetScreenWidth, GetScreenHeight, }800,600, AppTitle); // for window settings, look at example - window flags
  R3D_Init(800,600, 0 {or R3D_FLAG_TRANSPARENT_SORTING});
 // SetTargetFPS(60); // Set our game to run at 60 frames-per-second
   //SetWindowState({FLAG_MSAA_4X_HINT or FLAG_FULLSCREEN_MODE or});
    // Configure rendering effects
    R3D_SetBackgroundColor(BLACK);
    R3D_SetAmbientColor(DARKGRAY);
    R3D_SetSSAO(True);
    R3D_SetSSAORadius(2.0);
    R3D_SetBloomIntensity(0.1);
    R3D_SetBloomMode(R3D_BLOOM_MIX);
    R3D_SetTonemapMode(R3D_TONEMAP_ACES);
    R3D_SetModelImportScale(0.01);


  //light := R3D_CreateLight(R3D_LIGHT_DIR);

  //R3D_LightLookAt(light, Vector3Create( 0, 10, 5 ), Vector3Create(0,0,0));

  //R3D_SetLightActive(light, true);
  //R3D_EnableShadow(light, 4096);

  FScreenManager := TScreenManager.Create;
  //FScreenManager.Add(Tgamescreen_mainmenu, SCREEN_MAINMENU);
  FScreenManager.Add(TScreenSpace, SCREEN_SPACE);
  FScreenManager.ShowScreen(SCREEN_SPACE); //Show Screen

end;

procedure TRayApplication.DoRun;
begin

  while (not WindowShouldClose) do // Detect window close button or ESC key
  begin
    // Update your variables here
    FScreenManager.Update(GetFrameTime); // Update screen manager
    // Draw
   // BeginDrawing();
     // ClearBackground( ColorCreate(32, 32, 64, 255) );
      FScreenManager.Render; // Render screen manager
    //EndDrawing();
  end;

  // Stop program loop
  Terminate;
end;

destructor TRayApplication.Destroy;
begin
  FScreenManager.Free;
  // De-Initialization
  CloseWindow(); // Close window and OpenGL context

  // Show trace log messages (LOG_DEBUG, LOG_INFO, LOG_WARNING, LOG_ERROR...)
  TraceLog(LOG_INFO, 'your first window is close and destroy');

  inherited Destroy;
end;

var
  Application: TRayApplication;
begin
  Application:=TRayApplication.Create(nil);
  Application.Title:=AppTitle;
  Application.Run;
  Application.Free;
end.

