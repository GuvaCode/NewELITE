unit ProceduralSkybox;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, Raylib, Rlgl, RayMath;

type
  TSkyboxFace = (sfFront, sfBack, sfLeft, sfRight, sfTop, sfBottom);

  { TProceduralSkybox }

  TProceduralSkybox = class
  private
    FSeed: Cardinal;
    FResolution: Integer;
    FPointStars: Boolean;
    FStars: Boolean;
    FSun: Boolean;
    FNebulae: Boolean;
    FTextures: array[TSkyboxFace] of TTexture2D;

    function GenerateFace(Face: TSkyboxFace): TTexture2D;
    function RandomVec3: TVector3;
    function Hash(const S: String): Cardinal;
    function Noise(x, y, z: Single): Single;
    function NebulaNoise(p: TVector3; scale, intensity, falloff: Single; offset: TVector3): Single;
    function GetTexture(Face: TSkyboxFace): TTexture2D;
  public
    constructor Create(Seed: Cardinal; Resolution: Integer;
      PointStars, Stars, Sun, Nebulae: Boolean);
    destructor Destroy; override;

    procedure Regenerate;

    property Textures[Face: TSkyboxFace]: TTexture2D read GetTexture; default;
  end;

implementation

{ TProceduralSkybox }

constructor TProceduralSkybox.Create(Seed: Cardinal; Resolution: Integer;
  PointStars, Stars, Sun, Nebulae: Boolean);
begin
  FSeed := Seed;
  FResolution := Resolution;
  FPointStars := PointStars;
  FStars := Stars;
  FSun := Sun;
  FNebulae := Nebulae;

  RandSeed := FSeed;
  Regenerate;
end;

destructor TProceduralSkybox.Destroy;
var
  Face: TSkyboxFace;
begin
  for Face := Low(TSkyboxFace) to High(TSkyboxFace) do
    UnloadTexture(FTextures[Face]);
  inherited Destroy;
end;

procedure TProceduralSkybox.Regenerate;
var
  Face: TSkyboxFace;
begin
  RandSeed := FSeed;

  for Face := Low(TSkyboxFace) to High(TSkyboxFace) do
  begin
    if FTextures[Face].id <> 0 then
      UnloadTexture(FTextures[Face]);
    FTextures[Face] := GenerateFace(Face);
  end;
end;

function TProceduralSkybox.GenerateFace(Face: TSkyboxFace): TTexture2D;
var
  Image: TImage;
  x, y: Integer;
  uv, dir: TVector2;
  rayDir: TVector3;
  color: TColorB;
  t, starIntensity, nebulaValue, sunIntensity: Single;
  i: Integer;

  // Star parameters
  starPositions: array of TVector3;
  starColors: array of TColor;
  starSizes: array of Single;

  // Nebula parameters
  nebulaScales: array of Single;
  nebulaColors: array of TColor;
  nebulaIntensities: array of Single;
  nebulaOffsets: array of TVector3;

  // Sun parameters
  sunPos: TVector3;
  sunColor: TColor;
  sunSize: Single;
begin
  // Create image
  Image := GenImageColor(FResolution, FResolution, BLANK);

  // Generate random parameters based on seed
  SetLength(starPositions, 100);
  SetLength(starColors, 100);
  SetLength(starSizes, 100);

  for i := 0 to High(starPositions) do
  begin
    starPositions[i] := RandomVec3;
    starColors[i] := ColorCreate(
      Random(256),
      Random(256),
      Random(256),
      255
    );
    starSizes[i] := Random * 0.01 + 0.005;
  end;

  // Generate nebulae parameters
  SetLength(nebulaScales, 3);
  SetLength(nebulaColors, 3);
  SetLength(nebulaIntensities, 3);
  SetLength(nebulaOffsets, 3);

  for i := 0 to High(nebulaScales) do
  begin
    nebulaScales[i] := Random * 0.5 + 0.25;
    nebulaColors[i] := ColorCreate(
      Random(256),
      Random(256),
      Random(256),
      255
    );
    nebulaIntensities[i] := Random * 0.2 + 0.9;
    nebulaOffsets[i] := Vector3Create(
      Random * 2000 - 1000,
      Random * 2000 - 1000,
      Random * 2000 - 1000
    );
  end;

  // Generate sun parameters
  sunPos := RandomVec3;
  sunColor := ColorCreate(
    Random(256),
    Random(200) + 55,
    Random(100) + 50,
    255
  );
  sunSize := Random * 0.0001 + 0.0001;

  // Generate face
  for y := 0 to FResolution - 1 do
  begin
    for x := 0 to FResolution - 1 do
    begin
      uv := Vector2Create(
        (x / (FResolution - 1)) * 2 - 1,
        (y / (FResolution - 1)) * 2 - 1
      );

      // Determine ray direction based on face
      case Face of
        sfFront:  rayDir := Vector3Create(uv.x, uv.y, -1);
        sfBack:   rayDir := Vector3Create(uv.x, uv.y, 1);
        sfLeft:   rayDir := Vector3Create(-1, uv.y, uv.x);
        sfRight:  rayDir := Vector3Create(1, uv.y, -uv.x);
        sfTop:    rayDir := Vector3Create(uv.x, 1, -uv.y);
        sfBottom: rayDir := Vector3Create(uv.x, -1, uv.y);
      end;

      rayDir := Vector3Normalize(rayDir);

      // Start with black
      color := BLACK;

      // Add point stars (background stars)
      if FPointStars then
      begin
        t := Power(Random, 4.0);
        if t > 0.999 then
        begin
          color := ColorCreate(
            Round(t * 255),
            Round(t * 255),
            Round(t * 255),
            255
          );
        end;
      end;

      // Add bright stars
      if FStars then
      begin
        for i := 0 to High(starPositions) do
        begin
          starIntensity := 1.0 - Min(1.0, Vector3Distance(rayDir, starPositions[i]) / starSizes[i]);
          if starIntensity > 0 then
          begin
            starIntensity := Exp(-(1.0 - starIntensity) * 20.0);
            color := White;//ColorAdd(color, ColorAlpha(starColors[i], starIntensity));
          end;
        end;
      end;

      // Add nebulae
      if FNebulae then
      begin
        for i := 0 to High(nebulaScales) do
        begin
          nebulaValue := NebulaNoise(
            rayDir,
            nebulaScales[i],
            nebulaIntensities[i],
            3.0 + Random * 3.0,
            nebulaOffsets[i]
          );

          if nebulaValue > 0.1 then
          begin
            nebulaValue := Power(nebulaValue, 3.0 + Random * 3.0);
            color := WHITE;// ColorAdd(color, ColorAlpha(nebulaColors[i], nebulaValue));
          end;
        end;
      end;

      // Add sun
      if FSun then
      begin
        sunIntensity := Vector3DotProduct(rayDir, sunPos);
        //sunIntensity := SmoothStep(1.0 - sunSize * 32.0, 1.0 - sunSize, sunIntensity);
        sunIntensity := sunIntensity + Power(sunIntensity, 8.0 + Random * 16.0) * 0.5;

        if sunIntensity > 0 then
        begin
          color := WJITE;//ColorAdd(color, ColorAlpha(sunColor, sunIntensity));
        end;
      end;

      // Clamp color
      color.r := Min(color.r, 255);
      color.g := Min(color.g, 255);
      color.b := Min(color.b, 255);

      ImageDrawPixel(@Image, x, y, color);
    end;
  end;

  Result := LoadTextureFromImage(Image);
  UnloadImage(Image);
end;

function TProceduralSkybox.RandomVec3: TVector3;
begin
  Result := Vector3Create(
    Random * 2 - 1,
    Random * 2 - 1,
    Random * 2 - 1
  );
  Result := Vector3Normalize(Result);
end;

function TProceduralSkybox.Hash(const S: String): Cardinal;
var
  i: Integer;
begin
  Result := 0;
  for i := 1 to Length(S) do
    Result := Result + (i * Ord(S[i]));
end;

function TProceduralSkybox.Noise(x, y, z: Single): Single;
begin
  Result := Sin(x * 12.9898 + y * 78.233 + z * 144.7272) * 43758.5453;
  Result := Result - Floor(Result);
end;

function TProceduralSkybox.NebulaNoise(p: TVector3; scale, intensity, falloff: Single; offset: TVector3): Single;
const
  steps = 6;
var
  i: Integer;
  displace: TVector3;
  currentScale: Single;
begin
  currentScale := Power(2.0, steps);
  displace := Vector3Create(0, 0, 0);

  for i := 0 to steps - 1 do
  begin
    displace.x := Noise(
      p.x * currentScale + displace.x + offset.x,
      p.y * currentScale + displace.y + offset.y,
      p.z * currentScale + displace.z + offset.z
    );

    displace.y := Noise(
      p.y * currentScale + displace.y + offset.y,
      p.z * currentScale + displace.z + offset.z,
      p.x * currentScale + displace.x + offset.x
    );

    displace.z := Noise(
      p.z * currentScale + displace.z + offset.z,
      p.x * currentScale + displace.x + offset.x,
      p.y * currentScale + displace.y + offset.y
    );

    currentScale := currentScale * 0.5;
  end;

  Result := Noise(
    p.x * currentScale + displace.x + offset.x,
    p.y * currentScale + displace.y + offset.y,
    p.z * currentScale + displace.z + offset.z
  );

  Result := 0.5 * Result + 0.5;
  Result := Min(1.0, Result * intensity);
  Result := Power(Result, falloff);
end;

function TProceduralSkybox.GetTexture(Face: TSkyboxFace): TTexture2D;
begin
  Result := FTextures[Face];
end;

end.
