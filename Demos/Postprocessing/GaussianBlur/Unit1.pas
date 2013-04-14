unit Unit1;

interface

uses
  Windows, Messages, Classes, Graphics, Controls, Forms, ComCtrls,
  Dialogs, GLCadencer, GLScene, GLObjects, GLCoordinates,
  GLWin32Viewer, GLCrossPlatform, BaseClasses, Vectorgeometry,
  StdCtrls, ExtCtrls, GLSimpleNavigation,
  //VBOMesh libs:
  VBOMesh, uMeshObjects, uTextures, uFBO, uShaders, OGLStateEmul;
type
  TForm1 = class(TForm)
    GLScene1: TGLScene;
    GLSceneViewer1: TGLSceneViewer;
    GLCadencer1: TGLCadencer;
    GLLightSource1: TGLLightSource;
    GLCamera1: TGLCamera;
    GLDummyCube1: TGLDummyCube;
    GLSimpleNavigation1: TGLSimpleNavigation;
    procedure GLCadencer1Progress(Sender: TObject; const deltaTime,
      newTime: Double);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    procedure ApplyShader(ShaderProgram: TShaderProgram);
    { Public declarations }
  end;

var
  Form1: TForm1;
  world: TVBOMesh;
  tex: TTexture;
  fbotex,fbotex2,fbotex3: TTexture;
  ObjCol: TMeshCollection;
  Pass1,Pass2,Pass3: TMeshContainer;
implementation

{$R *.dfm}

procedure TForm1.ApplyShader(ShaderProgram: TShaderProgram);
begin
  ShaderProgram.SetUniforms('TexSize',Vectormake(fbotex.Width,fbotex.Height,0,0));
  ShaderProgram.SetUniforms('image',0);
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
  ObjCol:=Pass1.Collection;
  Pass1.Render.Active:=true;
  Pass2:=world.AddNewContainer;
  //������ ������ ��� ������� �������
  with Pass2.CreateShader do begin
    onApplyShader:=ApplyShader;
    CreateFromFile('Media\passthrough.vert','Media\linear_horiz.frag');
  end;
  Pass2.Render.Active:=true;
  Pass3:=world.AddNewContainer;
  //������ ������ ��� �������� �������
  with Pass3.CreateShader do begin
    onApplyShader:=ApplyShader;
    CreateFromFile('Media\passthrough.vert','Media\linear_vert.frag');
  end;
  Pass3.Render.Active:=true;

  //������� �������� ��� ��������� ������������� FBO
  fbotex:=TTexture.Create;
  fbotex2:=TTexture.Create;
  fbotex3:=TTexture.Create;
  //������ ����� ������������ ��������
  fbotex.CreateRGBA8Texture2D(256,256);
  fbotex2.CreateRGBA8Texture2D(256,256);
  fbotex3.CreateRGBA8Texture2D(256,256);

  //������������� FBO ����������, ����������� ���������� ���
  //���������� ����������� ��������� �����������,
  // (������� �������� ����� ������� ���������)
  with Pass1 do begin
    Priority:=-3;
    Render.FBO.ConfigFBO([rbDepth]);
    Render.FBO.ConfigDepthBuffer(bmBuffer,dp16);
    Render.AttachTexture(fbotex,tgTexture);
    Render.RenderBuffer:=rtFrameBuffer;
  end;

  with Pass2 do begin
    Priority:=-2;
    Collection.AddScreenQuad.Texture:=fbotex;
    Render.AttachTexture(fbotex2,tgTexture);
    Render.RenderBuffer:=rtFrameBuffer;
  end;

  with Pass3 do begin
    Priority:=-1;
    Collection.AddScreenQuad.Texture:=fbotex2;
    Render.AttachTexture(fbotex3,tgTexture);
    Render.RenderBuffer:=rtFrameBuffer;
  end;

  //��������� ���������, � ������� ����� ������������ ������������ �����
  with world.AddScreenQuad do begin
    Texture:=fbotex;
  end;

//��������� �����, �������� ��������������� ��������� � ���������
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  //��������� � ���������� ��������� � ������� �� ����
  ObjCol.AddPlane(10,10,1,1).MoveObject(0,-2,0);
  //��� ���������� ������� � ���������� (������ ������) ������ ������������ �����������
  TVBOMeshObject(ObjCol.Last).TwoSides:=true;
  TVBOMeshObject(ObjCol.Last).MaterialObject.TwoSideLighting:=true;
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
  GLSceneViewer1.Invalidate;
end;

end.
