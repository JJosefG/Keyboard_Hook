program Detect_Keys;

uses
  Vcl.Forms,
  DetectKeys in 'DetectKeys.pas' {frmDetectKeys},
  Options in 'Options.pas' {frmOptions};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.ShowMainForm := False;
  Application.CreateForm(TfrmDetectKeys, frmDetectKeys);
  Application.CreateForm(TfrmOptions, frmOptions);
  Application.Run;
end.

