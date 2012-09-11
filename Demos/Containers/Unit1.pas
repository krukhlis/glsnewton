unit Unit1;

interface

uses
  Windows, Messages, Classes, Graphics, Controls, Forms,
  Dialogs, GLCadencer, GLScene, GLObjects, GLCoordinates,
  GLWin32Viewer, GLCrossPlatform, BaseClasses, Vectorgeometry,
  StdCtrls, ExtCtrls, GLSimpleNavigation,
  //VBOMesh libs:
  VBOMesh, uMeshObjects, uTextures, uFBO, OGLStateEmul, ComCtrls;
type
  TForm1 = class(TForm)
    GLScene1: TGLScene;
    GLSceneViewer1: TGLSceneViewer;
    GLCadencer1: TGLCadencer;
    GLLightSource1: TGLLightSource;
    GLCamera1: TGLCamera;
    GLDummyCube1: TGLDummyCube;
    GLSimpleNavigation1: TGLSimpleNavigation;
    Panel1: TPanel;
    CheckBox1: TCheckBox;
    TrackBar1: TTrackBar;
    Label1: TLabel;
    Label2: TLabel;
    procedure GLCadencer1Progress(Sender: TObject; const deltaTime,
      newTime: Double);
    procedure FormCreate(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  world: TVBOMesh;
  tex,fbotex: TTexture;
  ObjCol: TMeshCollection;
  Pass1: TMeshContainer;
  Size: integer = 256;
implementation

{$R *.dfm}

procedure TForm1.CheckBox1Click(Sender: TObject);
begin
  Pass1.Render.ViewerToTextureSize:=not CheckBox1.Checked;
  if not CheckBox1.Checked then
    fbotex.SetDimensions(size,size);
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  GLCadencer1.Enabled:=false;
  tex.Free; fbotex.Free; world.Free;
end;

procedure TForm1.FormCreate(Sender: TObject);
var Sphere: TVBOMeshObject;
    color: TVector;
    h: single;
begin
  //���������� �������� OGL � ������ ��������� ��������� ���������� OGL
  GLSceneViewer1.Buffer.RenderingContext.Activate;
  OGLStateEmul.GLStateCache.CheckStates;
  //������� �������� �� �����
  tex:=TTexture.CreateFromFile('Media\tile.bmp');

  //��������� � ����� �������� ������
  world:=TVBOMesh.CreateAsChild(GLScene1.Objects);
  world.OldRender:=false;
  //��������� � ����� ��������� � �����������
  Pass1:=world.AddNewContainer;
  ObjCol:=Pass1.Collection; //������ �� ��������� ��������
  Pass1.Render.Active:=true; //���������� ������ ����������

  //������� �������� ��� ��������� ������������� FBO
  fbotex:=TTexture.Create;
  //������ ����� ������������ ��������
  fbotex.CreateRGBA8Texture2D(256,256);

  //������������� FBO ����������
  Pass1.Render.FBO.ConfigFBO([rbDepth]);
  Pass1.Render.FBO.ConfigDepthBuffer(bmBuffer,dp32);
  //����������� ���� �������� �� �������� ������������
  Pass1.Render.AttachTexture(fbotex,tgTexture);
  //��������� ��� ��������� ������ �������������� � ��������
  Pass1.Render.RenderBuffer:=rtFrameBuffer;
  //��������� ��� ������ ������ ����������� ��� ������ ��������
  Pass1.Render.ViewerToTextureSize:=true;

  //��������� ���������, � ������� ����� ������������ ������������ �����
  world.AddScreenQuad.Texture:=fbotex;

//��������� �����, �������� ��������������� ��������� � ���������
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  //��������� � ���������� ��������� � ������� �� ����
  ObjCol.AddPlane(10,10,1,1).MoveObject(0,-2,0);
  //��� ���������� ������� � ���������� (������ ������) ������ ������������ �����������
  TVBOMeshObject(ObjCol.Last).TwoSides:=true;
  //������� � ���������� �����, ������� ��� ����� � �������� �� ���������
  with ObjCol.AddBox(1,1,1,1,1,1) do begin
    MoveObject(-2,0,0); ScaleObject(1,1.5,1);
    //�������� ����� �������� ��� ���� � ������� ��� ������ �����
    MaterialObject.AddNewMaterial('Blue').Properties.DiffuseColor.SetColor(0,0,1.0,1.0);
  end;
  //������� � ���������� ����� � �������� �� ���� ��������
  Sphere:=ObjCol.AddSphere(1,16,32);
  Sphere.MoveObject(2,0,0);
  Sphere.Texture:=tex;
  //���� ������ ������� ������� ���������� (������) ��������� ��������
  TVBOMeshObject(ObjCol[0]).Texture:=tex;
  //������� � ���������� ����� �������� �����
  color:=VectorMake(0,1,0,1);
  ObjCol.AddGrid(10,10,10,10,@Color).MoveObject(0,2,0);
  //������� ������ ����� ����������� ���� �������� �����:
  color:=VectorMake(1,0,0,1);
  ObjCol.AddBBox(Sphere.Extents,color);

  //������� � ���������� �������� � �������� � ��� �������� �� obj
  with ObjCol.AddMeshFromFile('Media\Column.obj') do begin
    h:=Extents.emax[1]-Extents.emin[1];
    ScaleObject(1/400,1/h*4,1/400);
    MoveObject(0,-2,-3);
  end;

  //������� � ���������� �������� � �������� � ��� �������� �� 3ds
  with ObjCol.AddMeshFromFile('Media\Column.3ds') do begin
    Name:='3DS Mesh';
    h:=Extents.emax[1]-Extents.emin[1];
    ScaleObject(1/400,1/h*4,1/400);
    MoveObject(0,-2,3);
  end;
end;

procedure TForm1.GLCadencer1Progress(Sender: TObject; const deltaTime,
  newTime: Double);
begin
  GLSceneViewer1.Buffer.RenderingContext.Activate;
  fbotex.SetDimensions(size,size);
  GLSceneViewer1.Invalidate;
end;

procedure TForm1.TrackBar1Change(Sender: TObject);
const tsize: array[0..5] of integer = (128,256,512,1024,2048,4096);
begin
  size:=tsize[TrackBar1.Position];
  label2.Caption:=inttostr(size);
end;

end.
