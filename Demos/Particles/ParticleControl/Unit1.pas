unit Unit1;

interface

uses
  Windows, Messages, SysUtilsLite, Variants, Classes, Controls, Forms,
  Dialogs, GLSimpleNavigation, GLScene, GLObjects, GLCoordinates,
  GLCadencer, GLWin32Viewer, GLCrossPlatform, BaseClasses,
  VectorLists, VectorGeometry, StdCtrls, OpenGL1x,
  ComCtrls, ExtCtrls, VectorTypes,
  //VBOMesh units
  vboMesh, uVBO, uMeshObjects, uBaseClasses, uTextures, uShaders, OGLStateEmul;
type
  TForm1 = class(TForm)
    GLScene1: TGLScene;
    GLSceneViewer1: TGLSceneViewer;
    GLCadencer1: TGLCadencer;
    GLCamera1: TGLCamera;
    GLLightSource1: TGLLightSource;
    GLDummyCube1: TGLDummyCube;
    GLSimpleNavigation1: TGLSimpleNavigation;
    Panel2: TPanel;
    TrackBar2: TTrackBar;
    Panel1: TPanel;
    TrackBar1: TTrackBar;
    CheckBox1: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure GLCadencer1Progress(Sender: TObject; const deltaTime,
      newTime: Double);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormResize(Sender: TObject);
    procedure tbPCChange(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    function CreateShader: cardinal;
    procedure ApplyShader(MeshObject: TObject);
    procedure UnApplyShader(MeshObject: TObject);
  end;

var
  Form1: TForm1;
  Meshes: TVBOMesh;
  Particles: TVBOParticles;
  Atlas: TTexture;
  Shaders: TShaders;
  psId: cardinal;
implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
var i:integer;
    v:taffinevector;
    c:TVector;
begin
  GLSceneViewer1.Buffer.RenderingContext.Activate;
  OGLStateEmul.GLStateCache.CheckStates;
  //������ ���������� �����
  Atlas:=TTexture.CreateFromFile('Media\dark_smoke_atlas.tga');
  //��������� � ����� ��� ���������
  Meshes:=TVBOMesh.CreateAsChild(GLScene1.Objects);
  //������� ������ ��� ���������� �������� � ������� �� ������
  psId:=CreateShader;
  //����������� ������ ��� 10000 ������ � ��������� �� �� �����
  Particles:=Meshes.AddParticles(10000) as TVBOParticles;
  with Particles do begin
     //������� ��� ����� �������������� ����� �����
     UseColors:=true;
     For i:=1 to 10000 do begin
       //������ ��������� ��������� �������
       setvector(v,random(1000)/100-5,random(1000)/100-5,random(1000)/100-5);
       //� ����� �������� �������� �������� � ������,
       //������ ������� � �� ������������
       c:=vectormake(Random(2)/2,Random(2)/2,Random(10)/255,(10+random(245))/255);
       AddParticle(vectormake(v),c);
     end;
     Count:=10; //������� �������� ���� 10 ������
     //������ ����� ����������
     with MaterialObject.Blending do begin
       AlphaTestEnable:=true;
       AlphaFunc:=GL_GREATER;
       AlphaThreshold:=0;
       BlendEnable:=true;
       SrcBlendFunc:=GL_SRC_ALPHA;
       DstBlendFunc:=GL_ONE_MINUS_SRC_ALPHA;
     end;
     //�������� ������ � ����� �������
     NoZWrite:=true;
     //������ ��� ��������� VBO ����� ����� ����������� � ����� ��� ����� �������
     Immediate:=false; //true - ������ � VBO ������ ����� �������� ���������������
     //��� ���������� ������������ ����� ������� ������� ����������
     //Sorting:=sdBackToFront;
     //��������� ��� ������
     onBeforeRender:=ApplyShader;
     onAfterRender:=unApplyShader;
     Visible:=true;
  end;

end;

procedure TForm1.FormResize(Sender: TObject);
begin
   GLSceneViewer1.Buffer.ClearBuffers;
end;

procedure TForm1.GLCadencer1Progress(Sender: TObject; const deltaTime,
  newTime: Double);
begin
  GLSceneViewer1.Invalidate;
end;

procedure TForm1.tbPCChange(Sender: TObject);
begin
   Particles.Count:=TrackBar2.Position*100;
   Panel2.Caption:='Particles count='+inttostr(TrackBar2.Position*100);
end;

procedure TForm1.TrackBar1Change(Sender: TObject);
var i: integer;
    c: TVector;
begin
  Panel1.Caption:='Max particle size='+inttostr(TrackBar1.Position);
  for i:=0 to Particles.Count-1 do begin
    c:=Particles.Colors[i];
    c[2]:=random(TrackBar1.Position)/255;
    Particles.Colors[i]:=c;
  end;
end;

procedure TForm1.ApplyShader(MeshObject: TObject);
begin
  glEnable(GL_VERTEX_PROGRAM_POINT_SIZE);
  Shaders.UseProgramObject(psId);
  Atlas.Apply;
end;

procedure TForm1.UnApplyShader(MeshObject: TObject);
begin
  Shaders.UseProgramObject(0);
  glDisable(GL_VERTEX_PROGRAM_POINT_SIZE);
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  GLCadencer1.Enabled:=false;
  Meshes.Visible:=false;
  Atlas.Free; Shaders.Free;
  GLSceneViewer1.Buffer.RenderingContext.Deactivate;
end;

procedure TForm1.CheckBox1Click(Sender: TObject);
begin
  if CheckBox1.Checked then Particles.Sorting:=sdBackToFront
  else Particles.Sorting:=sdNone;
end;

function TForm1.CreateShader: cardinal;
var VS,FS: Ansistring;
    Scale: TVector2f;
begin
  VS:=
    'varying vec2 offset;'+#13+#10+
    'void main()'+#13+#10+
    '{'+#13+#10+
    '  gl_FrontColor=vec4(1.0,1.0,1.0,gl_Color.a);'+#13+#10+
    '  gl_BackColor=vec4(1.0,1.0,1.0,gl_Color.a);'+#13+#10+
    '  gl_PointSize = gl_Color.z*255.0;'+#13+#10+
    '  offset = gl_Color.xy;'+#13+#10+
    '  gl_Position = ftransform();'+#13+#10+
    '}';
  FS:=
    'uniform sampler2D Colormap;'+#13+#10+
    'uniform vec2 scale;'+#13+#10+
    'varying vec2 offset;'+#13+#10+
    'void main(void)'+#13+#10+
    '{'+#13+#10+
    '  vec2 coords = gl_PointCoord * scale + offset;'+#13+#10+
    '  gl_FragColor = texture2D(Colormap,coords)*gl_Color;'+#13+#10+
    '}';
  Shaders:=TShaders.Create;
  result:=Shaders.CreateShader(VS,FS);
  //�������� � ������ ������ �������� � ������ (������ ���� ������� ����������),
  //��� ��� ���� ������ �� ��������, �� ������ ��� ������ ���� ���
  Scale[0]:=0.5; Scale[1]:=0.5;
  Shaders.UseProgramObject(result);
  Shaders.SetUniforms(result,'scale',Scale);
  //���������� � ��� ������ ����������� �����
  Shaders.SetUniforms(result,'Colormap',0);
  Shaders.UseProgramObject(0);
end;

end.
