unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls,Process, Graphics, Dialogs, EditBtn, StdCtrls, FileUtil;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    DirectoryEdit1: TDirectoryEdit;
    GroupBox2: TGroupBox;
    ListBox1: TListBox;
    procedure Button1Click(Sender: TObject);
    procedure DirectoryEdit1Change(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.DirectoryEdit1Change(Sender: TObject);
begin
 FindAllFiles(ListBox1.Items,DirectoryEdit1.Directory,'*.dat;',False);
end;

procedure TForm1.Button1Click(Sender: TObject);
var ShProcess:TProcess;
    cArgs, cArgs2: String;
    i: integer;
begin
   cArgs := 'python3 '  + 'Dat2ObjTex.py ';
   for i :=0 to ListBox1.Items.Count -1 do
   begin
     ShProcess := TProcess.Create(nil);
     ShProcess.Executable := 'python3';

     writeln(paramstr(0)+'/Dat2ObjTex.py');
     ShProcess.Parameters.Add('Dat2ObjTex.py');
     //ShProcess.Parameters.Add(cArgs);

     ShProcess.Parameters.Add(ExtractFileName(ListBox1.Items.Strings[i]));
     ShProcess.Options := ShProcess.Options + [poWaitOnExit, poUsePipes];
     ShProcess.Execute;
    // ShProcess.Free;
   end;
end;

end.

