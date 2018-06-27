//----------------------------------------------------------------------------------------------------------------------
//--- File:      Build.inc
//--- Platform:  WIN 32
//--- Purpose:   contains compiler switches, build information and revision
//--             Detect_Keys.exe
//---
//--- Created:   Nov 2018
//--- Revisions: see detailed list below
//--- Author:    JJG
//--- Compiler:  Delphi 10
//----------------------------------------------------------------------------------------------------------------------
//
//------------Version-specific define statements------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------------------------

const

  {.$Define JJG_Release}         //activate for release...if not activated then we are debugging locally

  {$IfDef JJG_Release}
    strClassName              = 'TfrmDetectKeys';                 //remove dot when compiling for single-instance release
  {$Else}
    strClassName              = '.TfrmDetectKeys';                 //remove dot when compiling for single-instance release
  {$EndIf}

   strAppTitle               = 'Detect_Key_State';
   strCompany                = 'Atlantic Zeiser';
   strCopyRightDate          = '2018';
   strBuildDate              = 'Tue, 26 June 2018, 09:31';

   {$ifdef PREVIEW}
     strBuildType            = 'EVALUATION Version';
     strComment              = 'For Evaluation use only';
   {$else}
     strBuildType            = 'Version 100';
   {$endif}

   strComment                = 'Standard Edition';

   iVersion                  = 100;           //used for Version checking at first program run
   strVersion                = '1.00';        //Commercial Version Number

  {$IfDef JJG_Release}

  {$Else}
    {$Define JJG_Debug}          //de-activate for release...turns IO checking off if active, enables keybaord input to simulate IO events
  {$EndIf}

  {$Define Use_Keyboard_Hook}
  {ifNDef UseKeyboard_Hook}
    {$Define Use_Timer}
  {EndIfN}

//---------------------------------------------------------------------------------------------------------------------
//-- Revision History -------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------
//-- Build 1.00 26Jun2018 - Initial tryoputs. Add conditional compile in Build.inc to use either keyboard hook or timer to catch keybaord state change
//---------------------------------------------------------------------------------------------------------------------
//-- Build 1.01 26Jun2018 -
//-- 1 .Added Logging. Added conditional compile for using either Keyboard Hook or Timer to capture keyboard state.
//-- 2. Added simple ini file to track settings


