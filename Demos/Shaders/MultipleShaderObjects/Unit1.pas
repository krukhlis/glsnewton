unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, GLScene, GLCoordinates, GLWin32Viewer, GLCrossPlatform, OpenGL1x,
  BaseClasses, GLCadencer, GLObjects, StdCtrls, VectorGeometry, GLSimpleNavigation,
  ExtCtrls,
  //VBOMesh Lib
  vboMesh, uShaders, OGLStateEmul;

type
  TForm1 = class(TForm)
    GLScene1: TGLScene;
    GLSceneViewer1: TGLSceneViewer;
    GLCamera1: TGLCamera;
    GLLightSource1: TGLLightSource;
    GLDummyCube1: TGLDummyCube;
    GLCadencer1: TGLCadencer;
    GLSimpleNavigation1: TGLSimpleNavigation;
    Panel1: TPanel;
    Memo1: TMemo;
    Label1: TLabel;
    Label2: TLabel;
    procedure GLCadencer1Progress(Sender: TObject; const deltaTime,
      newTime: Double);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure ApplyShader1(mo: TObject);
    procedure ApplyShader2(mo: TObject);
    procedure unApplyShader(mo: TObject);
  end;

Const
  EmptyVP: string=
'#version 120                                   '+#13#10+
'uniform vec4[2] color;                         '+#13#10+
'void SendNormal(void);                 '+#13#10+
'void SendEmpty(void);                 '+#13#10+
'void main(void)                        '+#13#10+
'{                                      '+#13#10+
'  gl_Position = ftransform();          '+#13#10+
'  SendNormal();                        '+#13#10+
'}';
  SendNormToFS:string =
'#version 120                                   '+#13#10+
'uniform vec4[2] color;                         '+#13#10+
'varying vec3 normal;                   '+#13#10+
'void SendNormal(void)                  '+#13#10+
'{                                      '+#13#10+
'  normal = normalize(gl_NormalMatrix * gl_Normal);  '+#13#10+
'}';

  EmptyFP:string=
'#version 120                                   '+#13#10+
'varying vec3 normal;                           '+#13#10+
'uniform vec4[2] color;                         '+#13#10+
'void main(void)                                '+#13#10+
'{                                              '+#13#10+
'  float c = dot(color[1].rgb,normal);          '+#13#10+
'  gl_FragColor = color[0]*c;                   '+#13#10+
'}';


var
  Form1: TForm1;
  Shaders: TShaders;
  spId:integer;
  Mesh: TVBOMesh;

implementation

{$R *.dfm}

procedure TForm1.GLCadencer1Progress(Sender: TObject; const deltaTime,
  newTime: Double);
begin
  GLSceneViewer1.Invalidate;
end;

procedure TForm1.ApplyShader1(mo: TObject);
var colors:array[0..1] of TVector;
begin
  label1.Caption:='';
  colors[0]:=vectormake(0.5,1,0.7,1);
  colors[1]:=vectormake(1,1,1,1);
  with Shaders do begin
    //���������� ��������� ���������
    UseProgram('TestShader');
    //�������� � ������ ������ colors (2 ��������)
    SetUniforms('TestShader','color',colors[0],2);
  end;
end;

procedure TForm1.ApplyShader2(mo: TObject);
var colors:array[0..1] of TVector;
begin
    colors[0]:=vectormake(0.0,1,1,1);
    colors[1]:=vectormake(1,1,0.5,1);
    with Shaders do begin
    //���������� ��������� ���������
    UseProgram('TestShader');
    //�������� � ������ ������ colors (2 ��������)
    SetUniforms('TestShader','color',colors[0],2);
    //�������� �������� ������ � �������������� ��������
    SetUniforms('TestShader','Test',colors[0],2);
  end;
end;

procedure TForm1.unApplyShader(mo: TObject);
begin
  //������������ ������
  Shaders.EndProgram;
  //������� ������ ���������� ��������������
  label1.Caption:=label1.Caption+Shaders.UniformsWarnings;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  GLSceneViewer1.Buffer.RenderingContext.Activate;
  OGLStateEmul.GLStateCache.CheckStates;
  mesh:=TVBOMesh.CreateAsChild(glscene1.Objects);
  //��������� �� ����� ��� ������ � ����������� ������� ���������� �������
  with mesh.AddBox(1,1,1,1,1,1)do begin
    MoveObject(2,0,0);
    onBeforeRender:=ApplyShader1; //���������� ����� �����������
    onAfterRender:=unApplyShader; //���������� ����� ����������
  end;
  with mesh.AddBox(1,1,1,1,1,1) do begin
    MoveObject(-2,0,0);
    onBeforeRender:=ApplyShader2;
    onAfterRender:=unApplyShader;
  end;

  //������� ��������� ��������
  Shaders:=TShaders.Create;
  with Shaders do begin
    //������� ��������� ���������
    CreateShaderProgram('TestShader');
    //��������� � ���������� �������� ��� ������� ���������� ������� EmptyVP,
    //��������� ��� ��� ������ 'EmptyVP'
    AddShaderObject(EmptyVP,GL_VERTEX_SHADER,'EmptyVP');
    //��������� ��� ������� ���������� ������� SendNormToFS
    AddShaderObject(SendNormToFS,GL_VERTEX_SHADER,'SendNormal');
    //��������� ��� ����������� ���������� ������� EmptyFP
    AddShaderObject(EmptyFP,GL_FRAGMENT_SHADER,'EmptyFP');

    //������������ � ��������� ��������� 'TestShader' ������ 'SendNormal'
    AttachShaderToProgram('SendNormal','TestShader');
    //������������ � ��������� ��������� 'TestShader' ������ 'EmptyVP'
    AttachShaderToProgram('EmptyVP','TestShader');
    //������������ � ��������� ��������� 'TestShader' ������ 'EmptyFP'
    AttachShaderToProgram('EmptyFP','TestShader');
    //����������� ��������� ���������
    LinkShaderProgram('TestShader');
    //������� � ���� ��� ����������
    memo1.Lines.Add(Logs);
  end;
end;

end.
