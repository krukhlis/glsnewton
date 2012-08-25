{: Textures - ������������ ��� �������� ������� � ������� bmp, tga, jpg, png � dds.

	Historique:
        09/03/12 - Fantom - ��������� ��������� jpg �� ������������� Synopse jpegdec
                 - Fantom - ���������� �������� 32-������ bmp
        05/01/12 - Fantom - �������� ��������� ������� � ������� png
        05/01/12 - Fantom - ��������� ��������� ������� � ������� jpg
        08/05/11 - Fantom - ��������� ��� � ��������� 256-������� bmp (���)
        21/08/10 - Fantom - ��������� ��� � ��������� jpeg
}
unit Textures;

interface

uses
  Windows, Graphics, Classes, JPEG, SysUtils, jpegdec;

function LoadTexture(Filename: String; var Format: Cardinal; var Width, Height: integer) : pointer;overload;
function LoadTexture(Filename: String; var iFormat,cFormat,dType,pSize: Cardinal; var Width, Height: integer) : pointer; overload;
procedure SaveTGAImage(FileName: string; Data: pointer; Width,Height: integer;
  PixelFormat: TPixelFormat);

implementation

const
  GL_LUMINANCE = $1909;
  GL_BGR = $80E0;
  GL_LUMINANCE8 = $8040;
  GL_RGB8 = $8051;
  GL_UNSIGNED_SHORT = $1403;
  GL_UNSIGNED_BYTE = $1401;
  GL_LUMINANCE16 = $8042;
  GL_LUMINANCE_ALPHA = $190A;
  GL_LUMINANCE16_ALPHA16 = $8048;
  GL_LUMINANCE8_ALPHA8 = $8045;
  GL_RGB   = $1907;
  GL_RGB16 = $8054;
  GL_RGBA  = $1908;
  GL_RGBA16 = $805B;
  GL_RGBA8 = $8058;
  GL_BGRA  = $80E1;

Type
   TTGAHeader = packed record
      IDLength          : Byte;
      ColorMapType      : Byte;
      ImageType         : Byte;
      ColorMapOrigin    : Word;
      ColorMapLength    : Word;
      ColorMapEntrySize : Byte;
      XOrigin           : Word;
      YOrigin           : Word;
      Width             : Word;
      Height            : Word;
      PixelSize         : Byte;
      ImageDescriptor   : Byte;
  end;

{------------------------------------------------------------------}
{  Swap bitmap format from BGR to RGB                              }
{------------------------------------------------------------------}
procedure SwapRGB(data : Pointer; Size : Integer);
asm
  mov ebx, eax
  mov ecx, size

@@loop :
  mov al,[ebx+0]
  mov ah,[ebx+2]
  mov [ebx+2],al
  mov [ebx+0],ah
  add ebx,3
  dec ecx
  jnz @@loop
end;

procedure flipSurface(chgData: Pbyte; w, h, pSize: integer);
var
  lineSize: integer;
  sliceSize: integer;
  tempBuf: Pbyte;
  j: integer;
  top, bottom: Pbyte;
begin
  lineSize := pSize * w;
  sliceSize := lineSize * h;
  GetMem(tempBuf, lineSize);

  top := chgData;
  bottom := top;
  Inc(bottom, sliceSize - lineSize);

  for j := 0 to (h div 2) - 1 do begin
    Move(top^, tempBuf^, lineSize);
    Move(bottom^, top^, lineSize);
    Move(tempBuf^, bottom^, lineSize);
    Inc(top, lineSize);
    Dec(bottom, lineSize);
  end;
  FreeMem(tempBuf);
end;

{------------------------------------------------------------------}
{  Load BMP textures                                               }
{------------------------------------------------------------------}
function LoadBMPTexture(Filename: String; var Format : Cardinal; var Width, Height: integer) : pointer;
var
  FileHeader: BITMAPFILEHEADER;
  InfoHeader: BITMAPINFOHEADER;
  Palette: array of RGBQUAD;
  BitmapFile: THandle;
  BitmapLength: LongWord;
  PaletteLength: LongWord;
  ReadBytes: LongWord;
  pData : Pointer;
  //For 256 color bitmap
  bmp: TBitmap;
  bpp:byte;
  i,j, offs: integer;
  p: PByteArray;
  sLength: integer;
  fLength,temp: integer;
begin
  result :=nil;
  Width:=-1; Height:=-1;
  // Load image from file
    BitmapFile := CreateFile(PChar(Filename), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, 0, 0);
    if (BitmapFile = INVALID_HANDLE_VALUE) then begin
      MessageBox(0, PChar('Error opening ' + Filename), PChar('BMP Unit'), MB_OK);
      Exit;
    end;

    // Get header information
    ReadFile(BitmapFile, FileHeader, SizeOf(FileHeader), ReadBytes, nil);
    ReadFile(BitmapFile, InfoHeader, SizeOf(InfoHeader), ReadBytes, nil);
    Width  := InfoHeader.biWidth;
    Height := InfoHeader.biHeight;

    if InfoHeader.biClrUsed<>0 then begin
       CloseHandle(BitmapFile);
       bmp:=TBitmap.Create; bmp.LoadFromFile(Filename);
       bmp.PixelFormat:=pf24bit; bpp:=3;
       getmem(pData,bmp.Width*bmp.Height*bpp);
       for i:=bmp.Height-1 downto 0 do begin
         p:=bmp.ScanLine[i]; offs:=i*bmp.Width*bpp;
         for j:=0 to bmp.Width-1 do begin
            PByteArray(pData)[offs+j*bpp]:=p[j*bpp+2];
            PByteArray(pData)[offs+j*bpp+1]:=p[j*bpp+1];
            PByteArray(pData)[offs+j*bpp+2]:=p[j*bpp];
         end;
       end; Width:=bmp.Width; Height:=bmp.Height;
       result:=pData; Format:=GL_RGB; exit;
    end;

    //BitmapLength := InfoHeader.biSizeImage;
    //if BitmapLength = 0 then
    bpp:=InfoHeader.biBitCount Div 8;
    BitmapLength := Width * Height * bpp;
    sLength:=Width*bpp; fLength:=0;
    if frac(sLength/4)>0 then fLength:=((sLength div 4)+1)*4-sLength;
    // Get the actual pixel data
    GetMem(pData, BitmapLength);
    result:=pData;
    for i:=0 to Height-1 do begin
      ReadFile(BitmapFile, pData^, sLength , ReadBytes, nil);
      ReadFile(BitmapFile, Temp, fLength , ReadBytes, nil);
      inc(integer(pData),sLength);
    end;
{    ReadFile(BitmapFile, pData^, BitmapLength, ReadBytes, nil);
    if (ReadBytes <> BitmapLength) then begin
      MessageBox(0, PChar('Error reading bitmap data'), PChar('BMP Unit'), MB_OK);
      Exit;
    end;
}
    CloseHandle(BitmapFile);

  // Bitmaps are stored BGR and not RGB, so swap the R and B bytes.
  if bpp=3 then begin SwapRGB(Result, Width*Height); Format:=GL_RGB; end;
  if bpp=4 then begin Format:=GL_BGRA; end;

end;


{------------------------------------------------------------------}
{  Load JPEG textures                                              }
{------------------------------------------------------------------}
function LoadJPGTexture(Filename: String; var Format: Cardinal; var Width, Height: integer): pointer;
var
  W : Integer;
  H : Integer;
  BMP : TBitmap;
  JPG : TJPEGImage;
  p: PByteArray;
  pData : PByteArray;
  bpp: byte;
  ResStream : TResourceStream;      // used for loading from resource
begin
  result := nil;
  JPG:=TJPEGImage.Create;

  try
    JPG.LoadFromFile(Filename);
  except
    MessageBox(0, PChar('Couldn''t load JPG - "'+ Filename +'"'), PChar('BMP Unit'), MB_OK);
    Exit;
  end;


  // Create Bitmap
  BMP:=TBitmap.Create;
  BMP.width:=JPG.width;
  BMP.height:=JPG.height;
  BMP.pixelformat:=pf24bit;
  BMP.canvas.draw(0,0,JPG);        // Copy the JPEG onto the Bitmap
  bpp:=3;
  Width :=BMP.Width;
  Height:=BMP.Height;
  getmem(pData,(Width+1)*(Height+1)*4);
  {$R-}
  for H:=0 to Height-1 do begin
    P:=BMP.scanline[Height-H-1];
    for W:=0 to Width-1 do begin
      pData[(H*Width+W)*bpp]:=P[W*bpp+2];
      pData[(H*Width+W)*bpp+1]:=P[W*bpp+1];
      pData[(H*Width+W)*bpp+2]:=P[W*bpp];
      //pData[(H*Width+W)*bpp+3]:=255;
    end;
  end;
  {$R+}
  BMP.free; JPG.free;

  Result:=pData;
  Format := GL_RGB
end;


{------------------------------------------------------------------}
{  Loads 24 and 32bpp (alpha channel) TGA textures                 }
{------------------------------------------------------------------}
function LoadTGATexture(Filename: String; var Format: Cardinal; var Width, Height: integer): pointer;
var
  TGAHeader : packed record   // Header type for TGA images
    FileType     : Byte;
    ColorMapType : Byte;
    ImageType    : Byte;
    ColorMapSpec : Array[0..4] of Byte;
    OrigX  : Array [0..1] of Byte;
    OrigY  : Array [0..1] of Byte;
    Width  : Array [0..1] of Byte;
    Height : Array [0..1] of Byte;
    BPP    : Byte;
    ImageInfo : Byte;
  end;
  TGAFile   : File;
  bytesRead : Integer;
  image     : Pointer;    {or PRGBTRIPLE}
  CompImage : Pointer;
  ColorDepth    : Integer;
  ImageSize     : Integer;
  BufferIndex : Integer;
  currentByte : Integer;
  CurrentPixel : Integer;
  I : Integer;
  Front: ^Byte;
  Back: ^Byte;
  Temp: Byte;

  ResStream : TResourceStream;      // used for loading from resource

  // Copy a pixel from source to dest and Swap the RGB color values
  procedure CopySwapPixel(const Source, Destination : Pointer);
  asm
    push ebx
    mov bl,[eax+0]
    mov bh,[eax+1]
    mov [edx+2],bl
    mov [edx+1],bh
    mov bl,[eax+2]
    mov bh,[eax+3]
    mov [edx+0],bl
    mov [edx+3],bh
    pop ebx
  end;
var loaded: boolean;
begin
  result :=nil;
  if FileExists(Filename) then begin
    AssignFile(TGAFile, Filename);
    Reset(TGAFile, 1);

    // Read in the bitmap file header
    BlockRead(TGAFile, TGAHeader, SizeOf(TGAHeader));
    loaded:=true;
  end
  else
  begin
    MessageBox(0, PChar('File not found  - ' + Filename), PChar('TGA Texture'), MB_OK);
    Exit;
  end;

  if loaded then begin
    Result := nil;

    // Only support 24, 32 bit images
    if (TGAHeader.ImageType <> 2) AND    { TGA_RGB }
       (TGAHeader.ImageType <> 10) then  { Compressed RGB }
    begin
      Result := nil;
      CloseFile(tgaFile);
      MessageBox(0, PChar('Couldn''t load "'+ Filename +'". Only 24 and 32bit TGA supported.'), PChar('TGA File Error'), MB_OK);
      Exit;
    end;

    // Don't support colormapped files
    if TGAHeader.ColorMapType <> 0 then
    begin
      Result := nil;
      CloseFile(TGAFile);
      MessageBox(0, PChar('Couldn''t load "'+ Filename +'". Colormapped TGA files not supported.'), PChar('TGA File Error'), MB_OK);
      Exit;
    end;

    // Get the width, height, and color depth
    Width  := TGAHeader.Width[0]  + TGAHeader.Width[1]  * 256;
    Height := TGAHeader.Height[0] + TGAHeader.Height[1] * 256;
    ColorDepth := TGAHeader.BPP;
    ImageSize  := Width*Height*(ColorDepth div 8);

    if ColorDepth < 24 then
    begin
      Result := nil;
      CloseFile(TGAFile);
      MessageBox(0, PChar('Couldn''t load "'+ Filename +'". Only 24 and 32 bit TGA files supported.'), PChar('TGA File Error'), MB_OK);
      Exit;
    end;

    GetMem(Image, ImageSize);

    if TGAHeader.ImageType = 2 then begin  // Standard 24, 32 bit TGA file
        BlockRead(TGAFile, image^, ImageSize, bytesRead);
        if bytesRead <> ImageSize then begin
          Result := nil;
          CloseFile(TGAFile);
          MessageBox(0, PChar('Couldn''t read file "'+ Filename +'".'), PChar('TGA File Error'), MB_OK);
          Exit;
        end;
      // TGAs are stored BGR and not RGB, so swap the R and B bytes.
      // 32 bit TGA files have alpha channel and gets loaded differently
      if TGAHeader.BPP = 24 then begin
        for I :=0 to Width * Height - 1 do begin
          Front := Pointer(Integer(Image) + I*3);
          Back := Pointer(Integer(Image) + I*3 + 2);
          Temp := Front^;
          Front^ := Back^;
          Back^ := Temp;
        end;
        Result := Image; Format := GL_RGB;
      end else begin
        for I :=0 to Width * Height - 1 do begin
          Front := Pointer(Integer(Image) + I*4);
          Back := Pointer(Integer(Image) + I*4 + 2);
          Temp := Front^;
          Front^ := Back^;
          Back^ := Temp;
        end;
        Result := Image; Format := GL_RGBA;
      end;
    end;

    // Compressed 24, 32 bit TGA files
    if TGAHeader.ImageType = 10 then begin
      ColorDepth :=ColorDepth DIV 8;
      CurrentByte :=0;
      CurrentPixel :=0;
      BufferIndex :=0;

        GetMem(CompImage, FileSize(TGAFile)-sizeOf(TGAHeader));
        BlockRead(TGAFile, CompImage^, FileSize(TGAFile)-sizeOf(TGAHeader), BytesRead);   // load compressed data into memory
        if bytesRead <> FileSize(TGAFile)-sizeOf(TGAHeader) then
        begin
          Result := nil;
          CloseFile(TGAFile);
          MessageBox(0, PChar('Couldn''t read file "'+ Filename +'".'), PChar('TGA File Error'), MB_OK);
          Exit;
        end;

      // Extract pixel information from compressed data
      repeat
        Front := Pointer(Integer(CompImage) + BufferIndex);
        Inc(BufferIndex);
        if Front^ < 128 then begin
          for I := 0 to Front^ do begin
            CopySwapPixel(Pointer(Integer(CompImage)+BufferIndex+I*ColorDepth), Pointer(Integer(image)+CurrentByte));
            CurrentByte := CurrentByte + ColorDepth;
            inc(CurrentPixel);
          end;
          BufferIndex :=BufferIndex + (Front^+1)*ColorDepth
        end else begin
          for I := 0 to Front^ -128 do begin
            CopySwapPixel(Pointer(Integer(CompImage)+BufferIndex), Pointer(Integer(image)+CurrentByte));
            CurrentByte := CurrentByte + ColorDepth;
            inc(CurrentPixel);
          end;
          BufferIndex :=BufferIndex + ColorDepth
        end;
      until CurrentPixel >= Width*Height;
      Result := Image;
      if ColorDepth = 3 then Format := GL_RGB
      else Format := GL_RGBA;
    end;
  end;
end;


function LoadSynopseJpeg(Filename: String; var cFormat,iFormat,dType,pSize : Cardinal;
  var Width, Height: integer): pointer;
var
    Img: PJpegDecode;
    i: integer;
    ps,pd: Pinteger;
    p: pointer;
begin
  with TMemoryStream.Create do
    try
      LoadFromFile(FileName);
      if not (JpegDecode(Memory,Size,img)=JPEG_SUCCESS)
      then begin
        result:=LoadJPGTexture(Filename, cFormat, Width, Height);
        iFormat:=GL_RGB8; dType:=GL_UNSIGNED_BYTE; pSize:=3;
        //assert('Not supported Jpeg format')
      end else begin
        Width:=img.width; Height:=img.height;
        pSize:=img.bitsPixel div 8;
        getmem(p,width*Height*pSize);
        ps:=Pinteger(img.pRGB); pd:=pinteger(p);
        for i:=0 to Height-1 do begin
          CopyMemory(pd,ps,img.width*pSize);
          inc(pd,img.width); inc(ps,img.scanlength);
        end;
        result:=p; dType:=GL_UNSIGNED_BYTE;
        case img.bitsPixel of
          32: begin
            iFormat:=GL_RGBA8; cFormat:=GL_BGRA;
            end;
          24: begin
            iFormat:=GL_RGB8; cFormat:=GL_BGR;
            end;
          8: begin
            iFormat:=GL_LUMINANCE8; cFormat:=GL_LUMINANCE;
          end;
        end;
        img.Free;
      end;
    finally
      Free;
    end;
end;


procedure SaveTGAImage(FileName: string; data: pointer; Width,Height: integer;
  PixelFormat: TPixelFormat);
var stream: TFileStream;
    y, rowSize: Integer;
    header: TTGAHeader;
    size: integer;
begin
   stream:=TFileStream.Create(FileName,fmCreate);
   // prepare the header, essentially made up from zeroes
   FillChar(header, SizeOf(TTGAHeader), 0);
   header.ImageType:=2;
   header.Width:=Width;
   header.Height:=Height;
   size:=Width*Height;
   case PixelFormat of
      pf24bit : begin header.PixelSize:=24; size:=size*3; end;
      pf32bit : begin header.PixelSize:=32; size:=size*4; end;
      pf8bit  : begin header.PixelSize:=8; size:=size; end;
   else
      Assert(false,'Unsupported Bitmap format');
   end;
   stream.Write(header, SizeOf(TTGAHeader));
   stream.Write(data^,size);
   stream.Free;
end;

var
  LoadJpeg: procedure (var Data: pointer; FileName: PWideChar;
    var IntFormat,ColorFormat: cardinal; var width,height: integer);
  jpgLibHandle: THandle = 0;

  LoadPNG: procedure (var Data: pointer; FileName: PWideChar;
    var IntFormat,ColorFormat,DataType,ElementSize: cardinal;
    var width,height: integer);
  ImgLibHandle: THandle = 0;

procedure InitJpegLoader;
begin
  jpgLibHandle := LoadLibrary('JpegLoader.dll');
  if jpgLibHandle<>0 then
    LoadJpeg:=GetProcAddress(Cardinal(jpgLibHandle), 'LoadJpeg');
  if (jpgLibHandle=0) or (not assigned(LoadJpeg)) then jpgLibHandle:=$FFFFFFFF;
end;

procedure InitImgLoader;
begin
  ImgLibHandle := LoadLibrary('ImgLoader.dll');
  if ImgLibHandle<>0 then begin
    LoadJpeg:=GetProcAddress(Cardinal(ImgLibHandle), 'LoadJpeg');
    LoadPng:=GetProcAddress(Cardinal(ImgLibHandle), 'LoadPNG');
  end else begin
    ImgLibHandle := LoadLibrary('JpegLoader.dll');
    if ImgLibHandle<>0 then
      LoadJpeg:=GetProcAddress(Cardinal(ImgLibHandle), 'LoadJpeg');
    LoadPng:=nil;
  end;
  if (ImgLibHandle=0) then ImgLibHandle:=$FFFFFFFF;
end;

{
procedure LoadPNG(var Data: pointer; FileName: String;
  var IntFormat,ColorFormat,DataType,ElementSize: cardinal;
  var width,height: integer); external 'ImgLoader.dll';
}

{procedure LoadJpeg(var Data: pointer; FileName: string;
  var IntFormat,ColorFormat: cardinal; var width,height: integer);
    external 'jpegLoader.dll';
}
{------------------------------------------------------------------}
{  Determines file type and sends to correct function              }
{------------------------------------------------------------------}
function LoadTexture(Filename: String; var Format: Cardinal;
  var Width, Height: integer) : pointer; overload;
var ext: string;
    ColorFormat,DataType,eSize: cardinal;
begin
  result:=nil; ext:=copy(Uppercase(filename), length(filename)-3, 4);
  if ext = '.BMP' then
    result:=LoadBMPTexture(Filename, Format, Width, Height);
  if ext = '.JPG' then begin
    if ImgLibHandle=0 then InitImgLoader;
    if ImgLibHandle<>$FFFFFFFF then begin
      LoadJpeg(result,PWideChar(FileName),ColorFormat,Format,Width,Height);
      flipSurface(result,Width,Height,3);
      if Format=$80E0 then begin SwapRGB(result,Width*Height); Format:=GL_RGB; end;
    end else result:=LoadJPGTexture(Filename, Format, Width, Height);
    //LoadJpeg(result,FileName,ColorFormat,Format,Width,Height);
  end;
  if ext = '.TGA' then
    result:=LoadTGATexture(Filename, Format, Width, Height);
  if ext = '.PNG' then begin
    if ImgLibHandle=0 then InitImgLoader;
    if (ImgLibHandle<> $FFFFFFFF) and (assigned(LoadPng)) then begin
      LoadPNG(result,PWideChar(FileName),ColorFormat,Format,DataType,eSize,Width,Height);
    end else assert(false,'PNG Textures not supported. Put ImgLoader.dll in search path');
  end;
end;

function LoadTexture(Filename: String; var iFormat,cFormat,dType,pSize: Cardinal;
  var Width, Height: integer): pointer; overload;
var ext: string;
begin
  result:=nil; ext:=copy(Uppercase(filename), length(filename)-3, 4);
  if ext = '.BMP' then begin
    result:=LoadBMPTexture(Filename, cFormat, Width, Height);
    if cFormat=GL_BGRA then begin
      iFormat:=GL_RGBA8; dType:=GL_UNSIGNED_BYTE; pSize:=4;
    end else begin
      iFormat:=GL_RGB8; dType:=GL_UNSIGNED_BYTE; pSize:=3;
    end;
  end;
  if ext = '.JPG' then begin
    if ImgLibHandle=0 then InitImgLoader;
    if ImgLibHandle<>$FFFFFFFF then begin
      LoadJpeg(result,PWideChar(FileName),iFormat,cFormat,Width,Height);
      if cFormat=$80E0 then begin
        SwapRGB(result,Width*Height);
        cFormat:=GL_RGB; iFormat:=GL_RGB8; pSize:=3;
      end else pSize:=1;
      flipSurface(result,Width,Height,pSize);
      dType:=GL_UNSIGNED_BYTE;
    end else begin
      result:=LoadSynopseJpeg(FileName,cFormat,iFormat,dType,pSize,Width,Height);
      //flipSurface(result,Width,Height,pSize);
    end;

  end;
  if ext = '.TGA' then begin
    result:=LoadTGATexture(Filename, cFormat, Width, Height);
    if cFormat=GL_RGB then begin
      iFormat:=GL_RGB8; pSize:=3;
    end else begin
      iFormat:=GL_RGBA8; pSize:=4;
    end; dType:=GL_UNSIGNED_BYTE;
  end;

  if ext = '.PNG' then begin
    if ImgLibHandle=0 then InitImgLoader;
    if (ImgLibHandle<> $FFFFFFFF) and (assigned(LoadPng)) then begin
      LoadPNG(result,PWideChar(FileName),iFormat,cFormat,dType,pSize,Width,Height);
    end else assert(false,'PNG Textures not supported. Put ImgLoader.dll in search path');
  end;
end;

initialization

finalization
//  if (jpgLibHandle<>0) and (jpgLibHandle<>$FFFFFFFF) then FreeLibrary(jpgLibHandle);
  if (ImgLibHandle<>0) and (ImgLibHandle<>$FFFFFFFF) then FreeLibrary(ImgLibHandle);

end.
