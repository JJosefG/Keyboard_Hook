object frmOptions: TfrmOptions
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Options'
  ClientHeight = 283
  ClientWidth = 542
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  PixelsPerInch = 96
  TextHeight = 13
  object gBoxBottom: TGroupBox
    Left = 0
    Top = 228
    Width = 542
    Height = 55
    Align = alBottom
    TabOrder = 0
    ExplicitTop = 216
    ExplicitWidth = 526
    DesignSize = (
      542
      55)
    object btnOK: TButton
      Left = 172
      Top = 16
      Width = 75
      Height = 25
      Anchors = []
      Caption = 'OK'
      Default = True
      ModalResult = 1
      TabOrder = 0
      ExplicitLeft = 168
    end
    object btnCancel: TButton
      Left = 294
      Top = 16
      Width = 75
      Height = 25
      Anchors = []
      Cancel = True
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 1
      ExplicitLeft = 288
    end
  end
  object gBoxLeft: TGroupBox
    Left = 0
    Top = 0
    Width = 217
    Height = 228
    Align = alLeft
    TabOrder = 1
    ExplicitHeight = 105
    object RadioGroup1: TRadioGroup
      Left = 3
      Top = 16
      Width = 198
      Height = 89
      Caption = 'Key Logging:'
      Items.Strings = (
        'Log all keys'
        'Log CAP/Numlock only')
      TabOrder = 0
    end
  end
end
