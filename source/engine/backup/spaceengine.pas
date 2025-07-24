unit SpaceEngine;

{$mode ObjFPC}{$H+}

interface

uses
  RayLib, RayMath, RlGl, Math, DigestMath, Collider, Classes, SysUtils, r3d;

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
    FSpaceDust: TSpaceDust;
    FSkyBox: TR3D_Skybox;

    FRadar: TRadar;
    function GetCount: Integer;
    function GetModelActor(const Index: Integer): TSpaceActor;
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
    property Items[const Index: Integer]: TSpaceActor read GetModelActor; default;
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
    FPosition: TVector2;
    //FSize: Single;
    FRange: Single;
    FPlayer: TSpaceActor;
    FEngine: TSpaceEngine;
    FBackgroundColor: TColorB;
    FForegroundColor: TColorB;
    FDefaultBlipColor: TColorB;
    FHostileBlipColor: TColorB;
    FFriendlyBlipColor: TColorB;

    // Новые поля для стиля Everspace 2
    FScreenMargin: Integer;
    FEdgeMarkerSize: Integer;
    FViewAngle: Single;
    FMaxRange: Single;
    FHostileColor: TColorB;
    FFriendlyColor: TColorB;
    FNeutralColor: TColorB;
    FObjectiveColor: TColorB;

    procedure SetPlayer(AValue: TSpaceActor);
  public
    constructor Create(AEngine: TSpaceEngine);
    procedure Draw(Camera: TSpaceCamera);
    property Position: TVector2 read FPosition write FPosition;
 //   property Size: Single read FSize write FSize;
    property Range: Single read FRange write FRange;
    property Player: TSpaceActor read FPlayer write SetPlayer;
    property BackgroundColor: TColorB read FBackgroundColor write FBackgroundColor;
    property ForegroundColor: TColorB read FForegroundColor write FForegroundColor;
    property DefaultBlipColor: TColorB read FDefaultBlipColor write FDefaultBlipColor;
    property HostileBlipColor: TColorB read FHostileBlipColor write FHostileBlipColor;
    property FriendlyBlipColor: TColorB read FFriendlyBlipColor write FFriendlyBlipColor;

    // Новые свойства для стиля Everspace 2
    property ScreenMargin: Integer read FScreenMargin write FScreenMargin;
    property EdgeMarkerSize: Integer read FEdgeMarkerSize write FEdgeMarkerSize;
    property ViewAngle: Single read FViewAngle write FViewAngle;
    property MaxRange: Single read FMaxRange write FMaxRange;
    property HostileColor: TColorB read FHostileColor write FHostileColor;
    property FriendlyColor: TColorB read FFriendlyColor write FFriendlyColor;
    property NeutralColor: TColorB read FNeutralColor write FNeutralColor;
    property ObjectiveColor: TColorB read FObjectiveColor write FObjectiveColor;
  end;

implementation

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

function TSpaceEngine.GetModelActor(const Index: Integer): TSpaceActor;
begin
  if (FActorList <> nil) and (Index >= 0) and (Index < FActorList.Count) then
    Result := TSpaceActor(FActorList[Index])
  else
    Result := nil;
end;

constructor TSpaceEngine.Create;
begin
  FActorList := TList.Create;
  FDeadActorList := TList.Create;
  FSpaceDust := TSpaceDust.Create(50, 500);
  CrosshairNear := TSpaceCrosshair.Create(nil);
  CrosshairFar := TSpaceCrosshair.Create(nil);

  // Initialize R3D with default settings


  // Set default texture filtering
 // R3D_SetTextureFilter(TEXTURE_FILTER_BILINEAR);

  // Create skybox
  //FSkyBoxQuality := SBQOriginal;
  //FUsesSkyBox := false;
 //FSkyBox := R3D_LoadSkybox('cubemap.png', CUBEMAP_LAYOUT_AUTO_DETECT);

 // img := LoadImage('test.png');
//  FSkyBox := R3D_LoadSkyboxPanorama('HDR_silver_and_gold_nebulae.hdr', 2048*2);
 // GenerateSkyBox(2048, Red, 256);
//  R3D_EnableSkybox(FSkyBox);

 FRadar := TRadar.Create(Self);
 //.. FRadar := TRadar.Create(Self); // PlayerActor будет установлен позже
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
    //CrosshairNear.DrawCrosshair();
    //CrosshairFar.DrawCrosshair();
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
//  FModel.transform := GetColliderTransform(@FCollider);
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
  FPosition := Vector2Create(20, 20);
 // FSize := 180;
  FRange := 1000;
  FBackgroundColor := ColorCreate(0, 0, 32, 200);
  FForegroundColor := ColorCreate(0, 200, 255, 220);
  FDefaultBlipColor := ColorCreate(255, 255, 0, 220);
  FHostileBlipColor := ColorCreate(255, 50, 50, 220);
  FFriendlyBlipColor := ColorCreate(50, 255, 50, 220);

  // Инициализация новых полей для стиля Everspace 2
  FScreenMargin := 1;
  FEdgeMarkerSize := 20;
  FViewAngle := 60 * DEG2RAD;
  FMaxRange := 2000;
  FHostileColor := RED;
  FFriendlyColor := GREEN;
  FNeutralColor := YELLOW;
  FObjectiveColor := ColorCreate(255, 165, 0, 255);
end;

procedure TRadar.SetPlayer(AValue: TSpaceActor);
begin
  if FPlayer = AValue then Exit;
  FPlayer := AValue;
end;

procedure TRadar.Draw(Camera: TSpaceCamera);
var
  i: Integer;
  actor: TSpaceActor;
  screenWidth, screenHeight: Integer;
  screenCenter: TVector2;
  relativePos, screenPos: TVector3;
  dir, localPos: TVector3;
  distance, angle, relAngle: Single;
  isOffScreen: Boolean;
  markerColor: TColorB;
  playerForward, playerRight, playerUp: TVector3;
  viewport: TRectangle;
  screenPos2D: TVector2;
begin
  if (FPlayer = nil) or (FEngine = nil) then Exit;

  // Получаем параметры экрана
  screenWidth := GetScreenWidth;
  screenHeight := GetScreenHeight;
  screenCenter := Vector2Create(screenWidth / 2, screenHeight / 2);
  viewport := RectangleCreate(0, 0, screenWidth, screenHeight);

  // Получаем ориентацию игрока
  playerForward := FPlayer.GetForward;
  playerRight := FPlayer.GetRight;
  playerUp := FPlayer.GetUp;

  // Отрисовка всех объектов
  for i := 0 to FEngine.Count - 1 do
  begin
    actor := FEngine[i];
    if (actor = FPlayer) or (not actor.Visible) then Continue;

    // Вычисляем относительную позицию
    relativePos := Vector3Subtract(actor.Position, FPlayer.Position);
    distance := Vector3Length(relativePos);
    if distance > FMaxRange then Continue;

    // Преобразуем в локальные координаты игрока
    dir := Vector3Normalize(relativePos);
    localPos.x := Vector3DotProduct(dir, playerRight);
    localPos.y := Vector3DotProduct(dir, playerUp);
    localPos.z := Vector3DotProduct(dir, playerForward);

    // Проецируем на экран
    angle := ArcTan2(localPos.x, localPos.z);
    relAngle := Abs(angle);
    isOffScreen := (relAngle > FViewAngle/2) or (localPos.z <= 0);

    // Выбираем цвет метки
    case actor.Tag of
      1: markerColor := FHostileColor;    // Враги
      2: markerColor := FFriendlyColor;   // Союзники
      3: markerColor := FNeutralColor;    // Нейтральные
      4: markerColor := FObjectiveColor;  // Цели квеста
      else markerColor := WHITE;
    end;

    if not isOffScreen then
    begin
      // Объект в поле зрения - рисуем обычную метку
      screenPos2D := GetWorldToScreen(Vector3Add(FPlayer.Position, relativePos), Camera.Camera);
      if CheckCollisionPointRec(screenPos2D, viewport) then
      begin
        // Треугольная метка с расстоянием
        DrawTriangle(
          Vector2Create(screenPos2D.x, screenPos2D.y - 12),
          Vector2Create(screenPos2D.x - 6, screenPos2D.y),
          Vector2Create(screenPos2D.x + 6, screenPos2D.y),
          ColorAlpha(markerColor,0.6) );

        // Текст с расстоянием
        DrawText(PChar(Format('%.0fm', [distance])),
          Round(screenPos2D.x - 20), Round(screenPos2D.y + 10), 10, WHITE);
      end;
    end
    else
    begin
      // Объект вне поля зрения - рисуем метку на границе
     // if localPos.z > 0 then // Только если объект перед камерой
     // begin
        // Нормализуем угол
        angle := Clamp(angle, -FViewAngle/2, FViewAngle/2);

        // Вычисляем позицию на границе экрана
        screenPos.x := screenCenter.x + Tan(angle) * screenCenter.x;
        screenPos.y := screenCenter.y - (localPos.y / Cos(angle)) * screenCenter.y;

        // Ограничиваем позицию границами экрана
        screenPos.x := Clamp(screenPos.x, FScreenMargin, screenWidth - FScreenMargin);
        screenPos.y := Clamp(screenPos.y, FScreenMargin, screenHeight - FScreenMargin);

        // Рисуем стрелку направления
        DrawTriangle(
          Vector2Create(screenPos.x, screenPos.y - FEdgeMarkerSize),
          Vector2Create(screenPos.x - FEdgeMarkerSize/2, screenPos.y),
          Vector2Create(screenPos.x + FEdgeMarkerSize/2, screenPos.y),
          ColorAlpha(markerColor,0.6));
             // Текст с расстоянием
        DrawText(PChar(Format('%.0fm', [distance])),
          Round(screenPos.x - 20), Round(screenPos.y + 10), 10, WHITE);
        // Линия к краю экрана
       // DrawLineEx(
       //   Vector2Create(screenPos.x, screenPos.y),
       //   Vector2Create(screenCenter.x, screenCenter.y),
       //   1, ColorAlpha(markerColor, 0.6));
     // end;
    end;
  end;
end;




end.

