unit ScreenSpace;

{$mode ObjFPC}{$H+}
{.$define DEBUG}


interface

uses
  RayLib, RayMath, Classes, SysUtils, ScreenManager, SpaceEngine,DigestMath, r3d, Math;

type

  { TSpaceShip }

  TSpaceShip = class(TSpaceActor)
  private
    ShipModel: TR3D_Model;
  public
    constructor Create(const AParent: TSpaceEngine); override;
    procedure Update(const DeltaTime: Single); override;
  end;

  { TAiShip }

  TAiShip = class(TSpaceActor)
  private
    ShipModel: TR3D_Model;
    FOrbitRadius: Single;
    FOrbitHeight: Single;
    FOrbitSpeed: Single;
    FOrbitAngleChangeTimer: Single;
    FTargetOrbitHeight: Single;
    FOrbitChangeTimer: Single;
    FTargetOrbitRadius: Single;
  public
    constructor Create(const AParent: TSpaceEngine); override;
    procedure Update(const DeltaTime: Single); override;
  end;



  { TSpaceGate }
  TSpaceGate = class(TSpaceActor)
  private
    Ring: TSpaceActor;
    BodyModel, RingModel: TR3D_Model;
  public
    constructor Create(const AParent: TSpaceEngine); override;
    procedure Update(const DeltaTime: Single); override;
  end;


  { TScreenSpace }

  TScreenSpace = class(TGameScreen)
  private
    Engine: TSpaceEngine;
    Ship: TSpaceShip;
    AiShip: array[0..3] of TAiShip;
    Gate: TSpaceGate;
    Camera: TSpaceCamera;

  public
    procedure Init; override; // Init game screen
    procedure Shutdown; override; // Shutdown the game screen
    procedure Update(MoveCount: Single); override; // Update the game screen
    procedure Render; override;  // Render the game screen
    procedure Show; override;  // Celled when the screen is showned
    procedure Hide; override; // Celled when the screen is hidden
  end;

var Material: TR3D_Material;

implementation

{ TSpaceShip }

constructor TSpaceShip.Create(const AParent: TSpaceEngine);
begin
  inherited Create(AParent);
  R3D_SetModelImportScale(0.05);
  ShipModel := R3D_LoadModel(('data' + '/models/ship.glb'));

  ColliderType:= ctBox;
  ActorModel := ShipModel;
  DoCollision := True;
  AlignToHorizon:=False;
  MaxSpeed:=20;

end;

procedure TSpaceShip.Update(const DeltaTime: Single);
begin
  inherited Update(DeltaTime);
  // Визуальные эффекты двигателя
  ActorModel.materials[1].emission.color := GREEN;
  ActorModel.materials[1].emission.energy := Clamp(Abs(Self.CurrentSpeed)/MaxSpeed * 300.0, 30.0, 300.0);
  ActorModel.materials[1].albedo.color := BLACK;
end;

{ TAiShip }

constructor TAiShip.Create(const AParent: TSpaceEngine);
begin
  inherited Create(AParent);
  R3D_SetModelImportScale(0.05);


  ShipModel := R3D_LoadModel(('data' + '/models/ship.glb'));

  ColliderType:= ctBox;
  ActorModel := ShipModel;
  DoCollision := True;
  AlignToHorizon:=False;
  ///MaxSpeed:=2;
  ShipType := Pirate;
end;

procedure TAiShip.Update(const DeltaTime: Single);
var
  Gate: TSpaceGate;
  OrbitHeight: Single;
  Angle, Dist: Single;
  TargetPos, OrbitNormal, RightVector, ToTarget, Dir: TVector3;
  DistanceToTarget: Single;
  AvoidanceForce: TVector3;
  i: Integer;
begin
  inherited Update(DeltaTime);

  // Визуальные эффекты двигателя
  ActorModel.materials[1].emission.color := RED;
  ActorModel.materials[1].emission.energy := Clamp(Abs(Self.CurrentSpeed)/MaxSpeed * 300.0, 30.0, 300.0);
  ActorModel.materials[1].albedo.color := BLACK;

  // Инициализация параметров орбиты при первом вызове
  if FOrbitRadius = 0 then
  begin
    FOrbitRadius := 160 + Random(220);    // Случайный радиус 40-60
    FOrbitHeight := -100 + Random(100);    // Случайная высота 10-20
    FOrbitSpeed := 0.2 + Random * 0.2;  // Случайная скорость 0.2-0.4
    FTargetOrbitHeight := FOrbitHeight;
  end;

  // Поиск SpaceGate в сцене
  Gate := nil;
  for i := 0 to Engine.Count - 1 do
  begin
    if Engine.Items[i] is TSpaceGate then
    begin
      Gate := TSpaceGate(Engine.Items[i]);
      Break;
    end;
  end;

  if Gate = nil then
  begin
    // Если ворот нет, просто летим вперед
    InputForward := 0.5;
    Exit;
  end;

  // Плавное изменение высоты орбиты со временем
  FOrbitAngleChangeTimer += DeltaTime;
  if FOrbitAngleChangeTimer > 8.0 then
  begin
    FOrbitAngleChangeTimer := 0;
    FTargetOrbitHeight := 5 + Random(25); // Новая целевая высота 5-30
  end;
  OrbitHeight := SmoothDamp(FOrbitHeight, FTargetOrbitHeight, 0.3, DeltaTime);
  FOrbitHeight := OrbitHeight;

  // Вычисление позиции на орбите
  Angle := GetTime() * FOrbitSpeed;
  OrbitNormal := Vector3Create(0, 1, 0); // Нормаль орбиты (вертикальная)

  RightVector := Vector3Normalize(Vector3CrossProduct(OrbitNormal, Vector3Create(0, 0, 1)));
  TargetPos := Vector3Add(Gate.Position,
    Vector3Add(
      Vector3Scale(RightVector, FOrbitRadius * Cos(Angle)),
      Vector3Scale(Vector3Normalize(Vector3CrossProduct(RightVector, OrbitNormal)), FOrbitRadius * Sin(Angle)))
    );
  TargetPos.y := Gate.Position.y + OrbitHeight;

  // Избегание препятствий
  AvoidanceForce := Vector3Zero();
  for i := 0 to Engine.Count - 1 do
  begin
    if (Engine.Items[i] <> Self) and (Engine.Items[i] <> Gate) then
    begin
      Dist := Vector3Distance(Position, Engine.Items[i].Position);
      if Dist < 25 then
      begin
        Dir := Vector3Normalize(Vector3Subtract(Position, Engine.Items[i].Position));
        AvoidanceForce := Vector3Add(AvoidanceForce,
          Vector3Scale(Dir, 1.0 - (Dist / 25)));
      end;
    end;
  end;

  if Vector3Length(AvoidanceForce) > 0 then
  begin
    AvoidanceForce := Vector3Normalize(AvoidanceForce);
    TargetPos := Vector3Add(TargetPos, Vector3Scale(AvoidanceForce, 15));
  end;

  // Направление к цели
  ToTarget := Vector3Subtract(TargetPos, Position);
  DistanceToTarget := Vector3Length(ToTarget);

  // Поворот к цели
  RotationToVector(TargetPos, False, 0.2);

  // Управление скоростью
  if DistanceToTarget > FOrbitRadius * 0.4 then
  begin
    // Ускоряемся, если далеко от целевой позиции
    InputForward := Min(1.0, DistanceToTarget / FOrbitRadius)
  end
  else
  begin
    // Поддерживаем скорость на орбите
    InputForward := 0.6 + 0.2 * Sin(GetTime() * 2); // Легкие колебания скорости
  end;

  // Плавное изменение радиуса орбиты
  if FOrbitChangeTimer > 10.0 then
  begin
    FOrbitChangeTimer := 0;
    FTargetOrbitRadius := 30 + Random(40); // Новый радиус 30-70
  end;
  FOrbitChangeTimer += DeltaTime;
  FOrbitRadius := SmoothDamp(FOrbitRadius, FTargetOrbitRadius, 0.2, DeltaTime);
end;

{ TSpaceGate }

constructor TSpaceGate.Create(const AParent: TSpaceEngine);
begin

  inherited Create(AParent);
  R3D_SetModelImportScale(0.05);
  BodyModel := R3D_LoadModel(('data' + '/models/Gate_body.glb'));
  RingModel := R3D_LoadModel(('data' + '/models/Gate_ring.glb'));

  ShipType:=Station;
  Position := Vector3Create(10, - 100 , 100);
  ColliderType:= ctBox;
  ActorModel := BodyModel;
  DoCollision := True;
  AlignToHorizon:=False;
  MaxSpeed:=0;

  Ring := TSpaceActor.Create(AParent);
  Ring.Position := Self.Position;
  Ring.DoCollision :=False;
  Ring.ActorModel := RingModel;
  Ring.AlignToHorizon:=False;
  Ring.MaxSpeed:=0;

end;

procedure TSpaceGate.Update(const DeltaTime: Single);
const
  MinEnergy = 30;
  MaxEnergy = 70;
  PulseDuration = 1.0; // Полный цикл за 1 сек
var
  PulseFactor: Single;
begin
  inherited Update(DeltaTime);

   Ring.Position := Self.Position;
   Ring.RotateLocalEuler(Vector3Create(0, 1, 0), 30 * DeltaTime);

   // Плавное колебание с помощью Lerp
   PulseFactor := (Sin(GetTime() * (PI/PulseDuration)) + 1) * 0.5; // 0..1

   Ring.ActorModel.materials[1].emission.color := BLUE;
   Ring.ActorModel.materials[1].emission.energy := Lerp(MinEnergy, MaxEnergy, PulseFactor);
   Ring.ActorModel.materials[1].albedo.color := BLACK;
end;

{ TScreenSpace }



procedure TScreenSpace.Init;
var i: integer;
begin
  Engine := TSpaceEngine.Create;
  Engine.CrosshairFar.Create('data' + '/models/UI/crosshair2.gltf');
  Engine.CrosshairNear.Create('data' + '/models/UI/crosshair.gltf');
  Engine.LoadSkyBox('data' +'/skybox/planets/earthlike_planet_close.hdr', SQHigh, STPanorama);
  Engine.EnableSkybox;
  Engine.Light[0] := R3D_CreateLight(R3D_LIGHT_DIR);

  R3D_LightLookAt(Engine.Light[0], Vector3Create( 0, 10, 5 ), Vector3Create(0,0,0));
  R3D_SetLightActive(Engine.Light[0], true);
  R3D_EnableShadow(Engine.Light[0], 4096);



  Camera := TSpaceCamera.Create(True, 50);

  Ship := TSpaceShip.Create(Engine);
  Gate := TSpaceGate.Create(Engine);

  for i := 0 to 3 do
  begin
    AiShip[i] := TAiShip.Create(Engine);
    AiShip[i].MaxSpeed:= GetRandomValue(5,15);
  end;



  // При старте игры или активации корабля
  DisableCursor(); // Скрыть курсор
  SetMousePosition(GetScreenWidth div 2, GetScreenHeight div 2);

  Engine.Radar.Player := Ship;



  end;

procedure TScreenSpace.Shutdown;
begin
  Engine.Destroy;
  // R3D_UnloadModel(@ShipModel, true);
end;

procedure TScreenSpace.Update(MoveCount: Single);

begin
  Engine.Update(MoveCount, Ship.Position);

  Engine.ClearDeadActor;
  Engine.Collision;

  Engine.ApplyInputToShip(Ship, 0.5);

  Camera.FollowActor(Ship, MoveCount);

  Engine.CrosshairFar.PositionCrosshairOnActor(Ship, 20);
  Engine.CrosshairNear.PositionCrosshairOnActor(Ship, 15);
end;

procedure TScreenSpace.Render;
begin
  inherited Render;
  BeginDrawing();
    ClearBackground( ColorCreate(32, 32, 64, 255) );
    {$IFDEF DEBUG}
    Engine.Render(Camera,True,True,Ship.Velocity,False);
    DrawFPS(10,10);
    {$ELSE}
    Engine.Render(Camera,False,False,Ship.Velocity,False);
    {$ENDIF}
    DrawFPS(10,10);
  EndDrawing();
end;

procedure TScreenSpace.Show;
begin
  inherited Show;
end;

procedure TScreenSpace.Hide;
begin
  inherited Hide;
end;

end.

