unit ScreenSpace;

{$mode ObjFPC}{$H+}
{$define DEBUG}


interface

uses
  RayLib, RayMath, Classes, SysUtils, ScreenManager, SpaceEngine, r3d;

type

  { TScreenSpace }

  TScreenSpace = class(TGameScreen)
  private
    Engine: TSpaceEngine;
    Ship, Ship2, Ship3: TSpaceActor;
    ShipModel, ShipModel2: TR3D_Model;

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

{ TScreenSpace }



procedure TScreenSpace.Init;

begin
  Engine := TSpaceEngine.Create;
  Engine.CrosshairFar.Create('data' + '/models/UI/crosshair2.gltf');
  Engine.CrosshairNear.Create('data' + '/models/UI/crosshair.gltf');
  Engine.LoadSkyBox('HDR_marslike_planet_close.hdr', SQHigh, STPanorama);
  Engine.EnableSkybox;
  Engine.Light[0] := R3D_CreateLight(R3D_LIGHT_DIR);

  R3D_LightLookAt(Engine.Light[0], Vector3Create( 0, 10, 5 ), Vector3Create(0,0,0));
  R3D_SetLightActive(Engine.Light[0], true);
  R3D_EnableShadow(Engine.Light[0], 4096);

  Camera := TSpaceCamera.Create(True, 50);
  R3D_SetModelImportScale(0.05);

  ShipModel := R3D_LoadModel(('data' + '/models/untitled.glb'));

  R3D_SetModelImportScale(0.05);
  ShipModel2 := R3D_LoadModel(('data' + '/models/untitled.glb'));

  Ship := TSpaceActor.Create(Engine);
  Ship.ColliderType:= ctBox;
  Ship.ActorModel := ShipModel;
  Ship.DoCollision := True;
  Ship.AlignToHorizon:=False;
  Ship.MaxSpeed:=100;

  Ship2 := TSpaceActor.Create(Engine);
  Ship2.ColliderType:= ctBox;
  Ship2.SphereColliderSize:=17;
  Ship2.ActorModel := ShipModel2;
  Ship2.Position := Vector3Create(10,10,10);
  Ship2.DoCollision:= TRUE;

  Ship2.Tag:=1;
  Ship.MaxSpeed:=20;


  Ship3 := TSpaceActor.Create(Engine);
  Ship3.ColliderType:= ctBox;
  Ship3.SphereColliderSize:=17;
  Ship3.ActorModel := R3D_LoadModel(('data' + '/models/untitled.glb')); ;
  Ship3.Position := Vector3Create(10, - 10,100);
  Ship3.DoCollision:= TRUE;
  Ship3.Scale:=20;
  Ship3.Tag:=3;


  {
  Engine.Radar.Player := Ship;
  Engine.Radar.Position := Vector2Create(20, 20);
  Engine.Radar.Size := 180; // Ширина (высота будет вычислена автоматически)
  Engine.Radar.DefaultBlipColor := YELLOW; // Цвет по умолчанию для нейтральных объектов
  Engine.Radar.Range:=500;
 }

 // Engine.Radar.Range := 100;
 // Engine.Radar.BackgroundColor := ColorCreate(0, 0, 50, 200);
  Engine.Radar.Player := Ship;



 // Engine.CrosshairFar.ApplyBlend;

 // Material.emission.color := BLUE;
 // Material.emission.energy := 200.0;
 // Material.albedo.color := BLACK;

 // Ship.ActorModel.materials[1]:= Material;

 Ship.EngineLeftPoint[0] := Vector3Create(
    Ship.ActorModel.meshes[0].vertices[6].position.x,
    Ship.ActorModel.meshes[0].vertices[7].position.y,
    Ship.ActorModel.meshes[0].vertices[8].position.z
  );

  Ship.EngineRightPoint[0] := Vector3Create(
    Ship.ActorModel.meshes[0].vertices[3].position.x,
    Ship.ActorModel.meshes[0].vertices[4].position.y,
    Ship.ActorModel.meshes[0].vertices[5].position.z);

 { Ship.EngineLeftPoint[0]  := Vector3Create(Ship.ActorModel.meshes[1].vertices[6],
                                            Ship.ActorModel.meshes[1].vertices[7],
                                            Ship.ActorModel.meshes[1].vertices[8]);
  }
 { Ship.EngineRightPoint[0] := Vector3Create(Ship.ActorModel.meshes[1].vertices[3],
                                            Ship.ActorModel.meshes[1].vertices[4],
                                            Ship.ActorModel.meshes[1].vertices[5]);

  }
  //Vector3Create( 0.10819 , -0.04508, -0.21762);

  Ship.EngineLeftPoint[1]  := Vector3Create( -0.10860 , -0.04508, -0.21762);
  Ship.EngineRightPoint[1] := Vector3Create( -0.25327 , -0.04508, -0.21762);
 {
     for i := 0  to Fmodel.meshes[1].vertexCount -1 do
    begin
    vec := Vector3Create(FModel.meshes[1].vertices[i * 3],   }
  end;

procedure TScreenSpace.Shutdown;
begin
  Engine.Destroy;
  // R3D_UnloadModel(@ShipModel, true);



end;

procedure TScreenSpace.Update(MoveCount: Single);

begin
  Engine.Update(MoveCount, Ship.Position);



//  R3D_SetBloomIntensity(R3D_GetBloomIntensity() +  0.01);

 // Ship.ActorModel.materials[1].emission.energy :=  Ship.GetSpeed * 100;//Clamp(Ship.GetSpeed / Ship.MaxSpeed, 80, 100);
  //Ship.ActorModel.materials[0]   Material.emission.energy := 100.0;


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

