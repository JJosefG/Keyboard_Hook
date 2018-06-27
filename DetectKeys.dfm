object frmDetectKeys: TfrmDetectKeys
  Left = 0
  Top = 0
  Caption = 'Detect Key States'
  ClientHeight = 239
  ClientWidth = 566
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object pmnu: TPopupMenu
    Left = 16
    Top = 16
    object mnuOptions: TMenuItem
      Caption = 'Options'
      Hint = 'Set advanced program options'
      OnClick = mnuOptionsClick
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object mnuExit: TMenuItem
      Caption = 'E&xit'
      Hint = 'Exit the program'
      OnClick = mnuExitClick
    end
  end
  object tmr_1: TTimer
    Left = 16
    Top = 72
  end
end
