program Balls;

uses
  Forms,
  BallMain in 'BallMain.pas' {Form1},
  BallObj in 'BallObj.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
