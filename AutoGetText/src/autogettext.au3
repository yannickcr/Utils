#NoTrayIcon
#include <Array.au3>

$ver = '1.0.5'

ConsoleWrite("GetText [version " & $ver & "]" & @CRLF & @CRLF)

if($cmdLine[0]==0) Then
	displayHelp()
Else
	; Define the options
	$dFound = False
	$cFound = False
	$iFound = False
	$oFound = False
	$kFound = False
	$pFound = False
	$trFound = False
	$tFound = False
	$eFound = False
	$debug = False
	For $j = 1 to Ubound($cmdLine)-1
		; c : Config file
		If ($cmdLine[$j]=="-c") Then
			$c = $cmdLine[$j+1]
			$cFound = True
			ExitLoop
		EndIf
		; d : Directory
		If ($cmdLine[$j]=="-d") Then
			$d = $cmdLine[$j+1]
			$dFound = True
		EndIf
		; i : Files filter
		If ($cmdLine[$j]=="-i") Then
			$i = $cmdLine[$j+1]
			$iFound = True
		EndIf
		; o : Output file
		If ($cmdLine[$j]=="-o") Then
			$o = $cmdLine[$j+1]
			$oFound = True
		EndIf
		; k : Search mask
		If ($cmdLine[$j]=="-k") Then
			$k = StringReplace($cmdLine[$j+1],'$var$','([a-zA-Z0-9-_ ]+)')
			$kFound = True
		EndIf
		; p : Project Id Version
		If ($cmdLine[$j]=="-p") Then
			$p = $cmdLine[$j+1]
			$pFound = True
		EndIf
		; tr : Last Translator
		If ($cmdLine[$j]=="-tr") Then
			$tr = $cmdLine[$j+1]
			$trFound = True
		EndIf
		; t : Language Team
		If ($cmdLine[$j]=="-t") Then
			$t = $cmdLine[$j+1]
			$tFound = True
		EndIf
		; e : Charset
		If ($cmdLine[$j]=="-e") Then
			$e = $cmdLine[$j+1]
			$eFound = True
		EndIf
		; debug : Debug
		If ($cmdLine[$j]=="-debug") Then
			$debug = True
		EndIf
	Next
	
	If($cFound==True) Then
			$d = IniRead($c, 'Config', 'Directory', '.\')
			$o = IniRead($c, 'Config', 'Output', 'default.pot')
			$i = IniRead($c, 'Config', 'File filter', '*')
			$k = IniRead($c, 'Config', 'Search mask', "_\([\'|" & '\"' & "]([a-zA-Z0-9-_ ]+)[\'|" & '\"' & "]\)")
			$p = IniRead($c, 'Config', 'Project Name', '')
			$tr = IniRead($c, 'Config', 'Translator', '')
			$t = IniRead($c, 'Config', 'Language Team', '')
			$e = IniRead($c, 'Config', 'Charset', 'UTF-8')
			$debug = IniRead($c, 'Config', 'Debug', False)
	Else
		If($dFound==False) Then
			$d = '.\'
		EndIf
		If($iFound==False) Then
			$i = '*'
		EndIf
		If($oFound==False) Then
			displayHelp()
		EndIf
		If($kFound==False) Then
			$k = "_\([\'|" & '\"' & "]([a-zA-Z0-9-_ ]+)[\'|" & '\"' & "]\)"
		EndIf
		If($pFound==False) Then
			$p = ''
		EndIf
		If($trFound==False) Then
			$tr = ''
		EndIf
		If($tFound==False) Then
			$t = ''
		EndIf
		If($eFound==False) Then
			$e = 'UTF-8'
		EndIf
	EndIf

	ConsoleWrite('Searching for strings to translate...please wait' & @CRLF)

	; Search for strings and save the results in the output file
	$d = StringSplit($d,';')
	_ArrayDelete($d,0)
	
	Dim $files[1]
	
	For $dir in $d
		$tmp = _FileListToArrayEx2($dir, $i, 1, "",True)
		_ArrayDelete($tmp,0)
		_ArrayConcatenate($files,$tmp)
	Next
	
	_ArrayDelete($files,0)
	
	Dim $strings[1]
	
	$k = StringSplit($k,';')
	_ArrayDelete($k,0)

	For $file In $files
		Dim $matches[1]
		$data = FileRead($file)
		For $mask in $k
			$tmp = StringRegExp($data,$mask,4)
			If IsArray($tmp) Then
				_ArrayConcatenate($matches,$tmp)
			EndIf
		Next

		If Ubound($matches)==1 Then
			ContinueLoop
		EndIf
		
		If $debug Then
			ConsoleWrite(@CRLF & 'Found in ' & $file & ' :' & @CRLF)
		EndIf
		
		For $j = 1 to UBound($matches) - 1
			$tmp = $matches[$j]
			_ArrayAdd($strings, $tmp[1])
			If $debug Then
				ConsoleWrite('	- ' & $tmp[1] & @CRLF)
			EndIf
		Next
	Next
	If(UBound($strings)==1) Then
		ConsoleWrite(@CRLF & '---------------------------------------------' & @CRLF)
		ConsoleWrite(' No strings found' & @CRLF)
		ConsoleWrite('---------------------------------------------' & @CRLF)
		Exit
	EndIf
	
	$strings = _ArrayUnique($strings, -1, 0, 1)
	_ArrayDelete($strings,0)
	
	_ArraySort($strings)
	_ArrayDelete($strings,0)
	
	; Write the output file
	$date = @YEAR & '-' & @MON & '-' & @MDAY & 'T' & @HOUR & ':' & @MIN & ':' & @SEC & '+00:00'
	$template =   'msgid ""' & @LF
	$template &=  'msgstr ""' & @LF
	$template &=  '"Project-Id-Version: ' & $p & '\n"' & @LF
 	$template &=  '"Report-Msgid-Bugs-To: \n"' & @LF
	$template &=  '"POT-Creation-Date: ' & $date & '\n"' & @LF
	$template &=  '"PO-Revision-Date: ' & $date & '\n"' & @LF
	$template &=  '"Last-Translator: ' & $tr & '\n"' & @LF
	$template &=  '"Language-Team: ' & $t & '\n"' & @LF
	$template &=  '"MIME-Version: 1.0\n"' & @LF
	$template &=  '"Content-Type: text/plain; charset=' & $e & '\n"' & @LF
	$template &=  '"Content-Transfer-Encoding: 8bit\n"' & @LF
	
	For $string In $strings
		$template &= @LF
		$template &= 'msgid "' & $string & '"' & @LF
		$template &= 'msgstr ""' & @LF
	Next
	
 	write($o,$template)
	ConsoleWrite(@CRLF & '---------------------------------------------' & @CRLF)
	ConsoleWrite(' ' & UBound($strings) & ' string(s) added in ' & $o & @CRLF)
	ConsoleWrite('---------------------------------------------' & @CRLF)
	Exit
EndIf

Func displayHelp()
	ConsoleWrite('Browse your files to find the strings to translate.' & @CRLF & @CRLF)
	ConsoleWrite('Usage: ' & @ScriptName & ' -o Output [-d Directory] [-i Filter] [-k Mask] [-p ID] [-tr Translator] [-t Language team] [-e Charset] [-debug]' & @CRLF & @CRLF)
	ConsoleWrite('	-c	Config file (if specified, all others command line parameters will be ignored)' & @CRLF)
	ConsoleWrite('	-o	Output file' & @CRLF)
	ConsoleWrite('	-d	Directory to search (current directory by default)' & @CRLF)
	ConsoleWrite('	-i	File filter (* by default)' & @CRLF)
	ConsoleWrite("	-k	Search mask, $var$ is the string to translate (_('$var$') by default)" & @CRLF)
	ConsoleWrite('	-p	Project Name' & @CRLF)
	ConsoleWrite('	-tr	Last translator name' & @CRLF)
	ConsoleWrite("	-t	Language team name" & @CRLF)
	ConsoleWrite('	-e	Charset (UTF-8 by default)' & @CRLF)
	ConsoleWrite('	-debug	Debug mode' & @CRLF & @CRLF)
	Exit
EndFunc

Func write($file,$content)
	$file2 = FileOpen($file, 8+2)
	FileWrite($file2, $content)
	FileClose($file2)
EndFunc

;===============================================================================
;
; Description:      lists all or preferred files and or folders in a specified path RECURSIVELY (Similar to using Dir with the /B Switch)
; Syntax:           _FileListToArrayEx($sPath, $sFilter = '*.*', $iFlag = 0, $sExclude = '', $iRecurse = False)
; Parameter(s):     $sPath = Path to generate filelist for
;               $sFilter = The filter to use. Search the Autoit3 manual for the word "WildCards" For details, support now for multiple searches
;                     Example *.exe; *.txt will find all .exe and .txt files
;                   $iFlag = determines weather to return file or folders or both.
;               $sExclude = exclude a file from the list by all or part of its name.  Now you can use multiple excludes with with or w/o wildcards.
;                     Example: Unins* will remove all files/folders that start with Unins
;                  $iFlag=0(Default) Return both files and folders
;                       $iFlag=1 Return files Only
;                  $iFlag=2 Return Folders Only
;            $iRecurse = True = Recursive, False = Standard
;
; Requirement(s):   None
; Return Value(s):  On Success - Returns an array containing the list of files and folders in the specified path
;                        On Failure - Returns the an empty string "" if no files are found and sets @Error on errors
;                  @Error or @extended = 1 Path not found or invalid
;                  @Error or @extended = 2 Invalid $sFilter or Invalid $sExclude
;                       @Error or @extended = 3 Invalid $iFlag
;                     @Error or @extended = 4 No File(s) Found
;
; Author(s):        SmOke_N
; Note(s):      The array returned is one-dimensional and is made up as follows:
;               $array[0] = Number of Files\Folders returned
;               $array[1] = 1st File\Folder
;               $array[2] = 2nd File\Folder
;               $array[3] = 3rd File\Folder
;               $array[n] = nth File\Folder
;
;               All files are written to a "reserved" .tmp file (Thanks to gafrost) for the example
;               The Reserved file is then read into an array, then deleted
;===============================================================================

Func _FileListToArrayEx2($sPath, $sFilter = '*.*', $iFlag = 0, $sExclude = '', $iRecurse = False)
    If Not FileExists($sPath) Then Return SetError(1, 1, '')
    If $sFilter = -1 Or $sFilter = Default Then $sFilter = '*.*'
    If $iFlag = -1 Or $iFlag = Default Then $iFlag = 0
    If $sExclude = -1 Or $sExclude = Default Then $sExclude = ''
    Local $aBadChar[6] = ['\', '/', ':', '>', '<', '|']
    $sFilter = StringRegExpReplace($sFilter, '\s*;\s*', ';')
    If StringRight($sPath, 1) <> '\' Then $sPath &= '\'
    For $iCC = 0 To 5
        If StringInStr($sFilter, $aBadChar[$iCC]) Or _
            StringInStr($sExclude, $aBadChar[$iCC]) Then Return SetError(2, 2, '')
    Next
    If StringStripWS($sFilter, 8) = '' Then Return SetError(2, 2, '')
    If Not ($iFlag = 0 Or $iFlag = 1 Or $iFlag = 2) Then Return SetError(3, 3, '')
    Local $oFSO = ObjCreate("Scripting.FileSystemObject"), $sTFolder
    $sTFolder = $oFSO.GetSpecialFolder(2)
    Local $hOutFile = @TempDir & $oFSO.GetTempName
    If Not StringInStr($sFilter, ';') Then $sFilter &= ';'
    Local $aSplit = StringSplit(StringStripWS($sFilter, 8), ';'), $sRead, $sHoldSplit
    For $iCC = 1 To $aSplit[0]
        If StringStripWS($aSplit[$iCC],8) = '' Then ContinueLoop
        If StringLeft($aSplit[$iCC], 1) = '.' And _
            UBound(StringSplit($aSplit[$iCC], '.')) - 2 = 1 Then $aSplit[$iCC] = '*' & $aSplit[$iCC]
        $sHoldSplit &= '"' & $sPath & $aSplit[$iCC] & '" '
    Next
    $sHoldSplit = StringTrimRight($sHoldSplit, 1)
       
    If $iRecurse Then
        RunWait(@Comspec & ' /c dir /b /s /a ' & $sHoldSplit & ' > "' & $hOutFile & '"', '', @SW_HIDE)
    Else
        RunWait(@ComSpec & ' /c dir /b /a ' & $sHoldSplit & ' /o-e /od > "' & $hOutFile & '"', '', @SW_HIDE)
    EndIf
    $sRead &= FileRead($hOutFile)
    If Not FileExists($hOutFile) Then Return SetError(4, 4, '')
    FileDelete($hOutFile)
    If StringStripWS($sRead, 8) = '' Then SetError(4, 4, '')
    Local $aFSplit = StringSplit(StringTrimRight(StringStripCR($sRead), 1), @LF)
    Local $sHold, $a_AnsiFName
    For $iCC = 1 To $aFSplit[0]
        ; translate DOS filenames from OEM to ANSI
        $a_AnsiFName = DllCall('user32.dll','Int','OemToChar','str',$aFSplit[$iCC],'str','')
        If @error=0 Then $aFSplit[$iCC] = $a_AnsiFName[2]

        If $sExclude And StringLeft($aFSplit[$iCC], _
            StringLen(StringReplace($sExclude, '*', ''))) = StringReplace($sExclude, '*', '') Then ContinueLoop
        Switch $iFlag
            Case 0
                If StringRegExp($aFSplit[$iCC], '\w:\\') = 0 Then
                    $sHold &= $sPath & $aFSplit[$iCC] & Chr(1)
                Else
                    $sHold &= $aFSplit[$iCC] & Chr(1)
                EndIf
            Case 1
                If StringInStr(FileGetAttrib($sPath & '\' & $aFSplit[$iCC]), 'd') = 0 And _
                    StringInStr(FileGetAttrib($aFSplit[$iCC]), 'd') = 0 Then
                    If StringRegExp($aFSplit[$iCC], '\w:\\') = 0 Then
                        $sHold &= $sPath & $aFSplit[$iCC] & Chr(1)
                    Else
                        $sHold &= $aFSplit[$iCC] & Chr(1)
                    EndIf
                EndIf
            Case 2
                If StringInStr(FileGetAttrib($sPath & '\' & $aFSplit[$iCC]), 'd') Or _
                    StringInStr(FileGetAttrib($aFSplit[$iCC]), 'd') Then
                    If StringRegExp($aFSplit[$iCC], '\w:\\') = 0 Then
                        $sHold &= $sPath & $aFSplit[$iCC] & Chr(1)
                    Else
                        $sHold &= $aFSplit[$iCC] & Chr(1)
                    EndIf
                EndIf
        EndSwitch
    Next
    If StringTrimRight($sHold, 1) Then Return StringSplit(StringTrimRight($sHold, 1), Chr(1))
    Return SetError(4, 4, '')
EndFunc