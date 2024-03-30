#cs Copyright
    Copyright 2024 Danysys. <hello@danysys.com>
    Licensed under the MIT license.
    See LICENSE file or go to https://opensource.org/licenses/MIT for details.
#ce Copyright

#cs Information
    Author(s)......: DanysysTeam (Danyfirex & Dany3j)
    Description....:  AutoIt Wrapper for RapidOCR: A library that empowers AutoIt users to extract text from images using the robust RapidOCR engine.
    Version........: 1.0.0
    AutoIt Version.: 3.3.14.5
    Thanks to .....:
                     https://github.com/RapidAI/RapidOCR
#ce Information

#Region Settings
#AutoIt3Wrapper_AU3Check_Parameters=-q -d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
#Tidy_Parameters=/tcb=-1 /sf /ewnl /reel /gd ;/sfc
#EndRegion Settings

#include-once
#include <File.au3>

; ===============================================================================================================================

; #CURRENT# =====================================================================================================================
; _RapidOCR_ImageToText
; _RapidOCR_LoadModel
; ===============================================================================================================================

; #INTERNAL_USE_ONLY# ===========================================================================================================
; __RapidOCR_Initialize
; __RapidOCR_GetLen
; __RapidOCR_GetResult
; __RapidOCR_GetDirectory
; __RapidOCR_GetFileName
; ===============================================================================================================================

Global $__ghRapidOCRLib = 0
Global $__ghRapidOCR = 0
Global $g__gtRAPIDOCR_PARAM = DllStructCreate("int padding;int maxSideLen;float boxScoreThresh;float boxThresh;float unClipRatio;int doAngle;int mostAngle")

If @ScriptName = "RapidOCR.au3" Then __TestRapidOCR()

Func __TestRapidOCR()
	Local $aFiles[] = ["Image1.png", "Image2.png", "Image3.jpg", "Image4.jpg"]

	For $i = 0 To UBound($aFiles) - 1
		MsgBox(0, "", _RapidOCR_ImageToText(@ScriptDir & "\images\" & $aFiles[$i]))
	Next
EndFunc   ;==>_TestRapidOCR

Func _RapidOCR_ImageToText($sPathImage, $iPadding = 50, $iMaxSizeLen = 1024, $fBoxScoreThresh = 0.6, $fBoxThresh = 0.3, $fUnClipRatio = 2.0, $iDoAngle = 1, $iMostAngle = 1)
	If Not $__ghRapidOCRLib Then
		__RapidOCR_Initialize()
	EndIf

	DllStructSetData($g__gtRAPIDOCR_PARAM, 1, $iPadding)
	DllStructSetData($g__gtRAPIDOCR_PARAM, 2, $iMaxSizeLen)
	DllStructSetData($g__gtRAPIDOCR_PARAM, 3, $fBoxScoreThresh)
	DllStructSetData($g__gtRAPIDOCR_PARAM, 4, $fBoxThresh)
	DllStructSetData($g__gtRAPIDOCR_PARAM, 5, $fUnClipRatio)
	DllStructSetData($g__gtRAPIDOCR_PARAM, 6, $iDoAngle)
	DllStructSetData($g__gtRAPIDOCR_PARAM, 7, $iMostAngle)

	If Not $__ghRapidOCR Then
		_RapidOCR_LoadModel()
	EndIf

	Local $aCall = DllCall($__ghRapidOCRLib, "ptr:cdecl", "OcrDetect", "handle", $__ghRapidOCR, "str", __RapidOCR_GetDirectory($sPathImage), "str", __RapidOCR_GetFileName($sPathImage), "struct*", $g__gtRAPIDOCR_PARAM)
	If @error Or Not $aCall[0] Then Return SetError(1, 0, "")

	Local $iLen = __RapidOCR_GetLen()
	Return BinaryToString(StringToBinary(__RapidOCR_GetResult($iLen)),4)

EndFunc   ;==>_RapidOCR_ImageToText

Func _RapidOCR_LoadModel($sPathDefaultModel = @ScriptDir & "\RapidOCR\onnx-models\", $sPathDetModel = "ch_PP-OCRv3_det_infer.onnx", $sPathClsModel = "ch_ppocr_mobile_v2.0_cls_infer.onnx", _
		$sPathRecModel = "ch_PP-OCRv3_rec_infer.onnx", $sPathKey = "ppocr_keys_v1.txt")

	If Not $__ghRapidOCRLib Then
		__RapidOCR_Initialize()
	EndIf

	Local $aCall = DllCall($__ghRapidOCRLib, "handle:cdecl", "OcrInit", "str", $sPathDefaultModel & $sPathDetModel, "str", $sPathDefaultModel & $sPathClsModel, "str", $sPathDefaultModel & $sPathRecModel, _
			"str", $sPathDefaultModel & $sPathKey, "int", 1)
	If @error Or Not $aCall[0] Then Return SetError(1, 0, 0)
	$__ghRapidOCR = $aCall[0]

EndFunc   ;==>_RapidOCR_LoadModel

Func __RapidOCR_GetDirectory($sPathImage)
	Local $szDrive, $szDir, $szFName, $szExt
	_PathSplit($sPathImage, $szDrive, $szDir, $szFName, $szExt)
	Return $szDrive & $szDir
EndFunc   ;==>__RapidOCR_GetDirectory

Func __RapidOCR_GetFileName($sPathImage)
	Local $szDrive, $szDir, $szFName, $szExt
	_PathSplit($sPathImage, $szDrive, $szDir, $szFName, $szExt)
	Return $szFName & $szExt
EndFunc   ;==>__RapidOCR_GetFileName

Func __RapidOCR_GetLen()
	Local $aCall = DllCall($__ghRapidOCRLib, "int:cdecl", "OcrGetLen", "handle", $__ghRapidOCR)
	If @error Or Not $aCall[0] Then Return SetError(1, 0, 0)
	Return $aCall[0]
EndFunc   ;==>__RapidOCR_GetLen

Func __RapidOCR_GetResult($iLen)
	Local $tString = DllStructCreate("char [" & $iLen & "]")
	Local $aCall = DllCall($__ghRapidOCRLib, "bool:cdecl", "OcrGetResult", "handle", $__ghRapidOCR, "struct*", $tString, "int", $iLen)
	If @error Or Not $aCall[0] Then Return SetError(1, 0, "")
	Return DllStructGetData($tString, 1)
EndFunc   ;==>__RapidOCR_GetResult

Func __RapidOCR_Initialize()
	$__ghRapidOCRLib = DllOpen(@ScriptDir & "\RapidOCR\" & (@AutoItX64 ? "x64" : "x86") & "\RapidOcrOnnx.dll")
	If @error Or Not $__ghRapidOCRLib Then Return SetError(1, 0, 0)
EndFunc   ;==>__RapidOCR_Initialize