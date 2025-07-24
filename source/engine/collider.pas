unit Collider;

{$mode ObjFPC}{$H+}

interface

uses
  RayLib, RayMath, Math, SysUtils;

const
  COLLIDER_VERTEX_COUNT = 7;
  COLLIDER_NORMAL_COUNT = 3;

type
  TColliderType = (ctBox, ctSphere);
  PCollider = ^TCollider;
  TCollider = record
    ColliderType: TColliderType;  // Тип коллайдера должен быть объявлен отдельно
    matRotate: TMatrix;           // Общие поля выносятся перед вариантной частью
    matTranslate: TMatrix;
    case TColliderType of         // Вариантная часть без объявления поля
      ctBox: (
        vertLocal: array[0..COLLIDER_VERTEX_COUNT] of TVector3;
        vertGlobal: array[0..COLLIDER_VERTEX_COUNT] of TVector3;
      );
      ctSphere: (
        Radius: Single;
        CenterLocal: TVector3;
        CenterGlobal: TVector3;
      );
  end;

function CreateCollider(min, max: TVector3): TCollider;
function CreateSphereCollider(center: TVector3; radius: Single): TCollider;

procedure SetColliderRotation(col: PCollider; axis: TVector3; ang: Single);
procedure SetColliderRotation(col: PCollider; q: TQuaternion);
procedure AddColliderRotation(col: PCollider; axis: TVector3; ang: Single);
procedure AddColliderRotation(col: PCollider; q: TQuaternion);

procedure SetColliderTranslation(col: PCollider; pos: TVector3);
procedure AddColliderTranslation(col: PCollider; pos: TVector3);

function GetColliderTransform(col: PCollider): TMatrix;
function TestColliderPoint(col: PCollider; point: TVector3): Boolean;
function TestColliderPair(a, b: PCollider): Boolean;
function GetCollisionCorrection(a, b: PCollider): TVector3;

implementation

procedure UpdateColliderGlobalVerts(col: PCollider);
var
  matTemp: TMatrix;
  i: Integer;
begin
  matTemp := MatrixMultiply(col^.matRotate, col^.matTranslate);

  case col^.ColliderType of
    ctBox:
      for i := 0 to COLLIDER_VERTEX_COUNT do
        col^.vertGlobal[i] := Vector3Transform(col^.vertLocal[i], matTemp);
    ctSphere:
      col^.CenterGlobal := Vector3Transform(col^.CenterLocal, matTemp);
  end;
end;

function CreateCollider(min, max: TVector3): TCollider;
begin
  Result.ColliderType := ctBox;
  Result.vertLocal[0] := Vector3Create(min.x, min.y, min.z);
  Result.vertLocal[1] := Vector3Create(min.x, min.y, max.z);
  Result.vertLocal[2] := Vector3Create(min.x, max.y, min.z);
  Result.vertLocal[3] := Vector3Create(min.x, max.y, max.z);
  Result.vertLocal[4] := Vector3Create(max.x, min.y, min.z);
  Result.vertLocal[5] := Vector3Create(max.x, min.y, max.z);
  Result.vertLocal[6] := Vector3Create(max.x, max.y, min.z);
  Result.vertLocal[7] := Vector3Create(max.x, max.y, max.z);

  Result.matRotate := MatrixIdentity();
  Result.matTranslate := MatrixIdentity();
  UpdateColliderGlobalVerts(@Result);
end;

function CreateSphereCollider(center: TVector3; radius: Single): TCollider;
begin
  Result.ColliderType := ctSphere;
  Result.CenterLocal := center;
  Result.Radius := radius;
  Result.matRotate := MatrixIdentity();
  Result.matTranslate := MatrixIdentity();
  UpdateColliderGlobalVerts(@Result);
end;

procedure SetColliderRotation(col: PCollider; axis: TVector3; ang: Single);
begin
  col^.matRotate := MatrixRotate(axis, ang);
  UpdateColliderGlobalVerts(col);
end;

procedure SetColliderRotation(col: PCollider; q: TQuaternion);
begin
  col^.matRotate := QuaternionToMatrix(q);
  UpdateColliderGlobalVerts(col);
end;

procedure AddColliderRotation(col: PCollider; axis: TVector3; ang: Single);
var
  matTemp: TMatrix;
begin
  matTemp := MatrixRotate(axis, ang);
  col^.matRotate := MatrixMultiply(col^.matRotate, matTemp);
  UpdateColliderGlobalVerts(col);
end;

procedure AddColliderRotation(col: PCollider; q: TQuaternion);
var
  matTemp: TMatrix;
begin
  matTemp := QuaternionToMatrix(q);
  col^.matRotate := MatrixMultiply(col^.matRotate, matTemp);
  UpdateColliderGlobalVerts(col);
end;

procedure SetColliderTranslation(col: PCollider; pos: TVector3);
begin
   col^.matTranslate := MatrixTranslate(pos.x, pos.y, pos.z);
   UpdateColliderGlobalVerts(col);
end;

procedure AddColliderTranslation(col: PCollider; pos: TVector3);
var
  matTemp: TMatrix;
begin
  matTemp := MatrixTranslate(pos.x, pos.y, pos.z);
  col^.matTranslate := MatrixMultiply(col^.matTranslate, matTemp);
  UpdateColliderGlobalVerts(col);
end;

function GetColliderTransform(col: PCollider): TMatrix;
begin
  Result := MatrixMultiply(col^.matRotate, col^.matTranslate);
end;

function TestBoxPoint(col: PCollider; point: TVector3): Boolean;
var
  i: Integer;
  min, max, cur: TVector3;
  invTransform: TMatrix;
begin
  min := col^.vertLocal[0];
  max := col^.vertLocal[0];
  for i := 1 to COLLIDER_VERTEX_COUNT do
  begin
    cur := col^.vertLocal[i];
    min.x := math.Min(min.x, cur.x);
    min.y := math.Min(min.y, cur.y);
    min.z := math.Min(min.z, cur.z);
    max.x := math.Max(max.x, cur.x);
    max.y := math.Max(max.y, cur.y);
    max.z := math.Max(max.z, cur.z);
  end;

  invTransform := MatrixInvert(GetColliderTransform(col));
  point := Vector3Transform(point, invTransform);

  Result := (point.x < max.x) and (point.x > min.x) and
            (point.y < max.y) and (point.y > min.y) and
            (point.z < max.z) and (point.z > min.z);
end;

function TestSpherePoint(col: PCollider; point: TVector3): Boolean;
var
  distance: Single;
begin
  distance := Vector3Distance(col^.CenterGlobal, point);
  Result := distance <= col^.Radius;
end;

function TestColliderPoint(col: PCollider; point: TVector3): Boolean;
begin
  case col^.ColliderType of
    ctBox: Result := TestBoxPoint(col, point);
    ctSphere: Result := TestSpherePoint(col, point);
  end;
end;

procedure GetCollisionVectors(a, b: PCollider; vec: PVector3);
var
  x, y, z: TVector3;
  i, j, k: Integer;
begin
  x := Vector3Create(1.0, 0.0, 0.0);
  y := Vector3Create(0.0, 1.0, 0.0);
  z := Vector3Create(0.0, 0.0, 1.0);

  vec[0] := Vector3Transform(x, a^.matRotate);
  vec[1] := Vector3Transform(y, a^.matRotate);
  vec[2] := Vector3Transform(z, a^.matRotate);

  vec[3] := Vector3Transform(x, b^.matRotate);
  vec[4] := Vector3Transform(y, b^.matRotate);
  vec[5] := Vector3Transform(z, b^.matRotate);

  i := 6;
  for j := 0 to 2 do
  begin
    for k := 3 to 5 do
    begin
      if Vector3Equals(vec[j], vec[k]) > 0 then
        vec[i] := x
      else
        vec[i] := Vector3Normalize(Vector3CrossProduct(vec[j], vec[k]));
      Inc(i);
    end;
  end;
end;

function GetColliderProjectionBounds(col: PCollider; vec: TVector3): TVector2;
var
  bounds: TVector2;
  proj: Single;
  i: Integer;
begin
  case col^.ColliderType of
    ctBox:
    begin
      proj := Vector3DotProduct(col^.vertGlobal[0], vec);
      bounds.x := proj;
      bounds.y := proj;
      for i := 1 to COLLIDER_VERTEX_COUNT do
      begin
        proj := Vector3DotProduct(col^.vertGlobal[i], vec);
        bounds.x := Min(bounds.x, proj);
        bounds.y := Max(bounds.y, proj);
      end;
    end;
    ctSphere:
    begin
      proj := Vector3DotProduct(col^.CenterGlobal, vec);
      bounds.x := proj - col^.Radius;
      bounds.y := proj + col^.Radius;
    end;
  end;
  Result := bounds;
end;

function BoundsOverlap(a, b: TVector2): Boolean;
begin
  if a.x > b.y then Exit(False);
  if b.x > a.y then Exit(False);
  Result := True;
end;

function GetOverlap(a, b: TVector2): Single;
begin
  if a.x > b.y then Exit(0.0);
  if b.x > a.y then Exit(0.0);
  if a.x > b.x then
    Result := b.y - a.x
  else
    Result := b.x - a.y;
end;

function TestBoxBox(a, b: PCollider): Boolean;
var
  testVec: array[0..14] of TVector3;
  apro, bpro: TVector2;
  i: Integer;
begin
  Result := False;
  GetCollisionVectors(a, b, @testVec);
  for i := 0 to 14 do
  begin
    apro := GetColliderProjectionBounds(a, testVec[i]);
    bpro := GetColliderProjectionBounds(b, testVec[i]);
    if not BoundsOverlap(apro, bpro) then
    begin
      Result := False;
      Exit;
    end;
  end;
  Result := True;
end;

function TestSphereSphere(a, b: PCollider): Boolean;
var
  distance: Single;
begin
  distance := Vector3Distance(a^.CenterGlobal, b^.CenterGlobal);
  Result := distance <= (a^.Radius + b^.Radius);
end;

function TestSphereBox(sphere, box: PCollider): Boolean;
var
  closestPoint, sphereCenter: TVector3;
  boxMin, boxMax: TVector3;
  distance, radius: Single;
  i: Integer;
begin
  sphereCenter := sphere^.CenterGlobal;
  radius := sphere^.Radius;

  // Находим границы бокса
  boxMin := box^.vertGlobal[0];
  boxMax := box^.vertGlobal[0];
  for i := 1 to COLLIDER_VERTEX_COUNT do
  begin
    boxMin := Vector3Min(boxMin, box^.vertGlobal[i]);
    boxMax := Vector3Max(boxMax, box^.vertGlobal[i]);
  end;

  // Находим ближайшую точку на боксе
  closestPoint := Vector3Create(
    Clamp(sphereCenter.x, boxMin.x, boxMax.x),
    Clamp(sphereCenter.y, boxMin.y, boxMax.y),
    Clamp(sphereCenter.z, boxMin.z, boxMax.z)
  );

  // Проверяем расстояние
  distance := Vector3Distance(sphereCenter, closestPoint);
  Result := distance <= radius;
end;

function TestColliderPair(a, b: PCollider): Boolean;
begin
  if (a^.ColliderType = ctBox) and (b^.ColliderType = ctBox) then
    Result := TestBoxBox(a, b)
  else if (a^.ColliderType = ctSphere) and (b^.ColliderType = ctSphere) then
    Result := TestSphereSphere(a, b)
  else if (a^.ColliderType = ctSphere) then
    Result := TestSphereBox(a, b)
  else
    Result := TestSphereBox(b, a);
end;

function GetBoxCorrection(a, b: PCollider): TVector3;
var
  overlapMin, overlap: Single;
  overlapDir: TVector3;
  testVec: array[0..14] of TVector3;
  apro, bpro: TVector2;
  i: Integer;
begin
  overlapMin := 100.0;
  overlapDir := Vector3Zero;
  GetCollisionVectors(a, b, @testVec);
  for i := 0 to 14 do
  begin
    apro := GetColliderProjectionBounds(a, testVec[i]);
    bpro := GetColliderProjectionBounds(b, testVec[i]);
    overlap := GetOverlap(apro, bpro);
    if overlap = 0.0 then Exit(Vector3Zero);
    if Abs(overlap) < Abs(overlapMin) then
    begin
      overlapMin := overlap;
      overlapDir := testVec[i];
    end;
  end;
  Result := Vector3Scale(overlapDir, overlapMin);
end;


function GetSphereCorrection(a, b: PCollider): TVector3;
var
  direction: TVector3;
  distance, overlap: Single;
  correctionFactor: Single;
begin
  if a^.ColliderType = ctSphere then
  begin
    if b^.ColliderType = ctSphere then
    begin
      // Сфера-сфера
      direction := Vector3Subtract(b^.CenterGlobal, a^.CenterGlobal);
      distance := Vector3Length(direction);
      overlap := (a^.Radius + b^.Radius) - distance;

      if distance > 0.001 then // Добавляем проверку на минимальное расстояние
      begin
        // Плавная коррекция с учётом массы (здесь можно добавить массу объектов)
        correctionFactor := 0.005; // Коэффициент смягчения
        Result := Vector3Scale(Vector3Normalize(direction), -overlap * correctionFactor);
      end
      else
        Result := Vector3Create(0, 0.01, 0); // Минимальный отскок при нулевом расстоянии
    end
    else
    begin
      // Сфера-бокс
      Result := GetBoxCorrection(b, a);
      // Смягчаем коррекцию для сферы
      Result := Vector3Scale(Result, -0.007); // Уменьшаем силу отскока
    end;
  end
  else
  begin
    // Бокс-сфера
    Result := GetBoxCorrection(a, b);
    // Смягчаем коррекцию для сферы
    Result := Vector3Scale(Result, 0.007); // Уменьшаем силу отскока
  end;
end;

function GetCollisionCorrection(a, b: PCollider): TVector3;
begin
  if (a^.ColliderType = ctBox) and (b^.ColliderType = ctBox) then
    Result := GetBoxCorrection(a, b)
  else
    Result := GetSphereCorrection(a, b);
end;

end.
