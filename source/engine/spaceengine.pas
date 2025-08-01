unit SpaceEngine;

{$mode ObjFPC}{$H+}

interface

uses
  raylib, raymath, rlgl, Math, DigestMath, Collider, Classes, SysUtils, r3d;

type
  // Типы качества скайбокса с соответствующими размерами текстур
  TSkyBoxQuality = (SQLow = 512, SQNormal = 1024, SQHigh = 2048, SQVeryHigh = 4096);
  TSkyBoxType = (STPanorama, STCubemap);   // Тип скайбокса: панорамный или кубическая карта
  TColliderType = (ctBox, ctSphere);   // Типы коллайдеров для столкновений
  TShipType = (Unknow, Asteroid, Police, Station, Neutral, Pirate, Missle, Beacon, Container, Enemy);  // Типы космических объектов/кораблей

  { TSpaceDust }
  // Класс для визуализации космической пыли
  TSpaceDust = class
  private
    FPoints: array of TVector3;  // Массив позиций частиц пыли
    FColors: array of TColorB;    // Массив цветов частиц
    FExtent: Single;              // Размер области с частицами
  public
    // Инициализация с указанием размера области и количества частиц
    constructor Create(Size: single; Count:integer); virtual;
    // Обновление позиций частиц относительно позиции камеры
    procedure UpdateViewPosition(ViewPosition: TVector3);
    // Отрисовка частиц с учетом скорости и опции отрисовки точек
    procedure Draw(ViewPosition, Velocity: TVector3; DrawDots: boolean);
  end;

  // Затычка классов для взаимных ссылок
  TSpaceActor = class;
  TRadar = class;

  { TSpaceCrosshair }
  // Класс для отображения прицела в 3D пространстве
  TSpaceCrosshair = class
  private
    FCrosshairColor: TColorB;  // Цвет прицела
    FCrosshairModel: TModel;   // 3D модель прицела
  public
    // Создание прицела с загрузкой модели из файла
    constructor Create(const modelFileName: PChar); virtual;
    destructor Destroy; override;
    // Позиционирование прицела на акторе с заданным расстоянием
    procedure PositionCrosshairOnActor(const Actor: TSpaceActor; distance: Single);
    // Отрисовка прицела с эффектом добавления
    procedure DrawCrosshair;
    property CrosshairColor: TColorB read FCrosshairColor write FCrosshairColor;
  end;

  { TSpaceCamera }
  // Класс 3D камеры с плавным перемещением
  TSpaceCamera = class
  private
    FSmoothPosition: TVector3;  // Сглаженная позиция камеры
    FSmoothTarget: TVector3;    // Сглаженная цель камеры
    FSmoothUp: TVector3;        // Сглаженный вектор "вверх"
  public
    Camera: TCamera3D;          // Базовая камера Raylib
    // Создание камеры с указанием типа проекции и угла обзора
    constructor Create(isPerspective:boolean; fieldOfView: single); virtual;
    // Начало 3D-рендеринга
    procedure BeginDrawing;
    // Завершение 3D-рендеринга
    procedure EndDrawing;
    // Плавное следование камеры за актором
    procedure FollowActor(const Actor: TSpaceActor; deltaTime: Single);
    // Плавное перемещение камеры в указанную позицию
    procedure MoveTo(position_, target, up: TVector3; deltaTime: Single);
    // Мгновенное установление позиции камеры
    procedure SetPosition(position_, target, up: TVector3);
    // Получение текущей позиции камеры
    function GetPosition: TVector3;
    // Получение текущей цели камеры
    function GetTarget: TVector3;
    // Получение текущего вектора "вверх"
    function GetUp: TVector3;
    // Получение угла обзора камеры
    function GetFovy: Single;
  end;

  { TSpaceEngine }
  // Основной класс игрового движка космического симулятора
  TSpaceEngine = class
  private
    FActorList: TList;          // Список активных акторов
    FDeadActorList: TList;      // Список уничтоженных акторов
    FLight: array[0..3] of TR3D_Light;  // Источники освещения
    FMouseForFly: Boolean;      // Флаг управления мышью
    FSpaceDust: TSpaceDust;     // Эффект космической пыли
    FSkyBox: TR3D_Skybox;       // Скайбокс
    FRadar: TRadar;             // Радар
    // Получение количества акторов
    function GetCount: Integer;
    // Получение источника света по индексу
    function GetLight(const Index: Integer): TR3D_Light;
    // Получение актора по индексу
    function GetModelActor(const Index: Integer): TSpaceActor;
    // Установка источника света по индексу
    procedure SetLight(const Index: Integer; AValue: TR3D_Light);
  public
    CrosshairNear, CrosshairFar: TSpaceCrosshair;  // Ближний и дальний прицелы
    constructor Create;
    destructor Destroy; override;
    // Добавление актора в движок
    procedure Add(const ModelActor: TSpaceActor);
    // Удаление актора из движка
    procedure Remove(const ModelActor: TSpaceActor);
    // Перемещение актора в другой движок
    procedure Change(ModelActor: TSpaceActor; Dest: TSpaceEngine);
    // Обновление состояния движка
    procedure Update(DeltaTime: Single; DustViewPosition: TVector3);
    // Отрисовка сцены
    procedure Render(Camera: TSpaceCamera; ShowDebugAxes, {%H-}ShowDebugRay: Boolean; DustVelocity: TVector3; DustDrawDots: boolean);
    // Проверка столкновений
    procedure Collision;
    // Очистка всех акторов
    procedure Clear;
    // Очистка уничтоженных акторов
    procedure ClearDeadActor;
    // Загрузка скайбокса из файла
    procedure LoadSkyBox(FileName: String; Quality: TSkyBoxQuality; SkyBoxType: TSkyBoxType);
    // Загрузка скайбокса из памяти
    procedure LoadSkyBoxFromMemory(SkyBoxImage: TImage; Quality: TSkyBoxQuality; SkyBoxType: TSkyBoxType);
    // Включение скайбокса
    procedure EnableSkybox;
    // Выключение скайбокса
    procedure DisableSkybox;
    // Применение управления к кораблю
    procedure ApplyInputToShip(Ship: TSpaceActor; Step: Single);
    property MouseForFly: Boolean read FMouseForFly write FMouseForFly;
    property Items[const Index: Integer]: TSpaceActor read GetModelActor; default;
    property Light[const Index: Integer]: TR3D_Light read GetLight write SetLight;
    property Count: Integer read GetCount;
    property Radar: TRadar read FRadar write FRadar;
  end;


  { TSpaceActor }
   // Базовый класс для всех объектов в космосе
   TSpaceActor = class
   private
     FCurrentSpeed: Single;       // Текущая скорость (для плавного изменения)
     FActorIndex: Integer;        // Индекс актора
     FAlignToHorizon: Boolean;    // Флаг выравнивания к горизонту
     FColliderType: TColliderType;// Тип коллайдера
     FDoCollision: Boolean;       // Флаг обработки столкновений
     FLastCollisionTime: Single;  // Время последнего столкновения
     FEngine: TSpaceEngine;       // Ссылка на движок
     FMaxSpeed: Single;           // Максимальная скорость
     FModel: TR3D_Model;          // 3D модель
     FModelTransform: TMatrix;    // Матрица трансформации модели
     FProjection: TVector4;       // Проекционные параметры
     FShipType: TShipType;        // Тип корабля/объекта
     // Плавные значения ввода управления
     FSmoothForward: Single;
     FSmoothLeft: Single;
     FSmoothUp: Single;
     FSmoothPitchDown: Single;
     FSmoothRollRight: Single;
     FSmoothYawLeft: Single;
     FPosition: TVector3;         // Позиция в мире
     FRotation: TQuaternion;      // Вращение (кватернион)
     FScale: Single;              // Масштаб
     FSphereColliderSize: Single; // Размер сферического коллайдера
     FTag: Integer;               // Произвольная метка
     FIsDead: Boolean;            // Флаг уничтожения
     FThrottleResponse: Single;   // Отзывчивость двигателя
     FTrailColor: TColorB;        // Цвет следа
     FTurnRate: Single;           // Скорость поворота
     FTurnResponse: Single;       // Отзывчивость поворотов
     FVelocity: TVector3;         // Вектор скорости
     FVisualRotation: TQuaternion;// Визуальное вращение (с эффектом крена)
     FVisualBank: Single;         // Визуальный крен
     FVisible: Boolean;           // Флаг видимости
     FRay: TRay;                  // Луч для проверки пересечений
     FCollider: TCollider;        // Коллайдер
     // Установка 3D модели с автоматическим созданием коллайдера
     procedure SetModel(AValue: TR3D_Model);
     // Установка позиции с обновлением коллайдера
     procedure SetPosition(AValue: TVector3);
     // Установка масштаба с обновлением коллайдера
     procedure SetScale(AValue: Single);
   public
     // Входные значения управления
     InputForward: Single;
     InputLeft: Single;
     InputUp: Single;
     InputPitchDown: Single;
     InputRollRight: Single;
     InputYawLeft: Single;
     // Создание актора с привязкой к движку
     constructor Create(const AParent: TSpaceEngine); virtual;
     destructor Destroy; override;
     // Обработка столкновения с другим актором
     procedure Collision(const Other: TSpaceActor); overload; virtual;
     // Проверка столкновений со всеми акторами
     procedure Collision; overload; virtual;
     // Помечает актор как уничтоженный
     procedure Dead; virtual;
     // Событие при столкновении (может быть переопределено)
     procedure OnCollision(const {%H-}Actor: TSpaceActor); virtual;
     // Обновление состояния актора
     procedure Update(const DeltaTime: Single); virtual;
     // Отрисовка актора
     procedure Render; virtual;
     // Получение вектора "вперед"
     function GetForward:TVector3;
     // Получение вектора "вперед" с заданной дистанцией
     function GetForward(Distance: Single): TVector3;
     // Получение вектора "назад"
     function GetBack:TVector3;
     // Получение вектора "назад" с заданной дистанцией
     function GetBack(Distance: Single): TVector3;
     // Получение вектора "вправо"
     function GetRight:TVector3;
     // Получение вектора "вправо" с заданной дистанцией
     function GetRight(Distance: Single): TVector3;
     // Получение вектора "влево"
     function GetLeft:TVector3;
     // Получение вектора "влево" с заданной дистанцией
     function GetLeft(Distance: Single): TVector3;
     // Получение вектора "вверх"
     function GetUp:TVector3;
     // Получение вектора "вверх" с заданной дистанцией
     function GetUp(Distance: Single): TVector3;
     // Получение вектора "вниз"
     function GetDown:TVector3;
     // Получение вектора "вниз" с заданной дистанцией
     function GetDown(Distance: Single): TVector3;
     // Получение вектора скорости
     function GetVelocity: TVector3;
     // Получение текущей скорости (длина вектора скорости)
     function GetSpeed: Single;
     // Преобразование точки из локальных координат в мировые
     function TransformPoint(point: TVector3): TVector3;
     // Вращение вокруг локальной оси на заданный угол
     procedure RotateLocalEuler(axis: TVector3; degrees: single);
     // Поворот к другому актору
     procedure RotationToActor(targetActor: TSpaceActor; z_axis: boolean = false; deflection: Single = 0.05);
     // Поворот к заданному вектору
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
     property ShipType: TShipType read FShipType write FShipType;
   end;

   { TRadar }
   // Класс для отображения радара
   TRadar = class
   private
     FEngine: TSpaceEngine;      // Ссылка на движок
     FPlayer: TSpaceActor;       // Игрок (центр радара)
     FMaxRange: Single;          // Максимальная дальность радара
     FRadarSize: Integer;        // Размер радара на экране
     FRadarMargin: Integer;      // Отступ радара от краев экрана
     FRadarPos: TVector2;        // Позиция радара на экране
     FShowLabels: Boolean;       // Флаг отображения подписей
     FLabelVisibilityRange: Single; // Дальность видимости подписей
     FLabelSize: Integer;        // Размер меток
     FFontSize: Integer;         // Размер шрифта подписей
     FMarkerColor: TColorB;      // Цвет меток
     FEdgeMarkerColor: TColorB;  // Цвет меток за краем экрана
     // Переменные для шейдеров радара
     FStartTime: Single;
     FResolution: array [0..2] of Single;
     FTime: Single;
     FRadarWaveShader: TShader;  // Шейдер волн радара
     FRadarRipleShader: TShader; // Шейдер ряби радара
     FRadarRenderTexture: TRenderTexture2D; // Текстура для рендера радара
     // Отрисовка круга радара
     procedure DrawRadarCircle;
     // Отрисовка маркеров в мире
     procedure DrawWorldMarkers(Camera: TSpaceCamera; modelPos: TVector3; distance: Single; color: TColorB);
     // Получение цвета объекта по его типу
     function GetObjectColor(ShipType: TShipType): TColorB;
   public
     // Создание радара с привязкой к движку
     constructor Create(AEngine: TSpaceEngine);
     destructor Destroy; override;
     // Отрисовка радара
     procedure Draw(Camera: TSpaceCamera);
     // Установка игрока (центра радара)
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

{ TSpaceDust }
// Создание космической пыли с заданным размером области и количеством частиц
constructor TSpaceDust.Create(Size: single; Count: integer);
var point: TVector3; color: TColorB; i: integer;
begin
  FExtent := size * 0.5;
  SetLength(FPoints,count);
  SetLength(FColors,count);
  // Генерация случайных частиц
  for i:=0 to count-1 do
  begin
    // Случайная позиция в пределах заданного размера
    point := Vector3Create(
      GetPrettyBadRandomFloat(-FExtent, FExtent),
      GetPrettyBadRandomFloat(-FExtent, FExtent),
      GetPrettyBadRandomFloat(-FExtent, FExtent));
    FPoints[i]:= point;
    // Случайный цвет с оттенками серого
    color := ColorCreate(GetRandomValue(192, 255), GetRandomValue(192, 255), GetRandomValue(192, 255),255);
    Fcolors[i]:= Color;
  end;
end;

// Обновление позиций частиц относительно позиции камеры
procedure TSpaceDust.UpdateViewPosition(ViewPosition: TVector3);
var size:single; i: integer;
begin
  size := FExtent * 2;
  for i:=0 to Length(FPoints) -1 do
  begin
    // "Бесконечное" пространство - частицы переходят на противоположную сторону
    if (FPoints[i].x > viewPosition.x + FExtent) then FPoints[i].x -= size;
    if (FPoints[i].x < viewPosition.x - FExtent) then FPoints[i].x += size;
    if (FPoints[i].y > viewPosition.y + FExtent) then FPoints[i].y -= size;
    if (FPoints[i].y < viewPosition.y - FExtent) then FPoints[i].y += size;
    if (FPoints[i].z > viewPosition.z + FExtent) then FPoints[i].z -= size;
    if (FPoints[i].z < viewPosition.z - FExtent) then FPoints[i].z += size;
  end;
end;

// Отрисовка космической пыли
procedure TSpaceDust.Draw(ViewPosition, Velocity: TVector3; DrawDots: boolean);
var i, farAlpha: integer;  distance, farLerp, cubeSize: single;
begin
  BeginBlendMode(BLEND_ADDITIVE);
  for i:=0 to Length(FPoints) -1 do
  begin
    // Расчет затухания в зависимости от расстояния
    distance := Vector3Distance(viewPosition, FPoints[i]);
    farLerp := Clamp(Normalize(distance, FExtent * 0.9, FExtent), 0, 1);
    farAlpha := round(Lerp(255, 0, farLerp));
    cubeSize := 0.01;
    // Отрисовка частиц (точек или линий)
    if (drawDots) then
    DrawSphereEx(FPoints[i], cubeSize, 2, 2, ColorCreate(FColors[i].r, FColors[i].g, FColors[i].b, farAlpha));
    // Отрисовка линий, показывающих движение
    DrawLine3D(Vector3Add(FPoints[i], Vector3Scale(velocity, 0.01)),
    FPoints[i], ColorCreate(FColors[i].r, FColors[i].g, FColors[i].b, farAlpha));
  end;
  rlDrawRenderBatchActive();
  EndBlendMode();
end;

{ TSpaceCrosshair }
// Создание прицела с загрузкой модели из файла
constructor TSpaceCrosshair.Create(const modelFileName: PChar);
begin
  //R3D_SetModelImportScale(1);
  FCrosshairColor := DARKGREEN;
  if modelFileName <> nil then
    FCrosshairModel := LoadModel(modelFileName);
end;

// Уничтожение прицела с выгрузкой модели
destructor TSpaceCrosshair.Destroy;
begin
  if @FCrosshairModel <> nil then
  begin
   // R3D_UnloadModel(@FCrosshairModel, True);
    TraceLog(LOG_INFO, 'Space Engine: crosshair destroy and unload.');
  end else TraceLog(LOG_ERROR, 'Space Engine: crosshair not destroy');
  inherited Destroy;
end;

// Позиционирование прицела на акторе с заданным расстоянием
procedure TSpaceCrosshair.PositionCrosshairOnActor(const Actor: TSpaceActor; distance: Single);
var crosshairPos: TVector3;
    crosshairTransform: TMatrix;
begin
  // Вычисление позиции перед актором
  crosshairPos := Vector3Add(Vector3Scale(Actor.GetForward(), distance), Actor.Position);
  // Создание матрицы трансформации
  crosshairTransform := MatrixTranslate(crosshairPos.x, crosshairPos.y, crosshairPos.z);
  crosshairTransform := MatrixMultiply(QuaternionToMatrix(Actor.Rotation), crosshairTransform);
  FCrosshairModel.transform := crosshairTransform;
end;

// Отрисовка прицела с эффектом добавления
procedure TSpaceCrosshair.DrawCrosshair;
begin
  BeginBlendMode(BLEND_ADDITIVE);
   rlDisableDepthTest();
     DrawModel(FCrosshairModel, Vector3Zero(), 1, DARKGREEN);
   rlEnableDepthTest();
 EndBlendMode();
end;

{ TSpaceCamera }
// Создание камеры с указанием типа проекции и угла обзора
constructor TSpaceCamera.Create(isPerspective: boolean; fieldOfView: single);
begin
 // Начальные параметры камеры
  Camera.position := Vector3Create(0, 10, -10);
  Camera.target := Vector3Create(0, 0, 0);
  Camera.up := Vector3Create(0, 1, 0);
  Camera.fovy := fieldOfView;
  // Установка типа проекции
  if isPerspective then
    Camera.projection := CAMERA_PERSPECTIVE
  else
    Camera.projection := CAMERA_ORTHOGRAPHIC;
  // Инициализация сглаженных значений
  FSmoothPosition := Vector3Zero();
  FSmoothTarget := Vector3Zero();
  FSmoothUp := Vector3Zero();
end;

// Начало 3D-рендеринга
procedure TSpaceCamera.BeginDrawing;
begin
  R3D_Begin(Camera);
end;

// Завершение 3D-рендеринга
procedure TSpaceCamera.EndDrawing;
begin
  R3D_End();
end;

// Плавное следование камеры за актором
procedure TSpaceCamera.FollowActor(const Actor: TSpaceActor; deltaTime: Single);
var pos, actorForwards, target, up: TVector3;
begin
  // Позиция камеры за актором
  pos := Actor.TransformPoint(Vector3Create(0, 1, -3));
  // Направление взгляда камеры
  actorForwards := Vector3Scale(Actor.GetForward(), 25);
  target := Vector3Add(Actor.FPosition, ActorForwards);
  up := Actor.GetUp();
  // Плавное перемещение
  MoveTo(pos, target, up, deltaTime);
end;

// Плавное перемещение камеры в указанную позицию
procedure TSpaceCamera.MoveTo(position_, target, up: TVector3; deltaTime: Single);
begin
  // Сглаживание движения камеры
  Camera.position := SmoothDamp(Camera.position, position_, 10, deltaTime);
  Camera.target := SmoothDamp(Camera.target, target, 5, deltaTime);
  Camera.up := SmoothDamp(Camera.up, up, 5, deltaTime);
end;

// Мгновенное установление позиции камеры
procedure TSpaceCamera.SetPosition(position_, target, up: TVector3);
begin
  Camera.position := position_;
  Camera.target := target;
  Camera.up := up;
  // Обновление сглаженных значений
  FSmoothPosition := position_;
  FSmoothTarget := target;
  FSmoothUp := up;
end;

// Получение текущей позиции камеры
function TSpaceCamera.GetPosition: TVector3;
begin
  result := Camera.position;
end;

// Получение текущей цели камеры
function TSpaceCamera.GetTarget: TVector3;
begin
  result := Camera.target;
end;

// Получение текущего вектора "вверх"
function TSpaceCamera.GetUp: TVector3;
begin
  result := Camera.up;
end;

// Получение угла обзора камеры
function TSpaceCamera.GetFovy: Single;
begin
  result := Camera.fovy;
end;

{ TSpaceEngine }
// Получение количества акторов в движке
function TSpaceEngine.GetCount: Integer;
begin
  if FActorList <> nil then Result := FActorList.Count
  else Result := 0;
end;

// Получение источника света по индексу
function TSpaceEngine.GetLight(const Index: Integer): TR3D_Light;
begin
  if (Index >= 0) and (Index <= 3) then
  result := FLight[Index];
end;

// Получение актора по индексу
function TSpaceEngine.GetModelActor(const Index: Integer): TSpaceActor;
begin
  if (FActorList <> nil) and (Index >= 0) and (Index < FActorList.Count) then
    Result := TSpaceActor(FActorList[Index])
  else
    Result := nil;
end;

// Установка источника света по индексу
procedure TSpaceEngine.SetLight(const Index: Integer; AValue: TR3D_Light);
begin
  if (Index >= 0) and (Index <= 3) then
  FLight[Index] := AValue;
end;

// Создание движка с инициализацией компонентов
constructor TSpaceEngine.Create;
begin
  FActorList := TList.Create;
  FDeadActorList := TList.Create;
  FSpaceDust := TSpaceDust.Create(50, 500); // Космическая пыль
  CrosshairNear := TSpaceCrosshair.Create(nil); // Ближний прицел
  CrosshairFar := TSpaceCrosshair.Create(nil);  // Дальний прицел
  FRadar := TRadar.Create(Self); // Радар
  FMouseForFly := False; // Управление мышью по умолчанию выключено
end;

// Уничтожение движка с очисткой ресурсов
destructor TSpaceEngine.Destroy;
var i: integer;
begin
  // Помечаем все акторы как уничтоженные
  for i := 0 to FActorList.Count - 1 do
  begin
    TSpaceActor(FActorList.Items[i]).Dead;
  end;
  // Очищаем список уничтоженных акторов
  ClearDeadActor;
  // Освобождаем списки
  FActorList.Free;
  FDeadActorList.Free;
  // Выгружаем скайбокс
  R3D_UnloadSkybox(FSkyBox);
  // Закрываем R3D
  R3D_Close;

  TraceLog(LOG_Info,PChar('Space Engine: Engine Destroy'));
  inherited Destroy;
end;

// Добавление актора в движок с сортировкой
procedure TSpaceEngine.Add(const ModelActor: TSpaceActor);
var L, H, I: Integer;
begin
  // Бинарный поиск места для вставки
  L := 0;
  H := FActorList.Count - 1;
  while (L <= H) do
  begin
    I := (L + H) div 2;
    L := I + 1
  end;
  FActorList.Insert(L, ModelActor);
end;

// Удаление актора из движка
procedure TSpaceEngine.Remove(const ModelActor: TSpaceActor);
begin
  FActorList.Remove(ModelActor);
end;

// Перемещение актора в другой движок
procedure TSpaceEngine.Change(ModelActor: TSpaceActor; Dest: TSpaceEngine);
begin
  Dest.Add(ModelActor);
  ModelActor.Engine := Dest;
  FActorList.Remove(ModelActor);
end;

// Обновление состояния движка
procedure TSpaceEngine.Update(DeltaTime: Single; DustViewPosition: TVector3);
var i: Integer;
begin
  // Обновляем позиции космической пыли
  FSpaceDust.UpdateViewPosition(DustViewPosition);
  // Обновляем все акторы
  for i := 0 to FActorList.Count - 1 do
  begin
    TSpaceActor(FActorList.Items[i]).Update(DeltaTime);
  end;
end;

// Отрисовка сцены
procedure TSpaceEngine.Render(Camera: TSpaceCamera; ShowDebugAxes,
  ShowDebugRay: Boolean; DustVelocity: TVector3; DustDrawDots: boolean);
var i: Integer;
begin
  // Отрисовка всех акторов
  Camera.BeginDrawing;
    for i := 0 to FActorList.Count - 1 do
      TSpaceActor(FActorList.Items[i]).Render();
  Camera.EndDrawing;
  // Отрисовка космической пыли и прицелов
  BeginMode3D(Camera.Camera);
  FSpaceDust.Draw(Camera.GetPosition(), DustVelocity, DustDrawDots);
    CrosshairNear.DrawCrosshair();
    CrosshairFar.DrawCrosshair();

  // Отладочная информация (оси и коллайдеры)
  if ShowDebugAxes then
  begin
    BeginBlendMode(BLEND_ADDITIVE);
    DrawGrid(10, 1.0);  // Отрисовка сетки
    for i := 0 to FActorList.Count - 1 do
    begin
      // Оси объекта (вперед, влево, вверх)
      DrawLine3D(TSpaceActor(FActorList.Items[i]).Position, Vector3Add(TSpaceActor(FActorList.Items[i]).Position, TSpaceActor(FActorList.Items[i]).GetForward), ColorCreate(0, 0, 255, 255));
      DrawLine3D(TSpaceActor(FActorList.Items[i]).Position, Vector3Add(TSpaceActor(FActorList.Items[i]).Position, TSpaceActor(FActorList.Items[i]).GetLeft), ColorCreate(255, 0, 0, 255));
      DrawLine3D(TSpaceActor(FActorList.Items[i]).Position, Vector3Add(TSpaceActor(FActorList.Items[i]).Position, TSpaceActor(FActorList.Items[i]).GetUp), ColorCreate(0, 255, 0, 255));
      // Отрисовка коллайдеров
      case TSpaceActor(FActorList.Items[i]).FCollider.ColliderType of
        // Отрисовка сетки сферы
        Collider.ctSphere:
           DrawSphereWires(TSpaceActor(FActorList.Items[i]).FPosition, TSpaceActor(FActorList.Items[i]).FSphereColliderSize, 32, 32, RED);
        // Отрисовка линий bounding box
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

  // Повторная отрисовка прицелов (поверх всего)
    CrosshairNear.DrawCrosshair();
    CrosshairFar.DrawCrosshair();
  EndMode3D;

  // Отрисовка радара (поверх всего)
  if Assigned(FRadar) and Assigned(FRadar.FPlayer) then
    FRadar.Draw(Camera);

end;

// Проверка столкновений между всеми акторами
procedure TSpaceEngine.Collision;
var
  i, j: Integer;
begin
  // Проверяем все пары акторов
  for i := 0 to FActorList.Count - 1 do
  begin
    for j := i + 1 to FActorList.Count - 1 do
    begin
      // Проверяем только акторы с включенной коллизией
      if (TSpaceActor(FActorList.Items[i]).DoCollision) and
         (TSpaceActor(FActorList.Items[j]).DoCollision) then
        TSpaceActor(FActorList.Items[i]).Collision(TSpaceActor(FActorList.Items[j]));
    end;
  end;
end;

// Очистка всех акторов
procedure TSpaceEngine.Clear;
begin
  while Count > 0 do
  begin
    Items[Count - 1].Free;
  end;
end;

// Очистка уничтоженных акторов
procedure TSpaceEngine.ClearDeadActor;
begin
  while FDeadActorList.Count -1 >= 0 do
  begin
    TSpaceActor(FDeadActorList.Items[FDeadActorList.Count - 1]).Free;
  end;
end;

// Загрузка скайбокса из файла
procedure TSpaceEngine.LoadSkyBox(FileName: String; Quality: TSkyBoxQuality;
  SkyBoxType: TSkyBoxType);
begin
  case SkyBoxType of
    STCubemap: FSkyBox := R3D_LoadSkybox(PChar(FileName),CUBEMAP_LAYOUT_AUTO_DETECT);
    STPanorama: FSkyBox := R3D_LoadSkyboxPanorama(PChar(FileName), Integer(Quality));
  end;

end;

// Загрузка скайбокса из памяти
procedure TSpaceEngine.LoadSkyBoxFromMemory(SkyBoxImage: TImage;
  Quality: TSkyBoxQuality; SkyBoxType: TSkyBoxType);
begin
  case SkyBoxType of
    STCubemap: FSkyBox := R3D_LoadSkyboxFromMemory(SkyBoxImage,CUBEMAP_LAYOUT_AUTO_DETECT);
    STPanorama: FSkyBox := R3D_LoadSkyboxPanoramaFromMemory(SkyBoxImage, Integer(Quality));
  end;
end;

// Включение скайбокса
procedure TSpaceEngine.EnableSkybox;
begin
  R3D_EnableSkybox(FSkyBox);
end;

// Выключение скайбокса
procedure TSpaceEngine.DisableSkybox;
begin
  R3D_DisableSkybox;
end;

// Применение управления к кораблю
procedure TSpaceEngine.ApplyInputToShip(Ship: TSpaceActor; Step: Single);
var
  triggerRight, triggerLeft: Single;
  mousePos, screenCenter: TVector2;
  mouseSensitivity, deadZone, distFromCenter: Single;
begin
  // Настройки управления
  mouseSensitivity := 0.2;    // Чувствительность мыши
  deadZone := 0.2;            // Мертвая зона в центре (20% от радиуса)

  // Управление вперед/назад
  Ship.InputForward := 0;
  if (IsKeyDown(KEY_W)) then Ship.InputForward += Step;
  if (IsKeyDown(KEY_S)) then Ship.InputForward -= Step;
  Ship.InputForward -= GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_Y);
  Ship.InputForward := Clamp(Ship.InputForward, -Step, Step);

  // Управление влево/вправо
  Ship.InputLeft := 0;
  if (IsKeyDown(KEY_D)) then Ship.InputLeft -= Step;
  if (IsKeyDown(KEY_A)) then Ship.InputLeft += Step;
  Ship.InputLeft -= GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_X);
  Ship.InputLeft := Clamp(Ship.InputLeft, -Step, Step);

  // Управление вверх/вниз
  Ship.InputUp := 0;
  if (IsKeyDown(KEY_SPACE)) then Ship.InputUp += Step;
  if (IsKeyDown(KEY_LEFT_CONTROL)) then Ship.InputUp -= Step;

  // Управление триггерами геймпада
  triggerRight := GetGamepadAxisMovement(0, GAMEPAD_AXIS_RIGHT_TRIGGER);
  triggerRight := Remap(triggerRight, -Step, Step, 0, Step);
  triggerLeft := GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_TRIGGER);
  triggerLeft := Remap(triggerLeft, -Step, Step, 0, Step);

  Ship.InputUp += triggerRight;
  Ship.InputUp -= triggerLeft;
  Ship.InputUp := Clamp(Ship.InputUp, -Step, Step);

  // Управление поворотом (рыскание)
  Ship.InputYawLeft := 0;
  if (IsKeyDown(KEY_RIGHT)) then Ship.InputYawLeft -= Step;
  if (IsKeyDown(KEY_LEFT)) then Ship.InputYawLeft += Step;

  Ship.InputYawLeft -= GetGamepadAxisMovement(0, GAMEPAD_AXIS_RIGHT_X);
  Ship.InputYawLeft := Clamp(Ship.InputYawLeft, -Step, Step);

  // Управление наклоном (тангаж)
  Ship.InputPitchDown := 0;
  if (IsKeyDown(KEY_UP)) then Ship.InputPitchDown += Step;
  if (IsKeyDown(KEY_DOWN)) then Ship.InputPitchDown -= Step;

  Ship.InputPitchDown += GetGamepadAxisMovement(0, GAMEPAD_AXIS_RIGHT_Y);
  Ship.InputPitchDown := Clamp(Ship.InputPitchDown, -Step, Step);

  // Управление креном
  Ship.InputRollRight := 0;
  if (IsKeyDown(KEY_Q)) then Ship.InputRollRight -= Step;
  if (IsKeyDown(KEY_E)) then Ship.InputRollRight += Step;

  // Управление мышью (если включено)
  if FMouseForFly then
  begin
    screenCenter := Vector2Create(GetScreenWidth/2, GetScreenHeight/2);
    mousePos := GetMousePosition();
    // Вычисляем отклонение от центра (нормализованное)
    Ship.InputYawLeft := ( screenCenter.x - mousePos.x) / (GetScreenWidth/2);
    Ship.InputPitchDown := (screenCenter.y - mousePos.y) / (GetScreenHeight/2);
    // Вычисляем расстояние от центра [0..1]
    distFromCenter := Vector2Length(Vector2Create(Ship.InputYawLeft, Ship.InputPitchDown));
    // Плавное уменьшение влияния мыши при приближении к центру
    if distFromCenter < deadZone then
    begin
      // В мертвой зоне - постепенно уменьшаем вращение до нуля
      Ship.InputYawLeft := 0;
      Ship.InputPitchDown := 0;
    end
      else
    begin
      // За пределами мертвой зоны - нормальная чувствительность
      Ship.InputYawLeft := Ship.InputYawLeft * mouseSensitivity;
      Ship.InputPitchDown := Ship.InputPitchDown * mouseSensitivity;
    end;
  end;
end;


{ TSpaceActor }
// Установка 3D модели с автоматическим созданием коллайдера
procedure TSpaceActor.SetModel(AValue: TR3D_Model);
begin
  FModel := AValue;
  // Создание коллайдера в зависимости от типа
  case FColliderType of
    ctBox:
      begin // Создание box коллайдера на основе AABB модели
        FCollider := CreateCollider(Vector3Scale(Self.FModel.aabb.min, FScale),
                                    Vector3Scale(Self.FModel.aabb.max, FScale));

      end;
    ctSphere:
      begin // Создание сферического коллайдера
        FCollider := CreateSphereCollider(FPosition, FSphereColliderSize);
      end;
  end;
  // Установка вращения и позиции коллайдера
  SetColliderRotation(@FCollider, FVisualRotation);
  SetColliderTranslation(@FCollider, FPosition);
end;

// Установка позиции актора с обновлением коллайдера
procedure TSpaceActor.SetPosition(AValue: TVector3);
begin
  FPosition := AValue;
  SetColliderRotation(@self.FCollider, FVisualRotation);
  SetColliderTranslation(@self.FCollider, FPosition);
end;

// Установка масштаба с обновлением коллайдера
procedure TSpaceActor.SetScale(AValue: Single);
begin
  if FScale = AValue then Exit;
  FScale := AValue;
  // Пересоздание коллайдера при изменении масштаба
  FCollider := CreateCollider(Vector3Scale(FModel.aabb.min, FScale),
                              Vector3Scale(FModel.aabb.max, FScale));
end;

// Создание актора с привязкой к движку
constructor TSpaceActor.Create(const AParent: TSpaceEngine);
begin
  FEngine := AParent;
  FIsDead := False;
  FVisible := True;
  FTag := 0;
  FScale := 1;
  // Инициализация позиции, скорости и вращения
  FPosition := Vector3Zero();
  FVelocity := Vector3Zero();
  FRotation := QuaternionIdentity();
  FScale := 1;
  // Настройки управления по умолчанию
  FThrottleResponse := 10;
  TurnRate := 180;
  TurnResponse := 10;
  FMaxSpeed := 20.0;
  FCurrentSpeed := 0.0;
  FLastCollisionTime := 0.0;
  FAlignToHorizon := True;
  // Добавление актора в движок
  Engine.Add(Self);
end;

// Уничтожение актора
destructor TSpaceActor.Destroy;
begin
  Engine.Remove(Self);
  Engine.FDeadActorList.Remove(Self);

  // Выгрузка модели, если она была загружена
  if @FModel <> nil then
  R3D_UnloadModel(@FModel, True);

  inherited Destroy;
end;

// Обработка столкновения с другим актором
procedure TSpaceActor.Collision(const Other: TSpaceActor);
var
  Correction, CollisionNormal, RelativeVelocity: TVector3;
  ImpactForce, SpeedBeforeCollision: Single;
const
  Elasticity = 0.3;       // Коэффициент упругости
  MinImpactForce = 0.1;   // Минимальная сила удара
  SpeedReductionFactor = 1.7; // Фактор снижения скорости при столкновении
begin
  // Обновление позиции и вращения коллайдера
  SetColliderRotation(@FCollider, FVisualRotation);
  SetColliderTranslation(@FCollider, FPosition);

  // Проверка столкновения коллайдеров
  if TestColliderPair(@FCollider, @Other.FCollider) then
  begin
    // Получение корректировки позиции
    Correction := GetCollisionCorrection(@FCollider, @Other.FCollider);
    CollisionNormal := Vector3Normalize(Correction);
    SpeedBeforeCollision := Vector3Length(FVelocity);

    // Расчет относительной скорости
    RelativeVelocity := Vector3Subtract(FVelocity, Other.FVelocity);
    ImpactForce := Vector3DotProduct(RelativeVelocity, CollisionNormal);

    // Применение корректировки позиции
    FPosition := Vector3Add(FPosition, Correction);
    SetColliderTranslation(@FCollider, FPosition);

    // Обработка удара
    if ImpactForce > MinImpactForce then
    begin
      // Уменьшение скорости при ударе
      FCurrentSpeed := FCurrentSpeed * (1.0 - Min(ImpactForce/MaxSpeed, SpeedReductionFactor));

      // Эффект отскока
      FVelocity := Vector3Add(FVelocity,
        Vector3Scale(CollisionNormal, ImpactForce * Elasticity));
    end;

    // Вызов событий столкновения
    OnCollision(Other);
    Other.OnCollision(Self);
  end;
end;

// Проверка столкновений со всеми акторами
procedure TSpaceActor.Collision;
var i: Integer;
begin
  for i := 0 to Engine.Count-1 do
  begin
    Collision(Engine.Items[i]);
  end;
end;

// Помечает актор как уничтоженный
procedure TSpaceActor.Dead;
begin
  if not FIsDead then
  begin
    FIsDead := True;
    FEngine.FDeadActorList.Add(Self);
  end;
end;

// Событие при столкновении (может быть переопределено в потомках)
procedure TSpaceActor.OnCollision(const Actor: TSpaceActor);
begin
  // Базовая реализация не делает ничего
end;

procedure TSpaceActor.Update(const DeltaTime: Single);
var
  forwardSpeedMultipilier, autoSteerInput, targetVisualBank: single;
  targetVelocity: TVector3;
  transform: TMatrix;
  i: integer;
  targetSpeed: Single;
  acceleration: Single;
begin
  // Сначала обновляем текущую скорость на основе ввода
  targetSpeed := FMaxSpeed * Abs(InputForward); // Целевая скорость зависит от ввода
  acceleration := FThrottleResponse * DeltaTime; // Скорость изменения скорости

  if InputForward > 0 then
  begin
    // Разгон вперед
    FCurrentSpeed := Min(FCurrentSpeed + acceleration * targetSpeed, targetSpeed);
  end
  else if InputForward < 0 then
  begin
    // Торможение или движение назад
    FCurrentSpeed := Max(FCurrentSpeed - acceleration * targetSpeed, -targetSpeed * 0.33);
  end
  else
  begin
    // Плавное замедление при отсутствии ввода
    FCurrentSpeed := SmoothDamp(FCurrentSpeed, 0, 5.0, DeltaTime);
  end;

  //Теперь рассчитываем движение с учетом текущей скорости
  forwardSpeedMultipilier := ifthen(FCurrentSpeed > 0.0, 1.0, 0.33);

  // Плавность управления (оставляем без изменений)
  FSmoothForward := SmoothDamp(FSmoothForward, InputForward, ThrottleResponse, DeltaTime);
  FSmoothLeft := SmoothDamp(FSmoothLeft, InputLeft, ThrottleResponse, DeltaTime);
  FSmoothUp := SmoothDamp(FSmoothUp, InputUp, ThrottleResponse, DeltaTime);

  // Рассчитываем целевую скорость
  targetVelocity := Vector3Zero();
  targetVelocity := Vector3Add(
    targetVelocity,
    Vector3Scale(GetForward(), FCurrentSpeed * forwardSpeedMultipilier)
  );

  targetVelocity := Vector3Add(
    targetVelocity,
    Vector3Scale(GetUp(), FMaxSpeed * 0.5 * FSmoothUp)
  );

  targetVelocity := Vector3Add(
    targetVelocity,
    Vector3Scale(GetLeft(), FMaxSpeed * 0.5 * FSmoothLeft)
  );

  // Обновляем скорость с учетом инерции
  FVelocity := SmoothDamp(FVelocity, targetVelocity, 2.5, DeltaTime);
  // Обновляем позицию
  FPosition := Vector3Add(FPosition, Vector3Scale(FVelocity, DeltaTime));
  // Обработка вращения
  FSmoothPitchDown := SmoothDamp(FSmoothPitchDown, InputPitchDown, TurnResponse, DeltaTime);
  FSmoothRollRight := SmoothDamp(FSmoothRollRight, InputRollRight, TurnResponse, DeltaTime);
  FSmoothYawLeft := SmoothDamp(FSmoothYawLeft, InputYawLeft, TurnResponse, DeltaTime);
  // Применение вращения
  RotateLocalEuler(Vector3Create(0, 0, 1), FSmoothRollRight * TurnRate * DeltaTime);
  RotateLocalEuler(Vector3Create(1, 0, 0), FSmoothPitchDown * TurnRate * DeltaTime);
  RotateLocalEuler(Vector3Create(0, 1, 0), FSmoothYawLeft * TurnRate * DeltaTime);
  // Автоматическое выравнивание к горизонту
  if (FAlignToHorizon) and (abs(GetForward().y) < 0.8) then
  begin
    autoSteerInput := GetRight().y;
    RotateLocalEuler(Vector3Create(0, 0, 1), autoSteerInput * TurnRate * 0.5 * DeltaTime);
  end;
  // Визуальный крен при поворотах
  targetVisualBank := (-30 * DEG2RAD * FSmoothYawLeft) + (-15 * DEG2RAD * FSmoothLeft);
  FVisualBank := SmoothDamp(FVisualBank, targetVisualBank, 10, DeltaTime);
  FVisualRotation := QuaternionMultiply(FRotation, QuaternionFromAxisAngle(Vector3Create(0, 0, 1), FVisualBank));
  // Обновление матрицы трансформации модели
  transform := MatrixTranslate(FPosition.x, FPosition.y, FPosition.z);
  transform := MatrixMultiply(QuaternionToMatrix(FVisualRotation), transform);
  transform := MatrixMultiply(MatrixScale(Scale, Scale, Scale), transform);
  FModelTransform := transform;
  // Обновление коллайдера
  SetColliderRotation(@self.FCollider, FvisualRotation);
  SetColliderTranslation(@self.FCollider, Self.FPosition);

  FModelTransform := MatrixMultiply(MatrixScale(FScale,FScale,FScale),GetColliderTransform(@FCollider));
  // Обновление луча (для проверки пересечений)
  FRay.direction := GetForward;
  FRay.position := Position;
end;

// Отрисовка актора
procedure TSpaceActor.Render;
begin
  if not FVisible then Exit;
  // Отрисовка модели с использованием R3D
  R3D_DrawModelPro(@FModel, FModelTransform);
end;

// Получение вектора "вперед"
function TSpaceActor.GetForward: TVector3;
begin
  result := Vector3RotateByQuaternion(Vector3Create(0,0,1), FRotation);
end;

// Получение вектора "вперед" с заданной дистанцией
function TSpaceActor.GetForward(Distance: Single): TVector3;
begin
  result := Vector3RotateByQuaternion(Vector3Create(0,0,Distance), FRotation);
end;

// Получение вектора "назад"
function TSpaceActor.GetBack: TVector3;
begin
  result := Vector3RotateByQuaternion(Vector3Create(0,0,-1), FRotation);
end;

// Получение вектора "назад" с заданной дистанцией
function TSpaceActor.GetBack(Distance: Single): TVector3;
begin
  result := Vector3RotateByQuaternion(Vector3Create(0,0,-Distance), FRotation);
end;

// Получение вектора "вправо"
function TSpaceActor.GetRight: TVector3;
begin
  result := Vector3RotateByQuaternion(Vector3Create(-1,0,0), FRotation);
end;

// Получение вектора "вправо" с заданной дистанцией
function TSpaceActor.GetRight(Distance: Single): TVector3;
begin
  result := Vector3RotateByQuaternion(Vector3Create(-Distance,0,0), FRotation);
end;

// Получение вектора "влево"
function TSpaceActor.GetLeft: TVector3;
begin
  result := Vector3RotateByQuaternion(Vector3Create(1,0,0), FRotation);
end;

// Получение вектора "влево" с заданной дистанцией
function TSpaceActor.GetLeft(Distance: Single): TVector3;
begin
  result := Vector3RotateByQuaternion(Vector3Create(Distance,0,0), FRotation);
end;

// Получение вектора "вверх"
function TSpaceActor.GetUp: TVector3;
begin
  result := Vector3RotateByQuaternion(Vector3Create(0,1,0), FRotation);
end;

// Получение вектора "вверх" с заданной дистанцией
function TSpaceActor.GetUp(Distance: Single): TVector3;
begin
  result := Vector3RotateByQuaternion(Vector3Create(0,Distance,0), FRotation);
end;

// Получение вектора "вниз"
function TSpaceActor.GetDown: TVector3;
begin
  result := Vector3RotateByQuaternion(Vector3Create(0,-1,0), FRotation);
end;

// Получение вектора "вниз" с заданной дистанцией
function TSpaceActor.GetDown(Distance: Single): TVector3;
begin
  result:= Vector3RotateByQuaternion(Vector3Create(0,-Distance,0), FRotation);
end;

// Получение вектора скорости
function TSpaceActor.GetVelocity: TVector3;
begin
    Result := FVelocity; // Возвращает вектор скорости (x, y, z)
end;

// Получение текущей скорости (длина вектора скорости)
function TSpaceActor.GetSpeed: Single;
begin
    Result := Vector3Length(FVelocity); // Возвращает длину вектора скорости
end;

// Преобразование точки из локальных координат в мировые
function TSpaceActor.TransformPoint(point: TVector3): TVector3;
var mPos, mRot, matrix: TMatrix;
begin
  mPos:= MatrixTranslate(FPosition.x, FPosition.y, FPosition.z);
  mRot:= QuaternionToMatrix(FRotation);
  matrix:= MatrixMultiply(mRot, mPos);
  result:= Vector3Transform(point, matrix);
end;

// Вращение вокруг локальной оси на заданный угол
procedure TSpaceActor.RotateLocalEuler(axis: TVector3; degrees: single);
var radians: single;
begin
  radians:= degrees * DEG2RAD;
  FRotation:= QuaternionMultiply(FRotation, QuaternionFromAxisAngle(axis, radians));
end;

// Поворот к другому актору
procedure TSpaceActor.RotationToActor(targetActor: TSpaceActor;
  z_axis: boolean; deflection: Single);
var
  matrix: TMatrix;
  rotation_: TQuaternion;
  dis, direction: TVector3;
begin
  dis := Vector3Subtract(FPosition, targetActor.Position);
  direction := Vector3Normalize(dis);
  if z_axis then // Получение матрицы взгляда с учетом Z-оси
  matrix := MatrixLookAt(Vector3Zero, direction, Vector3Create(0,1,1))
  else
  matrix := MatrixLookAt(Vector3Zero, direction, Vector3Create(0,1,0));
  rotation_ := QuaternionInvert(QuaternionFromMatrix(matrix));
  FRotation := QuaternionSlerp(FRotation, rotation_, GetFrameTime * deflection * RAD2DEG);
end;

// Поворот к заданному вектору
procedure TSpaceActor.RotationToVector(target: TVector3; z_axis: boolean; deflection: Single);
var
  matrix: TMatrix;
  rotation_: TQuaternion;
  dis, direction: TVector3;
begin
  dis := Vector3Subtract(FPosition, target);
  direction := Vector3Normalize(dis);
  if z_axis then // Получение матрицы взгляда с учетом Z-оси
  matrix := MatrixLookAt(Vector3Zero, direction, Vector3Create(0,1,1))
  else
  matrix := MatrixLookAt(Vector3Zero, direction, Vector3Create(0,1,0));
  rotation_ := QuaternionInvert(QuaternionFromMatrix(matrix));
  FRotation := QuaternionSlerp(FRotation, rotation_, GetFrameTime * deflection * RAD2DEG);
end;

{ TRadar }
// Создание радара с привязкой к движку
constructor TRadar.Create(AEngine: TSpaceEngine);
begin
  FEngine := AEngine;
  FPlayer := nil;
  FMaxRange := 600;
  FRadarSize := 100;
  FRadarMargin := 10;
  FRadarPos := Vector2Create(0, 0);
  FShowLabels := True;
  FLabelVisibilityRange := 1.0;
  FLabelSize := 15;
  FFontSize := 10;
  FMarkerColor := YELLOW;
  FEdgeMarkerColor := ColorCreate(255, 165, 0, 255); // Оранжевый

  FRadarRipleShader := LoadShaderFromMemory(nil, RIPLE_SHADER_FS);
  FRadarWaveShader := LoadShaderFromMemory(nil, WAVE_SHADER_FS);

  FRadarRenderTexture := LoadRenderTexture(Round(FRadarSize), Round(FRadarSize));

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

destructor TRadar.Destroy;
begin
  UnloadShader(FRadarRipleShader);
  UnloadShader(FRadarWaveShader);
  UnloadRenderTexture(FRadarRenderTexture);
  inherited Destroy;
end;

procedure TRadar.SetPlayer(AValue: TSpaceActor);
begin
  if FPlayer = AValue then Exit;
  FPlayer := AValue;
end;

procedure TRadar.DrawRadarCircle;
var
  radarCenter: TVector2;
begin
  radarCenter.x := GetScreenWidth - FRadarSize div 2 - FRadarMargin;
  radarCenter.y := GetScreenHeight - FRadarSize div 2 - FRadarMargin;

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


// Измененная функция для получения цвета по типу корабля
function TRadar.GetObjectColor(ShipType: TShipType): TColorB;
begin
  case ShipType of
    Asteroid: Result := GRAY;
    Police: Result := BLUE;
    Station: Result := WHITE;
    Neutral: Result := GREEN;
    Pirate: Result := RED;
    Missle: Result := ORANGE;
    Beacon: Result := YELLOW;
    Container: Result := ColorCreate(200, 200, 200, 255); // Светло-серый
    Enemy: Result := ColorCreate(255, 0, 255, 255); // Пурпурный
    else Result := FMarkerColor; // По умолчанию
  end;
end;

// Получение вектора "вперед" камеры
function GetCameraForward(camera: TCamera3D): TVector3;
begin
  Result := Vector3Normalize(Vector3Subtract(camera.target, camera.position));
end;
 // Получение вектора "вправо" камеры
function GetCameraRight(camera: TCamera3D): TVector3;
begin
  Result := Vector3Normalize(Vector3CrossProduct(GetCameraForward(camera), camera.up));
end;
 // Получение вектора "вверх" камеры
function GetCameraUp(camera: TCamera3D): TVector3;
begin
  Result := camera.up;
end;
// Отрисовка маркеров объектов в мире
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

  radarCenter.x := GetScreenWidth - FRadarSize div 2 - FRadarMargin;
  radarCenter.y := GetScreenHeight - FRadarSize div 2 - FRadarMargin;

  for i := 0 to FEngine.FActorList.Count - 1 do
  begin
    if TSpaceActor(FEngine.FActorList.Items[i]) = FPlayer then Continue;

    modelPos := TSpaceActor(FEngine.FActorList.Items[i]).Position;
    relativePos := Vector3Subtract(FPlayer.Position, modelPos);
    distance := Vector3Length(relativePos);

    if distance > FMaxRange then Continue;

    color := GetObjectColor(TSpaceActor(FEngine.FActorList.Items[i]).ShipType);

    // Отрисовка на радаре
    normalizedDist := Min(distance / FMaxRange, 1.0);
    angle := ArcTan2(relativePos.x, relativePos.z);
    radarPos.x := radarCenter.x + Sin(angle) * (FRadarSize div 2) * normalizedDist;
    radarPos.y := radarCenter.y - Cos(angle) * (FRadarSize div 2) * normalizedDist;

    // Рендерим шейдер в текстуру
    BeginTextureMode(FRadarRenderTexture);
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
          FRadarRenderTexture.texture,
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

