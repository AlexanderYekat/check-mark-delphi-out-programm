program check_marks_pr;

uses
  Vcl.Forms,
  check_marks in 'check_marks.pas' {CheckMarksForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TCheckMarksForm, CheckMarksForm);
  Application.Run;
end.
