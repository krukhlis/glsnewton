unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  StdCtrls, Dialogs, GLScene, GLObjects, GLCoordinates, GLCadencer, GLWin32Viewer,
  GLCrossPlatform, BaseClasses, GLKeyboard, VectorGeometry, VectorLists, VectorTypes,
  VBOMesh, uMeshObjects, uTextures, uMaterials, NewtonImport, OGLStateEmul;

type
  RParticle = record
    Sprite : TVBOMeshObject;
    Speed  : single;
    Active : boolean;
  end;                    

  TForm1 = class(TForm)
    GLScene1: TGLScene;
    GLSceneViewer1: TGLSceneViewer;
    GLCadencer1: TGLCadencer;
    GLCamera1: TGLCamera;
    GLDummyCube1: TGLDummyCube;
    Button1: TButton;
    Button2: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure GLCadencer1Progress(Sender: TObject; const deltaTime,
      newTime: Double);
    procedure Button1Click(Sender: TObject);
    procedure EndFrame;
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure GLSceneViewer1MouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  VBOMesh : TVBOMesh;
  Master,MasterBroken,Bench:TVbOMeshObject;
  Expl: TVBOAnimatedSprite;
  ExplTex,PartTex: TTexture;
  Particles : array of RParticle;
  NWorld    : PNewtonWorld;
  Fragments : array of TVBOMeshObject;
  FragB     : array of PNewtonBody;
  Ground    : PNewtonBody;
  MX,MY     : integer;


implementation

{$R *.dfm}

//������� ��������� ������ ��� ����� ���������� ���
procedure NewtonCallBack( const body : PNewtonBody; timestep : Float; threadIndex : int ); cdecl;
var
  M : Single;
  I : TVector3f;
  F : TVector3f;
begin
  NewtonBodyGetMassMatrix(Body, @M, @I[0], @I[1], @I[2]); //�������� ����� ����
  F:= affinevectormake(0, -10*m, 0);//���� ����, F=M*G
  NewtonBodyAddForce(Body, @F[0]);  //��������� ���� � ����
end;

procedure TForm1.EndFrame;          //������� �� ���������� ��������� ����� �������� ������ �������������� �������
begin
  Expl.Stop;                        //������������� ��������
  Expl.FirstFrame;                  //���������� � ������� ����
end;

procedure TForm1.FormCreate(Sender: TObject);
var List: TAffineVectorList;
    Col: PNewtonCollision;
    i,j:integer;
    Face :TMatrix3f;
    Faces:array of TVector3f;
begin
  GLSceneViewer1.Buffer.RenderingContext.Activate;
  OGLStateEmul.GLStateCache.CheckStates;
  VBOMesh:=TVBOMesh.CreateAsChild(GLscene1.Objects);

  Master:=VBOMesh.AddMeshFromFile('Media\BenchNew.obj');             //������ ������ ������ ��� ����� ��������
  Master.Visible:=false;                                       //�������� ���
  MasterBroken:=VBOMesh.AddMeshFromFile('Media\BrokenBenchNew.obj'); //������ ������ ������ ��� �������� ��������
  MasterBroken.Visible:=false;                                 //����� �������� ���
  Bench:=VBOMesh.AddProxyObject(Master);                       //������ �� ������ ������
  //������ �� ������ ������ �������� � ������ � PARAMS!

  ExplTex:=TTexture.CreateFromFile('Media\expl.bmp');                //������ �������� ������
  ExplTex.BlendingMode:=tbmAdditive;
  ExplTex.TextureMode:=tcReplace;
  Expl:=(VBOmesh.AddAnimatedSprite(stSpherical,1,1) as TVBOAnimatedSprite); //������ ������������� ������ ������
  Expl.Texture:=ExplTex;                                       //����������� ��� ��� ��������� ��������
  Expl.FramesDirection:=fdHorizontal;                          //���� ����������� ������ �� �����������
  Expl.FramesCount:=9;                                         //��������� ���������� ������
  Expl.HorFramesCount:=3;                                      //���-�� ������ �� �����������
  Expl.VertFramesCount:=3;                                     //���-�� ������ �� ���������
  Expl.FrameRate:=18;                                          //���-�� ������ � �������
  Expl.NoZWrite:=true;
  Expl.Visible:=false;
  Expl.ToFrame(0);
  Expl.OnEndFrameReached:=EndFrame;                            //����� ��������� ������� ����� ����������� �� ���������� ���������� �����

  PartTex:=TTexture.CreateFromFile('Media\Dust.tga');                //������ �������� ������
  PartTex.BlendingMode:=tbmTransparency;                       //����������� ��������� ��������
  PartTex.TextureMode:=tcAdd;
  SetLength(Particles,8);
  for i:=0 to Length(Particles)-1 do                           //������ ���� ������� �� �������� ������ ����� � ���� ����
  begin
    with Particles[i] do
    begin
      Sprite:=VBOMesh.AddSprite(stSpherical,3,3);             //������ ������ ����������� ��������� 3 �� 3
      Sprite.Visible:=false;
      Sprite.Texture:=PartTex;                                //��������� ��������
      Sprite.Material:=TMaterial.Create;                      //������ ��������, ����� ����� ���� ������ ����� �����
      Sprite.NoZWrite:=true;
      Active:=false;
    end;
  end;                                                        //������ ������� �� ���������� ��������
                                                              //������ ������������ ���
  NWorld:=NewtonCreate(nil,nil);
  NewtonSetSolverModel(NWorld,1);
  SetLength(Fragments,5);
  SetLength(FragB,5);
  for i:=0 to length(Fragments)-1 do
  begin
    Fragments[i]:=VBOmesh.AddMeshFromFile('Media\Mesh.3ds');       //������ ��� ������� ����� ���������� ���� �������
    Fragments[i].Visible:=false;
    List:=TAffineVectorList.Create;
    Fragments[i].GetTriMesh(List);                           //������ �������� ��� ������ ����������� ����
    SetLength(Faces,List.Count);                             //��� ����� ��������� ������������ �� ����
    for j:=0 to Length(Faces)-1 do                           //������� �� � ������ Faces
    begin
      Faces[j][0]:=List[j][0];
      Faces[j][1]:=List[j][1];
      Faces[j][2]:=List[j][2];
    end;
    Col := NewtonCreateConvexHull(NWorld,List.Count,@Faces[0],SizeOf(TAffineVector),0,0,nil); //������ ���������� �������� �� ����� �������������
    List.Free;                                            //ConvexHull(�������� �������) � ������� �� TriMeshCollision �� ����� ����� ����� �������� ������������, �� ����� ���� ������������
    FragB[i]:= NewtonCreateBody(NWorld, Col);             // ������ ���� � ����� ���������
    NewtonReleaseCollision(NWorld, Col);                  //������� �������� ��� ��������
    NewtonBodySetMassMatrix(FragB[i],0,1,1,1);            //������������� ���� � ������� �������
    NewtonBodySetForceAndTorqueCallBack(FragB[i],NewtonCallBack); //����� ������� ��������� ������, � ������� �� ����� ������������ ���� � ����
  end;

  Col:=NewtonCreateBox(NWorld,100,0.2,100,0,nil);          //������ ���� ������������ �����
  Ground:=NewtonCreateBody(NWorld,Col);
  NewtonReleaseCollision(NWorld, Col);
end;



procedure TForm1.FormDestroy(Sender: TObject);
begin
  NewtonDestroy(NWorld);
  VBOmesh.Free;
  GLSceneViewer1.Buffer.RenderingContext.Deactivate;
end;

procedure TForm1.GLCadencer1Progress(Sender: TObject; const deltaTime,
  newTime: Double);
var i:integer;
M:TMatrix;
begin
  NewtonUpdate(NWorld,DeltaTime);               //���������� ��������� ������������� ����
  for i:=0 to length(Fragments)-1 do
  begin
    NewtonBodyGetMatrix(FragB[i],@M);           //�������������� ����������� ������� � ����������� ������
    Fragments[i].Matrices.ModelMatrix:=M;
    Fragments[i].UpdateWorldMatrix();
  end;
  for i:=0 to Length(Particles)-1 do
  begin
    if Particles[i].Active then
    With Particles[i] do begin
      Sprite.MoveForward(Speed*DeltaTime);       //����� ���� ������� ������� ��� ����� ��������� �����
      Speed:=Speed-(Speed*Speed*DeltaTime);      //���������� ��������� �������� ��������
      Sprite.ScaleObject(VectorAdd(Sprite.Scale,DeltaTime)); //����������� ������ �������
      with Sprite.Material.Properties.DiffuseColor do begin
        Alpha:=Alpha-DeltaTime/2;//��������� �����
        if Alpha<0.01 then Particles[i].Active:=false; //�������� ���� ������� ����� ��� ����������� ����������
      end;
    end;
  end;                   
  GLSceneViewer1.Invalidate;
end;

procedure TForm1.Button1Click(Sender: TObject);
var i:integer;
    Angle:single;
    V:TVector;
    M:TMatrix;
begin
  Randomize;
  Expl.Visible:=true;
  Expl.Position:=VectorMake(0,0.5,0,1);
  Expl.Play(samLoop);                       //����������������� ������
  Bench.ChangeProxy(MasterBroken);          //������ ������ ������ ������ ������ �� ���������
  Angle:=0;
  for i:=0 to Length(Particles)-1 do
  begin
    with Particles[i] do                   //������ ������ ������������� ���� � ������� ����� ������
    begin
      Sprite.Visible:=true;
      Sprite.Material.Properties.DiffuseColor.Alpha:=1;
      Sprite.ScaleObject(1,1,1);
      Sprite.Direction:=VectorMake(0,0,1);
      Sprite.Position:=VectorMake(0,0,0,1);
      Active:=true;
      Speed:=50;
      Sprite.TurnObject(Angle);
    end;
    Angle:=Angle+2*pi/8;
  end;

  for i:=0 to Length(FragB)-1 do
  begin
    Fragments[i].Visible:=true;
    NewtonBodyGetMatrix(FragB[i],@M);        //������ ���� ���������� ���� � ������ �������, ����� ��� ���������� � ��������
    M[3]:=VectorMake(0,1,0,1);
    NewtonBodySetMatrix(FragB[i],@M);
    V:=VectorMake(20-Random(40),5+Random(15),20-Random(40));
    NewtonBodySetVelocity(FragB[i],@V);     //����� ��������� �������� ����� ���������� ���
    V:=VectorMake(Random(50),Random(50),Random(50));
    NewtonBodySetOmega(FragB[i],@V);        //����� ��������� ������� �������� �� ���� ���� , ����� ������� ��������
    NewtonBodySetMassMatrix(FragB[i],1,1,1,1); //����� ����� � ������� ������� ���
  end;
end;


procedure TForm1.FormMouseWheel(Sender: TObject; Shift: TShiftState;  //�������� ������ � ���
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  GLCamera1.AdjustDistanceToTarget(Power(1.1, WheelDelta/120));
end;

procedure TForm1.GLSceneViewer1MouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  if IsKeyDown($1) then
  begin
   GLCamera1.MoveAroundTarget((MY-Y), (MX-X));
   MX:=X; MY:=Y;
  end;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  Bench.ChangeProxy(Master); //�������������� ���� �������� ����� ������ ������
end;

end.
