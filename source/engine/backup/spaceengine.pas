unit SpaceEngine;

{$mode ObjFPC}{$H+}

interface

uses
  raylib, raymath, rlgl, Math, DigestMath, Collider, Classes, SysUtils, r3d;

type
  TSkyBoxQuality = (SQLow = 512, SQNormal = 1024, SQHigh = 2048, SQVeryHigh = 4096);
  TSkyBoxType = (STPanorama, STCubemap);
  TColliderType = (ctBox, ctSphere);

  { TrailRung }
  PTrailRung = ^TrailRung;
  TrailRung = record
    LeftPoint: array[0..3] of TVector3;
    RightPoint: array[0..3] of TVector3;
    TimeToLive: Single;
  end;

  { TSpaceDust }
  TSpaceDust = class
  private
    FPoints: array of TVector3;
    FColors: array of TColorB;
    FExtent: Single;
  public
    constructor Create(Size: single; Count:integer); virtual;
    procedure UpdateViewPosition(ViewPosition: TVector3);
    procedure Draw(ViewPosition, Velocity: TVector3; DrawDots: boolean);
  end;

  TSpaceActor = class;
  TRadar = class;

  { TSpaceCrosshair }
  TSpaceCrosshair = class
  private
    FCrosshairColor: TColorB;
    FCrosshairModel: TModel;//TR3D_Model;
    //crosshairTransform: TMatrix;
  public
    constructor Create(const modelFileName: PChar); virtual;
    destructor Destroy; override;
    procedure PositionCrosshairOnActor(const Actor: TSpaceActor; distance: Single);
    procedure DrawCrosshair;
    procedure ApplyBlend;
    property CrosshairColor: TColorB read FCrosshairColor write FCrosshairColor;

  end;

  { TSpaceCamera }
  TSpaceCamera = class
  private
    FSmoothPosition: TVector3;
    FSmoothTarget: TVector3;
    FSmoothUp: TVector3;
  public
    Camera: TCamera3D;
    constructor Create(isPerspective:boolean; fieldOfView: single); virtual;
    procedure BeginDrawing;
    procedure EndDrawing;
    procedure FollowActor(const Actor: TSpaceActor; deltaTime: Single);
    procedure MoveTo(position_, target, up: TVector3; deltaTime: Single);
    procedure SetPosition(position_, target, up: TVector3);
    function GetPosition: TVector3;
    function GetTarget: TVector3;
    function GetUp: TVector3;
    function GetFovy: Single;
  end;

  { TSpaceEngine }
  TSpaceEngine = class
  private
    FActorList: TList;
    FDeadActorList: TList;
    FLight: array[0..3] of TR3D_Light;
    FSpaceDust: TSpaceDust;
    FSkyBox: TR3D_Skybox;
    FRadar: TRadar;
    function GetCount: Integer;
    function GetLight(const Index: Integer): TR3D_Light;
    function GetModelActor(const Index: Integer): TSpaceActor;
    procedure SetLight(const Index: Integer; AValue: TR3D_Light);
  public
    CrosshairNear, CrosshairFar: TSpaceCrosshair;
    constructor Create;
    destructor Destroy; override;
    procedure Add(const ModelActor: TSpaceActor);
    procedure Remove(const ModelActor: TSpaceActor);
    procedure Change(ModelActor: TSpaceActor; Dest: TSpaceEngine);
    procedure Update(DeltaTime: Single; DustViewPosition: TVector3);
    procedure Render(Camera: TSpaceCamera; ShowDebugAxes, {%H-}ShowDebugRay: Boolean; DustVelocity: TVector3; DustDrawDots: boolean);
    procedure Collision;
    procedure Clear;
    procedure ClearDeadActor;
    procedure LoadSkyBox(FileName: String; Quality: TSkyBoxQuality; SkyBoxType: TSkyBoxType);
    procedure LoadSkyBoxFromMemory(SkyBoxImage: TImage; Quality: TSkyBoxQuality; SkyBoxType: TSkyBoxType);
    procedure EnableSkybox;
    procedure DisableSkybox;
    procedure ApplyInputToShip(Ship: TSpaceActor; Step: Single);

    property Items[const Index: Integer]: TSpaceActor read GetModelActor; default;
    property Light[const Index: Integer]: TR3D_Light read GetLight write SetLight;
    property Count: Integer read GetCount;


    property Radar: TRadar read FRadar write FRadar;
  end;

  { TSpaceActor }
  TSpaceActor = class
  private
    FActorIndex: Integer;
    FAlignToHorizon: Boolean;
    FColliderType: TColliderType;
    FDoCollision: Boolean;
    FEngine: TSpaceEngine;
    FMaxSpeed: Single;
    FModel: TR3D_Model;
    FModelTransform: TMatrix;
    FProjection: TVector4;
    FSmoothForward: Single;
    FSmoothLeft: Single;
    FSmoothUp: Single;
    FSmoothPitchDown: Single;
    FSmoothRollRight: Single;
    FSmoothYawLeft: Single;
    FPosition: TVector3;
    FRotation: TQuaternion;
    FScale: Single;
    FSphereColliderSize: Single;
    FTag: Integer;
    FIsDead: Boolean;
    FThrottleResponse: Single;
    FTrailColor: TColorB;
    FTurnRate: Single;
    FTurnResponse: Single;
    FVelocity: TVector3;
    FVisualRotation: TQuaternion;
    FVisualBank: Single;
    FVisible: Boolean;
    FRay: TRay;
    FCollider: TCollider;

    RungCount: integer;
    RungIndex: integer;
    Rungs: array [0..15] of TrailRung;
    LastRungPosition: TVector3;

    procedure SetModel(AValue: TR3D_Model);
    procedure SetPosition(AValue: TVector3);
    procedure SetScale(AValue: Single);
    procedure PositionActiveTrailRung();
  public
    InputForward: Single;
    InputLeft: Single;
    InputUp: Single;
    InputPitchDown: Single;
    InputRollRight: Single;
    InputYawLeft: Single;
    EngineLeftPoint: array[0..3] of TVector3;
    EngineRightPoint: array[0..3] of TVector3;
    constructor Create(const AParent: TSpaceEngine); virtual;
    destructor Destroy; override;
    procedure Assign(const {%H-}Value: TSpaceActor); virtual;
    procedure Collision(const Other: TSpaceActor); overload; virtual;
    procedure Collision; overload; virtual;
    procedure Dead; virtual;
    procedure OnCollision(const {%H-}Actor: TSpaceActor); virtual;
    procedure Update(const DeltaTime: Single); virtual;
    procedure Render; virtual;



    procedure DrawTrail;

    function GetForward:TVector3;
    function GetForward(Distance: Single): TVector3;

    function GetBack:TVector3;
    function GetBack(Distance: Single): TVector3;

    function GetRight:TVector3;
    function GetRight(Distance: Single): TVector3;

    function GetLeft:TVector3;
    function GetLeft(Distance: Single): TVector3;

    function GetUp:TVector3;
    function GetUp(Distance: Single): TVector3;

    function GetDown:TVector3;
    function GetDown(Distance: Single): TVector3;

    function GetVelocity: TVector3;
    function GetSpeed: Single;

    function TransformPoint(point: TVector3): TVector3;
    procedure RotateLocalEuler(axis: TVector3; degrees: single);
    procedure RotationToActor(targetActor: TSpaceActor; z_axis: boolean = false; deflection: Single = 0.05);
    procedure RotationToVector(target: TVector3; z_axis: boolean = false; deflection: Single = 0.05);
    property ActorModel: TR3D_Model read FModel write SetModel;

    property Engine: TSpaceEngine read FEngine write FEngine;
    property Position: TVector3 read FPosition write SetPosition;
    property Projection: TVector4 read FProjection write FProjection;

    property Rotation: TQuaternion read FRotation write FRotation;
    property Velocity: TVector3 read FVelocity write FVelocity;

    property TrailColor: TColorB read FTrailColor write FTrailColor;

  published
    property IsDead: Boolean read FIsDead;
    property Visible: Boolean read FVisible write FVisible;
    property Tag: Integer read FTag write FTag;
    property Scale: Single read FScale write SetScale;
    property ActorIndex: Integer read FActorIndex write FActorIndex;
    property DoCollision: Boolean read FDoCollision write FDoCollision;
    property MaxSpeed: Single read FMaxSpeed write FMaxSpeed default 20;
    property ThrottleResponse: Single read FThrottleResponse write FThrottleResponse default 10;
    property TurnResponse: Single read FTurnResponse write FTurnResponse default 10;
    property TurnRate: Single read FTurnRate write FTurnRate default 180;
    property AlignToHorizon: Boolean read FAlignToHorizon write FAlignToHorizon default True;
    property ColliderType: TColliderType read FColliderType write FColliderType default ctBox;
    property SphereColliderSize: Single read FSphereColliderSize write FSphereColliderSize default 1;
  end;

  { TRadar }
  TRadar = class
  private
    FEngine: TSpaceEngine;
    FPlayer: TSpaceActor;
    FMaxRange: Single;
    FRadarSize: Integer;
    FRadarPos: TVector2;
    FShowLabels: Boolean;
    FLabelVisibilityRange: Single;
    FLabelSize: Integer;
    FFontSize: Integer;
    FMarkerColor: TColorB;
    FEdgeMarkerColor: TColorB;

    // for radar shader
    FStartTime: Single;
    FResolution: array [0..2] of Single;
    FTime: Single;
    FRadarWaveShader: TShader;
    FRadarRipleShader: TShader;
    FRadarRenderTexture, FRadarRenderTexture2: TRenderTexture2D;

    procedure DrawRadarCircle;
    procedure DrawWorldMarkers(Camera: TSpaceCamera; modelPos: TVector3; distance: Single; color: TColorB);
    function GetObjectColor(Tag: Integer): TColorB;
  public
    constructor Create(AEngine: TSpaceEngine);
    procedure Draw(Camera: TSpaceCamera);
    procedure SetPlayer(AValue: TSpaceActor);

    property Player: TSpaceActor read FPlayer write SetPlayer;
    property MaxRange: Single read FMaxRange write FMaxRange;
    property RadarSize: Integer read FRadarSize write FRadarSize;
    property ShowLabels: Boolean read FShowLabels write FShowLabels;
    property LabelVisibilityRange: Single read FLabelVisibilityRange write FLabelVisibilityRange;
    property LabelSize: Integer read FLabelSize write FLabelSize;
    property FontSize: Integer read FFontSize write FFontSize;
    property MarkerColor: TColorB read FMarkerColor write FMarkerColor;
    property EdgeMarkerColor: TColorB read FEdgeMarkerColor write FEdgeMarkerColor;
  end;


implementation
uses RadarShader;

const RungDistance = 2.0;
const RungTimeToLive = 2.0;



{ TSpaceDust }
constructor TSpaceDust.Create(Size: single; Count: integer);
var point: TVector3; color: TColorB; i: integer;
begin
  FExtent := size * 0.5;
  SetLength(FPoints,count);
  SetLength(FColors,count);
  for i:=0 to count-1 do
  begin
    point := Vector3Create(
    GetPrettyBadRandomFloat(-FExtent, FExtent),
    GetPrettyBadRandomFloat(-FExtent, FExtent),
    GetPrettyBadRandomFloat(-FExtent, FExtent));
    FPoints[i]:= point;
    color := ColorCreate(GetRandomValue(192, 255), GetRandomValue(192, 255), GetRandomValue(192, 255),255);
    Fcolors[i]:= Color;
  end;
end;

procedure TSpaceDust.UpdateViewPosition(ViewPosition: TVector3);
var size:single; i: integer;
begin
  size := FExtent * 2;
  for i:=0 to Length(FPoints) -1 do
  begin
    if (FPoints[i].x > viewPosition.x + FExtent) then FPoints[i].x -= size;
    if (FPoints[i].x < viewPosition.x - FExtent) then FPoints[i].x += size;
    if (FPoints[i].y > viewPosition.y + FExtent) then FPoints[i].y -= size;
    if (FPoints[i].y < viewPosition.y - FExtent) then FPoints[i].y += size;
    if (FPoints[i].z > viewPosition.z + FExtent) then FPoints[i].z -= size;
    if (FPoints[i].z < viewPosition.z - FExtent) then FPoints[i].z += size;
  end;
end;

procedure TSpaceDust.Draw(ViewPosition, Velocity: TVector3; DrawDots: boolean);
var i, farAlpha: integer;  distance, farLerp, cubeSize: single;
begin
  BeginBlendMode(BLEND_ADDITIVE);
  for i:=0 to Length(FPoints) -1 do
  begin
    distance := Vector3Distance(viewPosition, FPoints[i]);
    farLerp := Clamp(Normalize(distance, FExtent * 0.9, FExtent), 0, 1);
    farAlpha := round(Lerp(255, 0, farLerp));
    cubeSize := 0.01;
    if (drawDots) then DrawSphereEx(FPoints[i], cubeSize, 2, 2, ColorCreate(FColors[i].r, FColors[i].g, FColors[i].b, farAlpha));
    DrawLine3D(Vector3Add(FPoints[i], Vector3Scale(velocity, 0.01)),
    FPoints[i], ColorCreate(FColors[i].r, FColors[i].g, FColors[i].b, farAlpha));
  end;
  rlDrawRenderBatchActive();
  EndBlendMode();
end;

{ TSpaceCrosshair }
constructor TSpaceCrosshair.Create(const modelFileName: PChar);
begin
  //R3D_SetModelImportScale(1);
  FCrosshairColor := DARKGREEN;


  if modelFileName <> nil then
    FCrosshairModel := LoadModel(modelFileName);


  // CubeColor := ColorCreate(100, 100, 255, 100);



end;

destructor TSpaceCrosshair.Destroy;
begin
  if @FCrosshairModel <> nil then
  begin
   // R3D_UnloadModel(@FCrosshairModel, True);
    TraceLog(LOG_INFO, 'Space Engine: crosshair destroy and unload.');
  end else TraceLog(LOG_ERROR, 'Space Engine: crosshair not destroy');
  inherited Destroy;
end;

procedure TSpaceCrosshair.PositionCrosshairOnActor(const Actor: TSpaceActor; distance: Single);
//v//ar crosshairPos: TVector3;

//begin
 // crosshairPos := Vector3Add(Vector3Scale(Actor.GetForward(), distance), Actor.Position);
//  crosshairTransform := MatrixTranslate(crosshairPos.x, crosshairPos.y, crosshairPos.z);
//  crosshairTransform := MatrixMultiply(QuaternionToMatrix(Actor.Rotation), crosshairTransform);
 // crosshairTransform := MatrixMultiply(MatrixScale(25, 25,25), crosshairTransform);


 var crosshairPos: TVector3;
    crosshairTransform: TMatrix;
begin
  crosshairPos := Vector3Add(Vector3Scale(Actor.GetForward(), distance), Actor.Position);
  crosshairTransform := MatrixTranslate(crosshairPos.x, crosshairPos.y, crosshairPos.z);
  crosshairTransform := MatrixMultiply(QuaternionToMatrix(Actor.Rotation), crosshairTransform);
  FCrosshairModel.transform := crosshairTransform;


end;

procedure TSpaceCrosshair.DrawCrosshair;
begin
  BeginBlendMode(BLEND_ADDITIVE);
   rlDisableDepthTest();

     DrawModel(FCrosshairModel, Vector3Zero(), 1, DARKGREEN);

     // R3D_DrawModelPro(@FCrosshairModel, crosshairTransform);
   rlEnableDepthTest();
 EndBlendMode();
end;

procedure TSpaceCrosshair.ApplyBlend;
begin
  //FCrosshairModel.materials[0].albedo.color := DARKGREEN;
  //FCrosshairModel.materials[0].orm.occlusion := 1.0;
  //FCrosshairModel.materials[0].orm.roughness := 0.2;
 // FCrosshairModel.materials[0].orm.metalness := 0.2;
  //FCrosshairModel.materials[0].blendMode := R3D_BLEND_ALPHA;
  //FCrosshairModel.materials[0].shadowCastMode := R3D_SHADOW_CAST_DISABLED;
end;

{ TSpaceCamera }
constructor TSpaceCamera.Create(isPerspective: boolean; fieldOfView: single);
begin
  Camera.position := Vector3Create(0, 10, -10);
  Camera.target := Vector3Create(0, 0, 0);
  Camera.up := Vector3Create(0, 1, 0);
  Camera.fovy := fieldOfView;

  if isPerspective then
    Camera.projection := CAMERA_PERSPECTIVE
  else
    Camera.projection := CAMERA_ORTHOGRAPHIC;

  FSmoothPosition := Vector3Zero();
  FSmoothTarget := Vector3Zero();
  FSmoothUp := Vector3Zero();
end;

procedure TSpaceCamera.BeginDrawing;
begin
  R3D_Begin(Camera);
end;

procedure TSpaceCamera.EndDrawing;
begin
  R3D_End();
end;

procedure TSpaceCamera.FollowActor(const Actor: TSpaceActor; deltaTime: Single);
var pos, actorForwards, target, up: TVector3;
begin
  pos := Actor.TransformPoint(Vector3Create(0, 1, -3));
  actorForwards := Vector3Scale(Actor.GetForward(), 25);
  target := Vector3Add(Actor.FPosition, ActorForwards);
  up := Actor.GetUp();
  MoveTo(pos, target, up, deltaTime);
end;

procedure TSpaceCamera.MoveTo(position_, target, up: TVector3; deltaTime: Single);
begin
  Camera.position := SmoothDamp(Camera.position, position_, 10, deltaTime);
  Camera.target := SmoothDamp(Camera.target, target, 5, deltaTime);
  Camera.up := SmoothDamp(Camera.up, up, 5, deltaTime);
end;

procedure TSpaceCamera.SetPosition(position_, target, up: TVector3);
begin
  Camera.position := position_;
  Camera.target := target;
  Camera.up := up;
  FSmoothPosition := position_;
  FSmoothTarget := target;
  FSmoothUp := up;
end;

function TSpaceCamera.GetPosition: TVector3;
begin
  result := Camera.position;
end;

function TSpaceCamera.GetTarget: TVector3;
begin
  result := Camera.target;
end;

function TSpaceCamera.GetUp: TVector3;
begin
  result := Camera.up;
end;

function TSpaceCamera.GetFovy: Single;
begin
  result := Camera.fovy;
end;

{ TSpaceEngine }
function TSpaceEngine.GetCount: Integer;
begin
  if FActorList <> nil then Result := FActorList.Count
  else Result := 0;
end;

function TSpaceEngine.GetLight(const Index: Integer): TR3D_Light;
begin
  if (Index >= 0) and (Index <= 3) then
  result := FLight[Index];
end;

function TSpaceEngine.GetModelActor(const Index: Integer): TSpaceActor;
begin
  if (FActorList <> nil) and (Index >= 0) and (Index < FActorList.Count) then
    Result := TSpaceActor(FActorList[Index])
  else
    Result := nil;
end;

procedure TSpaceEngine.SetLight(const Index: Integer; AValue: TR3D_Light);
begin
  if (Index >= 0) and (Index <= 3) then
  FLight[Index] := AValue;
end;

constructor TSpaceEngine.Create;
begin
  FActorList := TList.Create;
  FDeadActorList := TList.Create;
  FSpaceDust := TSpaceDust.Create(50, 500);
  CrosshairNear := TSpaceCrosshair.Create(nil);
  CrosshairFar := TSpaceCrosshair.Create(nil);
  FRadar := TRadar.Create(Self); // PlayerActor будет установлен позже

end;

destructor TSpaceEngine.Destroy;
var i: integer;
begin
  for i := 0 to FActorList.Count - 1 do
  begin
    TSpaceActor(FActorList.Items[i]).Dead;
  end;

  ClearDeadActor;

  FActorList.Free;
  FDeadActorList.Free;

  // Unload skybox if used
  R3D_UnloadSkybox(FSkyBox);

  // Close R3D
  R3D_Close;

  TraceLog(LOG_Info,PChar('Space Engine: Engine Destroy'));
  inherited Destroy;
end;

procedure TSpaceEngine.Add(const ModelActor: TSpaceActor);
var L, H, I: Integer;
begin
  L := 0;
  H := FActorList.Count - 1;
  while (L <= H) do
  begin
    I := (L + H) div 2;
    L := I + 1
  end;
  FActorList.Insert(L, ModelActor);
end;

procedure TSpaceEngine.Remove(const ModelActor: TSpaceActor);
begin
  FActorList.Remove(ModelActor);
end;

procedure TSpaceEngine.Change(ModelActor: TSpaceActor; Dest: TSpaceEngine);
begin
  Dest.Add(ModelActor);
  ModelActor.Engine := Dest;
  FActorList.Remove(ModelActor);
end;

procedure TSpaceEngine.Update(DeltaTime: Single; DustViewPosition: TVector3);
var i: Integer;
begin
  FSpaceDust.UpdateViewPosition(DustViewPosition);
  for i := 0 to FActorList.Count - 1 do
  begin
    TSpaceActor(FActorList.Items[i]).Update(DeltaTime);
  end;
end;

procedure TSpaceEngine.Render(Camera: TSpaceCamera; ShowDebugAxes,
  ShowDebugRay: Boolean; DustVelocity: TVector3; DustDrawDots: boolean);
var i: Integer;
begin

  Camera.BeginDrawing;
    for i := 0 to FActorList.Count - 1 do
      TSpaceActor(FActorList.Items[i]).Render();
  Camera.EndDrawing;




  BeginMode3D(Camera.Camera);
  FSpaceDust.Draw(Camera.GetPosition(), DustVelocity, DustDrawDots);
    CrosshairNear.DrawCrosshair();
    CrosshairFar.DrawCrosshair();
  if ShowDebugAxes then
  begin

    BeginBlendMode(BLEND_ADDITIVE);
    DrawGrid(10, 1.0);
    for i := 0 to FActorList.Count - 1 do
    begin
      TSpaceActor(FActorList.Items[i]).DrawTrail;
      DrawLine3D(TSpaceActor(FActorList.Items[i]).Position, Vector3Add(TSpaceActor(FActorList.Items[i]).Position, TSpaceActor(FActorList.Items[i]).GetForward), ColorCreate(0, 0, 255, 255));
      DrawLine3D(TSpaceActor(FActorList.Items[i]).Position, Vector3Add(TSpaceActor(FActorList.Items[i]).Position, TSpaceActor(FActorList.Items[i]).GetLeft), ColorCreate(255, 0, 0, 255));
      DrawLine3D(TSpaceActor(FActorList.Items[i]).Position, Vector3Add(TSpaceActor(FActorList.Items[i]).Position, TSpaceActor(FActorList.Items[i]).GetUp), ColorCreate(0, 255, 0, 255));

      case TSpaceActor(FActorList.Items[i]).FCollider.ColliderType of
        Collider.ctSphere:
           DrawSphereWires(TSpaceActor(FActorList.Items[i]).FPosition, TSpaceActor(FActorList.Items[i]).FSphereColliderSize, 32, 32, RED);
        Collider.ctBox:
          begin
            DrawLine3D(TSpaceActor(FActorList.Items[i]).FCollider.vertGlobal[0], TSpaceActor(FActorList.Items[i]).FCollider.vertGlobal[1], SKYBLUE);
            DrawLine3D(TSpaceActor(FActorList.Items[i]).FCollider.vertGlobal[2], TSpaceActor(FActorList.Items[i]).FCollider.vertGlobal[3], SKYBLUE);
            DrawLine3D(TSpaceActor(FActorList.Items[i]).FCollider.vertGlobal[4], TSpaceActor(FActorList.Items[i]).FCollider.vertGlobal[5], SKYBLUE);
            DrawLine3D(TSpaceActor(FActorList.Items[i]).FCollider.vertGlobal[6], TSpaceActor(FActorList.Items[i]).FCollider.vertGlobal[7], SKYBLUE);
            DrawLine3D(TSpaceActor(FActorList.Items[i]).FCollider.vertGlobal[0], TSpaceActor(FActorList.Items[i]).FCollider.vertGlobal[2], SKYBLUE);
            DrawLine3D(TSpaceActor(FActorList.Items[i]).FCollider.vertGlobal[1], TSpaceActor(FActorList.Items[i]).FCollider.vertGlobal[3], SKYBLUE);
            DrawLine3D(TSpaceActor(FActorList.Items[i]).FCollider.vertGlobal[4], TSpaceActor(FActorList.Items[i]).FCollider.vertGlobal[6], SKYBLUE);
            DrawLine3D(TSpaceActor(FActorList.Items[i]).FCollider.vertGlobal[5], TSpaceActor(FActorList.Items[i]).FCollider.vertGlobal[7], SKYBLUE);
            DrawLine3D(TSpaceActor(FActorList.Items[i]).FCollider.vertGlobal[1], TSpaceActor(FActorList.Items[i]).FCollider.vertGlobal[5], SKYBLUE);
            DrawLine3D(TSpaceActor(FActorList.Items[i]).FCollider.vertGlobal[3], TSpaceActor(FActorList.Items[i]).FCollider.vertGlobal[7], SKYBLUE);
            DrawLine3D(TSpaceActor(FActorList.Items[i]).FCollider.vertGlobal[0], TSpaceActor(FActorList.Items[i]).FCollider.vertGlobal[4], SKYBLUE);
            DrawLine3D(TSpaceActor(FActorList.Items[i]).FCollider.vertGlobal[2], TSpaceActor(FActorList.Items[i]).FCollider.vertGlobal[6], SKYBLUE);
          end;
       end; //end case
    end;


    EndBlendMode();

  end;
    CrosshairNear.DrawCrosshair();
    CrosshairFar.DrawCrosshair();
  EndMode3D;

  // Рисуем радар поверх всего
  if Assigned(FRadar) and Assigned(FRadar.FPlayer) then
    FRadar.Draw(Camera);

end;

procedure TSpaceEngine.Collision;
var
  i, j: Integer;
begin
  for i := 0 to FActorList.Count - 1 do
  begin
    for j := i + 1 to FActorList.Count - 1 do
    begin
      if (TSpaceActor(FActorList.Items[i]).DoCollision) and
         (TSpaceActor(FActorList.Items[j]).DoCollision) then
        TSpaceActor(FActorList.Items[i]).Collision(TSpaceActor(FActorList.Items[j]));
    end;
  end;
end;

procedure TSpaceEngine.Clear;
begin
  while Count > 0 do
  begin
    Items[Count - 1].Free;
  end;
end;

procedure TSpaceEngine.ClearDeadActor;
begin
  while FDeadActorList.Count -1 >= 0 do
  begin
    TSpaceActor(FDeadActorList.Items[FDeadActorList.Count - 1]).Free;
  end;
end;

procedure TSpaceEngine.LoadSkyBox(FileName: String; Quality: TSkyBoxQuality;
  SkyBoxType: TSkyBoxType);
begin
  case SkyBoxType of
    STCubemap: FSkyBox := R3D_LoadSkybox(PChar(FileName),CUBEMAP_LAYOUT_AUTO_DETECT);
    STPanorama: FSkyBox := R3D_LoadSkyboxPanorama(PChar(FileName), Integer(Quality));
  end;

end;

procedure TSpaceEngine.LoadSkyBoxFromMemory(SkyBoxImage: TImage;
  Quality: TSkyBoxQuality; SkyBoxType: TSkyBoxType);
begin
  case SkyBoxType of
    STCubemap: FSkyBox := R3D_LoadSkyboxFromMemory(SkyBoxImage,CUBEMAP_LAYOUT_AUTO_DETECT);
    STPanorama: FSkyBox := R3D_LoadSkyboxPanoramaFromMemory(SkyBoxImage, Integer(Quality));
  end;
end;

procedure TSpaceEngine.EnableSkybox;
begin
 R3D_EnableSkybox(FSkyBox);
end;

procedure TSpaceEngine.DisableSkybox;
begin
  R3D_DisableSkybox;
end;

procedure TSpaceEngine.ApplyInputToShip(Ship: TSpaceActor; Step: Single);
var triggerRight, triggerLeft: Single;
begin
  Ship.InputForward := 0;
  if (IsKeyDown(KEY_W)) then Ship.InputForward += Step;
  if (IsKeyDown(KEY_S)) then Ship.InputForward -= Step;

  Ship.InputForward -= GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_Y);
  Ship.InputForward := Clamp(Ship.InputForward, -Step, Step);

  Ship.InputLeft := 0;
  if (IsKeyDown(KEY_D)) then Ship.InputLeft -= Step;
  if (IsKeyDown(KEY_A)) then Ship.InputLeft += Step;

  Ship.InputLeft -= GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_X);
  Ship.InputLeft := Clamp(Ship.InputLeft, -Step, Step);

  Ship.InputUp := 0;
  if (IsKeyDown(KEY_SPACE)) then Ship.InputUp += Step;
  if (IsKeyDown(KEY_LEFT_CONTROL)) then Ship.InputUp -= Step;

  triggerRight := GetGamepadAxisMovement(0, GAMEPAD_AXIS_RIGHT_TRIGGER);
  triggerRight := Remap(triggerRight, -Step, Step, 0, Step);

  triggerLeft := GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_TRIGGER);
  triggerLeft := Remap(triggerLeft, -Step, Step, 0, Step);

  Ship.InputUp += triggerRight;
  Ship.InputUp -= triggerLeft;
  Ship.InputUp := Clamp(Ship.InputUp, -Step, Step);

  Ship.InputYawLeft := 0;
  if (IsKeyDown(KEY_RIGHT)) then Ship.InputYawLeft -= Step;
  if (IsKeyDown(KEY_LEFT)) then Ship.InputYawLeft += Step;

  Ship.InputYawLeft -= GetGamepadAxisMovement(0, GAMEPAD_AXIS_RIGHT_X);
  Ship.InputYawLeft := Clamp(Ship.InputYawLeft, -Step, Step);

  Ship.InputPitchDown := 0;
  if (IsKeyDown(KEY_UP)) then Ship.InputPitchDown += Step;
  if (IsKeyDown(KEY_DOWN)) then Ship.InputPitchDown -= Step;

  Ship.InputPitchDown += GetGamepadAxisMovement(0, GAMEPAD_AXIS_RIGHT_Y);
  Ship.InputPitchDown := Clamp(Ship.InputPitchDown, -Step, Step);

  Ship.InputRollRight := 0;
  if (IsKeyDown(KEY_Q)) then Ship.InputRollRight -= Step;
  if (IsKeyDown(KEY_E)) then Ship.InputRollRight += Step;
end;



{ TSpaceActor }
procedure TSpaceActor.SetModel(AValue: TR3D_Model);
begin
  FModel := AValue;

  case FColliderType of
    ctBox:
      begin
        FCollider := CreateCollider(Vector3Scale(Self.FModel.aabb.min, FScale),
                                    Vector3Scale(Self.FModel.aabb.max, FScale));

      end;
    ctSphere:
      begin
        FCollider := CreateSphereCollider(FPosition, FSphereColliderSize);
      end;
  end;

  SetColliderRotation(@FCollider, FVisualRotation);
  SetColliderTranslation(@FCollider, FPosition);
end;

procedure TSpaceActor.SetPosition(AValue: TVector3);
begin
  FPosition := AValue;
  SetColliderRotation(@self.FCollider, FVisualRotation);
  SetColliderTranslation(@self.FCollider, FPosition);
end;

procedure TSpaceActor.SetScale(AValue: Single);
begin
  if FScale = AValue then Exit;
  FScale := AValue;
  FCollider := CreateCollider(Vector3Scale(FModel.aabb.min, FScale),
                              Vector3Scale(FModel.aabb.max, FScale));
end;

procedure TSpaceActor.PositionActiveTrailRung();
var j: integer;
begin
  Rungs[RungIndex].TimeToLive := RungTimeToLive;
  for j := 0 to 3 do
  begin
    Rungs[RungIndex].LeftPoint[j] := Vector3Transform(EngineLeftPoint[j], Self.FModelTransform);
    Rungs[RungIndex].RightPoint[j] := Vector3Transform(EngineRightPoint[j], Self.FModelTransform);
  end;
end;

constructor TSpaceActor.Create(const AParent: TSpaceEngine);
begin
  FEngine := AParent;
  FIsDead := False;
  FVisible := True;
  FTag := 0;
  FScale := 1;

  FPosition := Vector3Zero();
  FVelocity := Vector3Zero();
  FRotation := QuaternionIdentity();
  FScale := 1;
  FMaxSpeed := 5;
  FThrottleResponse := 10;
  TurnRate := 180;
  TurnResponse := 10;

  FAlignToHorizon := True;

  RungCount := 16;
  LastRungPosition := Position;
  TrailColor := DARKGREEN;

  Engine.Add(Self);

end;

destructor TSpaceActor.Destroy;
begin
  Engine.Remove(Self);
  Engine.FDeadActorList.Remove(Self);

  // Unload model if assigned
  if @FModel <> nil then
  R3D_UnloadModel(@FModel, True);

  inherited Destroy;
end;

procedure TSpaceActor.Assign(const Value: TSpaceActor);
begin
  // Implementation remains the same
end;

procedure TSpaceActor.Collision(const Other: TSpaceActor);
var Correction: TVector3;
begin
  SetColliderRotation(@FCollider, FVisualRotation);
  SetColliderTranslation(@FCollider, FPosition);

  if TestColliderPair(@FCollider, @Other.FCollider) then
  begin
    Correction := GetCollisionCorrection(@FCollider, @Other.FCollider);

    // Apply correction to current position
    FPosition := Vector3Add(FPosition, Correction);
    SetColliderTranslation(@FCollider, FPosition);

    OnCollision(Other);
    Other.OnCollision(Self);
  end;
end;

procedure TSpaceActor.Collision;
var i: Integer;
begin
  for i := 0 to Engine.Count-1 do
  begin
    Collision(Engine.Items[i]);
  end;
end;

procedure TSpaceActor.Dead;
begin
  if not FIsDead then
  begin
    FIsDead := True;
    FEngine.FDeadActorList.Add(Self);
  end;
end;

procedure TSpaceActor.OnCollision(const Actor: TSpaceActor);
begin
  // Implementation remains the same
end;

procedure TSpaceActor.Update(const DeltaTime: Single);
var forwardSpeedMultipilier, autoSteerInput, targetVisualBank: single;
    targetVelocity: TVector3;
    transform: TMatrix; i: integer;

begin
  // Give the ship some momentum when accelerating
  FSmoothForward := SmoothDamp(FSmoothForward, InputForward, ThrottleResponse, deltaTime);
  FSmoothLeft := SmoothDamp(FSmoothLeft, InputLeft, ThrottleResponse, deltaTime);
  FSmoothUp := SmoothDamp(FSmoothUp, InputUp, ThrottleResponse, deltaTime);

  // Flying in reverse should be slower
  forwardSpeedMultipilier := ifthen(FSmoothForward > 0.0, 1.0, 0.33);

  targetVelocity := Vector3Zero();
  targetVelocity := Vector3Add(
    targetVelocity, Vector3Scale(GetForward(), MaxSpeed * forwardSpeedMultipilier * FSmoothForward));
  targetVelocity := Vector3Add(
    targetVelocity, Vector3Scale(GetUp(), MaxSpeed * 0.5 * FSmoothUp));
  targetVelocity := Vector3Add(
    targetVelocity, Vector3Scale(GetLeft(), MaxSpeed * 0.5 * FSmoothLeft));

  FVelocity := SmoothDamp(FVelocity, targetVelocity, 2.5, deltaTime);
  FPosition := Vector3Add(FPosition, Vector3Scale(FVelocity, deltaTime));

  // Give the ship some inertia when turning
  FSmoothPitchDown := SmoothDamp(FSmoothPitchDown, InputPitchDown, TurnResponse, deltaTime);
  FSmoothRollRight := SmoothDamp(FSmoothRollRight, InputRollRight, TurnResponse, deltaTime);
  FSmoothYawLeft := SmoothDamp(FSmoothYawLeft, InputYawLeft, TurnResponse, deltaTime);

  RotateLocalEuler(Vector3Create(0, 0, 1), FSmoothRollRight * TurnRate * deltaTime);
  RotateLocalEuler(Vector3Create(1, 0, 0), FSmoothPitchDown * TurnRate * deltaTime);
  RotateLocalEuler(Vector3Create(0, 1, 0), FSmoothYawLeft * TurnRate * deltaTime);

  // Auto-roll to align to horizon
  if (FAlignToHorizon) and (abs(GetForward().y) < 0.8) then
  begin
    autoSteerInput := GetRight().y;
    RotateLocalEuler(Vector3Create(0, 0, 1), autoSteerInput * TurnRate * 0.5 * deltaTime);
  end;

  // When yawing and strafing, there's some bank added to the model for visual flavor
  targetVisualBank := (-30 * DEG2RAD * FSmoothYawLeft) + (-15 * DEG2RAD * FSmoothLeft);
  FVisualBank := SmoothDamp(FVisualBank, targetVisualBank, 10, deltaTime);
  FVisualRotation := QuaternionMultiply(FRotation, QuaternionFromAxisAngle(Vector3Create(0, 0, 1), FVisualBank));

  // Sync up the raylib representation of the model with the ship's position
  transform := MatrixTranslate(FPosition.x, FPosition.y, FPosition.z);
  transform := MatrixMultiply(QuaternionToMatrix(FvisualRotation), transform);
  transform := MatrixMultiply(MatrixScale(Scale, Scale, Scale), transform);
  FModelTransform := transform;

  // Update collider after position change
  SetColliderRotation(@FCollider, FVisualRotation);
  SetColliderTranslation(@FCollider, FPosition);
  FModelTransform := MatrixMultiply(MatrixScale(FScale, FScale, FScale), GetColliderTransform(@FCollider));

  // The currently active trail rung is dragged directly behind the ship for a smoother trail
  PositionActiveTrailRung();
  if (Vector3Distance(Position, LastRungPosition) > RungDistance) then
  begin
    RungIndex := (RungIndex + 1) mod RungCount;
    LastRungPosition := Position;
  end;

  for i := 0 to RungCount -1 do
    Rungs[i].TimeToLive -= deltaTime;

  // Update ray
  FRay.direction := GetForward;
  FRay.position := Position;


  ActorModel.materials[1].emission.color := GREEN;
  ActorModel.materials[1].emission.energy := Clamp(GetSpeed * FMaxSpeed, 30.0, 300.0);
  ActorModel.materials[1].albedo.color := black;

end;

procedure TSpaceActor.Render;
begin
  if not FVisible then Exit;

  // Draw model using R3D
  R3D_DrawModelPro(@FModel, FModelTransform);
   // Отрисовка выхлопа
 //DrawTrail;
  //R3D_DrawParticleSystem(@FExhaustParticles, @FExhaustMesh, @FExhaustMaterial);
//  DrawTrail;

end;


procedure TSpaceActor.DrawTrail;
var i,j: integer;
    thisRung,nextRung: TrailRung;
    color,fill: TColorB;


begin
  BeginBlendMode(BLEND_ADDITIVE);
  rlDisableDepthMask();

  for i := 0 to RungCount -1 do
  begin
    if (Rungs[i].TimeToLive <= 0) then continue;
    thisRung := Rungs[i mod RungCount];
    color := TrailColor;
    color.a := 255 * Round(thisRung.TimeToLive / RungTimeToLive);
    fill := color;
    fill.a := Round(color.a / 4);

    nextRung := Rungs[(i + 1) mod RungCount];
    if (nextRung.TimeToLive > 0) and (thisRung.TimeToLive < nextRung.TimeToLive) then
    begin
      for j := 0 to 3 do
      begin
        DrawTriangle3D(thisRung.LeftPoint[j], thisRung.RightPoint[j], nextRung.LeftPoint[j], fill);
        DrawTriangle3D(nextRung.LeftPoint[j], thisRung.RightPoint[j], nextRung.RightPoint[j], fill);
        DrawTriangle3D(nextRung.LeftPoint[j], thisRung.RightPoint[j], thisRung.LeftPoint[j], fill);
        DrawTriangle3D(nextRung.RightPoint[j], thisRung.RightPoint[j], nextRung.LeftPoint[j], fill);
      end;
    end;
  end;
  rlDrawRenderBatchActive();
  rlEnableDepthMask();
  EndBlendMode();
end;



function TSpaceActor.GetForward: TVector3;
begin
  result := Vector3RotateByQuaternion(Vector3Create(0,0,1), FRotation);
end;

function TSpaceActor.GetForward(Distance: Single): TVector3;
begin
  result := Vector3RotateByQuaternion(Vector3Create(0,0,Distance), FRotation);
end;

function TSpaceActor.GetBack: TVector3;
begin
  result := Vector3RotateByQuaternion(Vector3Create(0,0,-1), FRotation);
end;

function TSpaceActor.GetBack(Distance: Single): TVector3;
begin
  result := Vector3RotateByQuaternion(Vector3Create(0,0,-Distance), FRotation);
end;

function TSpaceActor.GetRight: TVector3;
begin
  result := Vector3RotateByQuaternion(Vector3Create(-1,0,0), FRotation);
end;

function TSpaceActor.GetRight(Distance: Single): TVector3;
begin
  result := Vector3RotateByQuaternion(Vector3Create(-Distance,0,0), FRotation);
end;

function TSpaceActor.GetLeft: TVector3;
begin
  result := Vector3RotateByQuaternion(Vector3Create(1,0,0), FRotation);
end;

function TSpaceActor.GetLeft(Distance: Single): TVector3;
begin
  result := Vector3RotateByQuaternion(Vector3Create(Distance,0,0), FRotation);
end;

function TSpaceActor.GetUp: TVector3;
begin
  result := Vector3RotateByQuaternion(Vector3Create(0,1,0), FRotation);
end;

function TSpaceActor.GetUp(Distance: Single): TVector3;
begin
  result := Vector3RotateByQuaternion(Vector3Create(0,Distance,0), FRotation);
end;

function TSpaceActor.GetDown: TVector3;
begin
  result := Vector3RotateByQuaternion(Vector3Create(0,-1,0), FRotation);
end;

function TSpaceActor.GetDown(Distance: Single): TVector3;
begin
  result:= Vector3RotateByQuaternion(Vector3Create(0,-Distance,0), FRotation);
end;

function TSpaceActor.GetVelocity: TVector3;
begin
    Result := FVelocity; // Возвращает вектор скорости (x, y, z)
end;

function TSpaceActor.GetSpeed: Single;
begin
    Result := Vector3Length(FVelocity); // Возвращает длину вектора скорости
end;

function TSpaceActor.TransformPoint(point: TVector3): TVector3;
var mPos, mRot, matrix: TMatrix;
begin
  mPos:= MatrixTranslate(FPosition.x, FPosition.y, FPosition.z);
  mRot:= QuaternionToMatrix(FRotation);
  matrix:= MatrixMultiply(mRot, mPos);
  result:= Vector3Transform(point, matrix);
end;

procedure TSpaceActor.RotateLocalEuler(axis: TVector3; degrees: single);
var radians: single;
begin
  radians:= degrees * DEG2RAD;
  FRotation:= QuaternionMultiply(FRotation, QuaternionFromAxisAngle(axis, radians));
end;

procedure TSpaceActor.RotationToActor(targetActor: TSpaceActor;
  z_axis: boolean; deflection: Single);
var
  matrix: TMatrix;
  rotation_: TQuaternion;
  dis, direction: TVector3;
begin
  dis := Vector3Subtract(FPosition, targetActor.Position);
  direction := Vector3Normalize(dis);
  if z_axis then // Get look at and rotation.
  matrix := MatrixLookAt(Vector3Zero, direction, Vector3Create(0,1,1))
  else
  matrix := MatrixLookAt(Vector3Zero, direction, Vector3Create(0,1,0));
  rotation_ := QuaternionInvert(QuaternionFromMatrix(matrix));
  FRotation := QuaternionSlerp(FRotation, rotation_, GetFrameTime * deflection * RAD2DEG);
end;

procedure TSpaceActor.RotationToVector(target: TVector3; z_axis: boolean; deflection: Single);
var
  matrix: TMatrix;
  rotation_: TQuaternion;
  dis, direction: TVector3;
begin
  dis := Vector3Subtract(FPosition, target);
  direction := Vector3Normalize(dis);
  if z_axis then // Get look at and rotation.
  matrix := MatrixLookAt(Vector3Zero, direction, Vector3Create(0,1,1))
  else
  matrix := MatrixLookAt(Vector3Zero, direction, Vector3Create(0,1,0));
  rotation_ := QuaternionInvert(QuaternionFromMatrix(matrix));
  FRotation := QuaternionSlerp(FRotation, rotation_, GetFrameTime * deflection * RAD2DEG);
end;

{ TRadar }

constructor TRadar.Create(AEngine: TSpaceEngine);
begin
  FEngine := AEngine;
  FPlayer := nil;
  FMaxRange := 200;
  FRadarSize := 100;
  FRadarPos := Vector2Create(0, 0);
  FShowLabels := True;
  FLabelVisibilityRange := 0.7;
  FLabelSize := 15;
  FFontSize := 10;
  FMarkerColor := YELLOW;
  FEdgeMarkerColor := ColorCreate(255, 165, 0, 255); // Оранжевый

  FRadarRipleShader := LoadShaderFromMemory(nil, RIPLE_SHADER_FS);
  FRadarWaveShader := LoadShaderFromMemory(nil, WAVE_SHADER_FS);

  FRadarRenderTexture := LoadRenderTexture(Round(FRadarSize), Round(FRadarSize));
  FRadarRenderTexture2 := LoadRenderTexture(Round(FRadarSize), Round(FRadarSize));
  // Получаем uniform-переменные
  FRadarRipleShader.locs[SHADER_LOC_VECTOR_VIEW] := GetShaderLocation(FRadarRipleShader, 'iResolution');
  FRadarRipleShader.locs[SHADER_LOC_MATRIX_MODEL] := GetShaderLocation(FRadarRipleShader, 'iTime');

  FRadarWaveShader.locs[SHADER_LOC_VECTOR_VIEW] := GetShaderLocation(FRadarWaveShader, 'iResolution');
  FRadarWaveShader.locs[SHADER_LOC_MATRIX_MODEL] := GetShaderLocation(FRadarWaveShader, 'iTime');
    // Устанавливаем разрешение в шейдер
  FResolution[0] := FRadarSize;
  FResolution[1] := FRadarSize;
  FResolution[2] := 0;
  SetShaderValue(FRadarRipleShader, FRadarRipleShader.locs[SHADER_LOC_VECTOR_VIEW], @FResolution, SHADER_UNIFORM_VEC3);
  SetShaderValue(FRadarWaveShader, FRadarWaveShader.locs[SHADER_LOC_VECTOR_VIEW], @FResolution, SHADER_UNIFORM_VEC3);
end;

procedure TRadar.SetPlayer(AValue: TSpaceActor);
begin
  if FPlayer = AValue then Exit;
  FPlayer := AValue;
end;

procedure TRadar.DrawRadarCircle;
var
  radarCenter: TVector2;
  margin: Integer;


begin
  margin := 10;
  radarCenter.x := GetScreenWidth - FRadarSize div 2 - margin;
  radarCenter.y := GetScreenHeight - FRadarSize div 2 - margin;

  // Фон радара
 DrawCircle(Round(radarCenter.x), Round(radarCenter.y), FRadarSize div 2,
 ColorCreate(0, 0, 32, 180));


  // Обновление
  FTime := GetTime() - FStartTime;
  SetShaderValue(FRadarRipleShader, FRadarRipleShader.locs[SHADER_LOC_MATRIX_MODEL], @FTime, SHADER_UNIFORM_FLOAT);
  SetShaderValue(FRadarWaveShader, FRadarWaveShader.locs[SHADER_LOC_MATRIX_MODEL], @FTime, SHADER_UNIFORM_FLOAT);

  // Рендерим шейдер в текстуру
  BeginTextureMode(FRadarRenderTexture);
        ClearBackground(BLANK);
        BeginShaderMode(FRadarRipleShader);
        // Рисуем прямоугольник, на который будет наложен шейдер
          DrawRectangle(0, 0, Round(FRadarSize), Round(FRadarSize), WHITE);
        EndShaderMode;
  EndTextureMode;

      // Рисуем полученную текстуру
      DrawTexturePro(
        FRadarRenderTexture.texture,
        RectangleCreate(0, 0, FRadarSize, -FRadarSize),
        RectangleCreate(radarCenter.x - FRadarSize div 2, radarCenter.y - FRadarSize div 2, FRadarSize, FRadarSize),
        Vector2Zero(),
        0,
        WHITE
      );

end;

function TRadar.GetObjectColor(Tag: Integer): TColorB;
begin
  case Tag of
    1: Result := RED;     // Враги
    2: Result := GREEN;   // Союзники
    3: Result := BLUE;    // Дружественные
    4: Result := YELLOW;  // Цели
    else Result := FMarkerColor;
  end;
end;


function GetCameraForward(camera: TCamera3D): TVector3;
begin
  Result := Vector3Normalize(Vector3Subtract(camera.target, camera.position));
end;

function GetCameraRight(camera: TCamera3D): TVector3;
begin
  Result := Vector3Normalize(Vector3CrossProduct(GetCameraForward(camera), camera.up));
end;

function GetCameraUp(camera: TCamera3D): TVector3;
begin
  Result := camera.up;
end;

procedure TRadar.DrawWorldMarkers(Camera: TSpaceCamera; modelPos: TVector3; distance: Single; color: TColorB);
var
  screenPos, edgePos: TVector2;
  viewport: TRectangle;
  direction: TVector2;
  screenCenter: TVector2;
  angle: Single;
  distanceText: string;
  textWidth: Integer;
  markerSize: Integer;
  isOffScreen: Boolean;
  behindCamera: Boolean;
  viewVector: TVector3;
  fakePos: TVector3;
  const FakeDistance = 10.0;
begin
  viewport := RectangleCreate(0, 0, GetScreenWidth, GetScreenHeight);
  screenCenter := Vector2Create(viewport.width/2, viewport.height/2);

  // Проверяем, находится ли объект позади камеры
  viewVector := Vector3Subtract(modelPos, Camera.Camera.position);
  behindCamera := Vector3DotProduct(viewVector, GetCameraForward(Camera.Camera)) < 0;

  if behindCamera then
  begin
    // Создаем виртуальную позицию перед камерой

    fakePos := Vector3Add(Camera.Camera.position,
              Vector3Scale(GetCameraForward(Camera.Camera), FakeDistance));
    fakePos := Vector3Add(fakePos,
              Vector3Scale(GetCameraRight(Camera.Camera),
              Vector3DotProduct(viewVector, GetCameraRight(Camera.Camera))));
    fakePos := Vector3Add(fakePos,
              Vector3Scale(GetCameraUp(Camera.Camera),
              Vector3DotProduct(viewVector, GetCameraUp(Camera.Camera))));

    screenPos := GetWorldToScreen(fakePos, Camera.Camera);
    isOffScreen := True;
  end
  else
  begin
    screenPos := GetWorldToScreen(modelPos, Camera.Camera);
    isOffScreen := not CheckCollisionPointRec(screenPos, viewport);
  end;

  if isOffScreen then
  begin
    // Вычисляем направление от центра экрана к объекту
    direction := Vector2Normalize(Vector2Subtract(screenPos, screenCenter));

    // Находим точку пересечения с границей экрана
    angle := ArcTan2(direction.y, direction.x);

    // Корректируем позицию маркера у края экрана
    edgePos.x := screenCenter.x + (Cos(angle) * (viewport.width/2 - 20));
    edgePos.y := screenCenter.y + (Sin(angle) * (viewport.height/2 - 20));

    // Рисуем специальный маркер для объектов позади
    if behindCamera then
    begin
      // Маркер в виде круга с точкой
      DrawCircleLines(Round(edgePos.x), Round(edgePos.y), 8, color);
      DrawCircle(Round(edgePos.x), Round(edgePos.y), 3, color);
    end
    else
    begin
      // Обычный маркер у края экрана (треугольник)
      markerSize := 10;
      DrawTriangle(
        Vector2Create(edgePos.x + Cos(angle) * markerSize,
                     edgePos.y + Sin(angle) * markerSize),
        Vector2Create(edgePos.x + Cos(angle + Pi*0.8) * markerSize,
                     edgePos.y + Sin(angle + Pi*0.8) * markerSize),
        Vector2Create(edgePos.x + Cos(angle - Pi*0.8) * markerSize,
                     edgePos.y + Sin(angle - Pi*0.8) * markerSize),
        color);
    end;

    // Текст с дистанцией
    distanceText := Format('%.0fm', [distance]);
    textWidth := MeasureText(PChar(distanceText), FFontSize);

    // Позиционируем текст с учетом угла
    DrawText(PChar(distanceText),
      Round(edgePos.x + Cos(angle) * 15 - textWidth/2),
      Round(edgePos.y + Sin(angle) * 15 - FFontSize/2),
      FFontSize, WHITE);
  end
  else
  begin
    // Обычный маркер над видимым объектом
    markerSize := Round(FLabelSize * (1 - Min(distance / FMaxRange, 1.0)));
    markerSize := Trunc(Clamp(markerSize, 8, FLabelSize));

    DrawTriangle(
      Vector2Create(screenPos.x, screenPos.y - markerSize),
      Vector2Create(screenPos.x - markerSize/2, screenPos.y - markerSize/2),
      Vector2Create(screenPos.x + markerSize/2, screenPos.y - markerSize/2),
      color);

    // Соединительная линия
    DrawLineEx(
      Vector2Create(screenPos.x, screenPos.y - markerSize/2),
      Vector2Create(screenPos.x, screenPos.y),
      1, color);

    // Текст с дистанцией
    distanceText := Format('%.0fm', [distance]);
    textWidth := MeasureText(PChar(distanceText), FFontSize);
    DrawText(PChar(distanceText),
      Round(screenPos.x - textWidth/2),
      Round(screenPos.y - markerSize - FFontSize - 2),
      FFontSize, color);
  end;
end;

procedure TRadar.Draw(Camera: TSpaceCamera);
var
  i: Integer;
  modelPos: TVector3;
  relativePos: TVector3;
  distance, normalizedDist: Single;
  radarPos: TVector2;
  angle: Single;
  color: TColorB;
  radarCenter: TVector2;
begin
  if (FPlayer = nil) or (FEngine = nil) then Exit;

  // Отрисовка круга радара
  BeginBlendMode(BLEND_ADDITIVE);
      DrawRadarCircle;
  EndBlendMode();

  radarCenter.x := GetScreenWidth - FRadarSize div 2 - 10;
  radarCenter.y := GetScreenHeight - FRadarSize div 2 - 10;

  for i := 0 to FEngine.FActorList.Count - 1 do
  begin
    if TSpaceActor(FEngine.FActorList.Items[i]) = FPlayer then Continue;

    modelPos := TSpaceActor(FEngine.FActorList.Items[i]).Position;
    relativePos := Vector3Subtract(FPlayer.Position, modelPos);
    distance := Vector3Length(relativePos);

    if distance > FMaxRange then Continue;

    color := GetObjectColor(TSpaceActor(FEngine.FActorList.Items[i]).Tag);

    // Отрисовка на радаре
    normalizedDist := Min(distance / FMaxRange, 1.0);
    angle := ArcTan2(relativePos.x, relativePos.z);
    radarPos.x := radarCenter.x + Sin(angle) * (FRadarSize div 2) * normalizedDist;
    radarPos.y := radarCenter.y - Cos(angle) * (FRadarSize div 2) * normalizedDist;

    // Рендерим шейдер в текстуру
    BeginTextureMode(FRadarRenderTexture2);
          ClearBackground(BLANK);
          BeginShaderMode(FRadarWaveShader);
          // Рисуем прямоугольник, на который будет наложен шейдер
            DrawRectangle(0, 0, Round(FRadarSize), Round(FRadarSize), WHITE);
          EndShaderMode;
    EndTextureMode;

       BeginBlendMode(BLEND_ADDITIVE);

         DrawCircle(Round(radarPos.x), Round(radarPos.y), Max(2, Round(4 * (1 - normalizedDist))), color);



        // Рисуем полученную текстуру
        DrawTexturePro(
          FRadarRenderTexture2.texture,
          RectangleCreate(0, 0, FRadarSize, -FRadarSize),
          RectangleCreate(radarCenter.x - FRadarSize div 2, radarCenter.y - FRadarSize div 2, FRadarSize, FRadarSize),
          Vector2Zero(),
          0,
          WHITE
        );
        EndBlendMode();


    // Отрисовка меток в мире
    if FShowLabels and (distance < FMaxRange * FLabelVisibilityRange) then
    begin
      BeginBlendMode(BLEND_ADDITIVE);
        DrawWorldMarkers(Camera, modelPos, distance, color);
      EndBlendMode();
    end;
  end;
end;




end.

