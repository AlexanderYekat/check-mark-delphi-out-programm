program check_marks_pr;

uses
  Vcl.Forms, Windows,
  check_marks in 'check_marks.pas' {CheckMarksForm};

{$R *.res}

var
  hwnd: THandle;

begin
  hwnd := FindWindow('TCheckMarksForm', 'CheckMarksForm');
  if hwnd = 0 then
  begin
    Application.Initialize;
    Application.MainFormOnTaskbar := True;
    Application.CreateForm(TCheckMarksForm, CheckMarksForm);
    Application.Run;
  end
  else exit;
end.
