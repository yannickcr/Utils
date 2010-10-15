#NoTrayIcon
#include <Array.au3>

$ver = '1.0.4'

_EnableConsole()

ConsoleWrite("GetText-JS [version " & $ver & "]" & @CRLF & @CRLF)

if($cmdLine[0]==1) Then
	displayHelp()
Else
	; Define the options
	$dFound = False
	$iFound = False
	$oFound = False
	$kFound = False
	$lFound = False
	$cFound = False
	$debug = False
	For $j = 1 to Ubound($cmdLine)-1
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
			$k = StringReplace(StringReplace($cmdLine[$j+1], '$set$', '([a-zA-Z0-9-_ ]+)'), '$key$', '([a-zA-Z0-9-_ ]+)')
			$kFound = True
		EndIf
		; l : Language file
		If ($cmdLine[$j]=="-l") Then
			$l = $cmdLine[$j+1]
			$lFound = True
		EndIf
		; c : Language code
		If ($cmdLine[$j]=="-c") Then
			$c = $cmdLine[$j+1]
			$cFound = True
		EndIf
		; debug : Debug
		If ($cmdLine[$j]=="-debug") Then
			$debug = True
		EndIf
	Next
	
	If($dFound==False) Then
		$d = '.\'
	EndIf
	If($iFound==False) Then
		$i = '*.js'
	EndIf
	If($oFound==False) Then
		displayHelp()
	EndIf
	If($kFound==False) Then
		$k = "MooTools.lang.get\('([a-zA-Z0-9-_ ]+)', '([a-zA-Z0-9-_ ]+)'\)"
	EndIf
	If($lFound==False) Then
		displayHelp()
	EndIf
	If($cFound==False) Then
		$c = 'en-US'
	EndIf
	
	ConsoleWrite('Opening the language file...' & @CRLF)
	
	; Load the locale file
	$locale = FileRead($l)
	$locale = StringSplit($locale, @LF)

	ConsoleWrite('Searching for strings to translate...please wait' & @CRLF)

	; Search for strings and save the results in the output file
	$files = _FileListToArrayEx2($d, $i, 1, '', True)
	_ArrayDelete($files,0)
	
	Dim $cascades[1]

	For $file In $files
		$data = FileRead($file)
		$matches = StringRegExp($data,$k,4)
		
		If Ubound($matches)==0 Then
			ContinueLoop
		EndIf
		
		If $debug Then
			ConsoleWrite(@CRLF & 'Found in ' & $file & ' :' & @CRLF)
		EndIf
		
		For $j = 0 to UBound($matches) - 1
			$tmp = $matches[$j]
			_ArrayAdd($cascades, $tmp[1] & ':' & $tmp[2])
			If $debug Then
				ConsoleWrite('	- ' & $tmp[1] & ': ' & $tmp[2] & @CRLF)
			EndIf
		Next
		
	Next
	If(UBound($cascades)==1) Then
		ConsoleWrite(@CRLF & '---------------------------------------------' & @CRLF)
		ConsoleWrite(' No strings found' & @CRLF)
		ConsoleWrite('---------------------------------------------' & @CRLF)
		Exit
	EndIf
	
	$cascades = _ArrayUnique($cascades, -1, 0, 1)
	_ArrayDelete($cascades,0)
	
	_ArraySort($cascades)
	_ArrayDelete($cascades,0)
	
	; Write the output file
	$template = ''
	$lastSet = ''
	
	For $cascade In $cascades
		$cascade = StringSplit($cascade, ':')
		
		if($lastSet <> $cascade[1]) Then
			if($lastSet <> '') Then
				$template = StringTrimRight($template,2)
				$template &= @LF & '});' & @LF & @LF
			EndIf
			$template &= "MooTools.lang.set('" & $c & "', '" & $cascade[1] & "', {" & @LF
			$lastSet = $cascade[1]
		EndIf
		
		$translation = _ArraySearch($locale, 'msgid "' & $cascade[2] & '"')
		If($translation == -1) Then
			$translation = $cascade[2]
		Else
			$translation = StringRegExpReplace($locale[$translation+1],'msgstr "(.*)"','$1')
		EndIf

		$template &= chr(9) & "'" & $cascade[2] & "': '" & addslashes($translation) & "'," & @LF
	Next
	
	$template = StringTrimRight($template,2)
	$template &= @LF & '});'
	
 	write($o,$template)
	ConsoleWrite(@CRLF & '---------------------------------------------' & @CRLF)
	ConsoleWrite(' ' & UBound($cascades) & ' string(s) added in ' & $o & @CRLF)
	ConsoleWrite('---------------------------------------------' & @CRLF)
	Exit
EndIf

Func displayHelp()
	ConsoleWrite('Browse your files to find the strings to translate.' & @CRLF & @CRLF)
	ConsoleWrite('Usage: ' & @ScriptName & ' -o Output -l File [-d Directory] [-i Filter] [-k Mask] [-debug]' & @CRLF & @CRLF)
	ConsoleWrite('	-o	Output file' & @CRLF)
	ConsoleWrite('	-d	Directory to search (current directory by default)' & @CRLF)
	ConsoleWrite('	-i	File filter (*.js by default)' & @CRLF)
	ConsoleWrite("	-k	Search mask, $key$ is the string to translate and $set$ his package (Mootools.lang.get('$set$','$key$') by default)" & @CRLF)
	ConsoleWrite('	-l	Language file' & @CRLF)
	ConsoleWrite('	-c	Language code (en-US by default)' & @CRLF)
	ConsoleWrite('	-debug	Debug mode' & @CRLF & @CRLF)
	Exit
EndFunc

Func write($file,$content)
	$file2 = FileOpen($file, 8+2)
	FileWrite($file2, $content)
	FileClose($file2)
EndFunc

Func addslashes($string)
    Local $output = StringReplace ( $string, '\', '\\' )
    $output = StringReplace ( $output, "'", "\'" )
    $output = StringReplace ( $output, '"', '\"' )
    $output = StringReplace ( $output, 'NUL', '\NUL' )
    Return $output
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

Func _EnableConsole()
    If @Compiled Then
        TraySetState(2)
        $hRead = FileOpen(@ScriptFullPath, 16)
        $bR = FileRead($hRead)
        FileClose($hRead)
        If BinaryMid($bR, 1, 2) <> "MZ"  Then
            MsgBox(0, "Error", "File is not an executable.")
            Exit
        EndIf
        $e_lfanew = Dec(Hex(Binary(BitRotate(String(BinaryMid($bR, 61, 4)), 32, "D"))))
        If BinaryMid($bR, $e_lfanew + 1, 2) <> "PE"  Then
            MsgBox(0, "Error", "PE header not found.")
            Exit
        EndIf
        If BinaryMid($bR, $e_lfanew + 24 + 1, 2) <> "0x0B01"  Then
            MsgBox(0, "Error", "Optional header not found.")
            Exit
        EndIf
        If BinaryMid($bR, $e_lfanew + 24 + 68, 2) <> "0x0003"  Then
            $new = BinaryMid($bR, 1, $e_lfanew + 24 + 68) & Binary("0x0300") & BinaryMid($bR, $e_lfanew + 24 + 68 + 2 + 1)
            $path = @ScriptDir & "\" & StringTrimRight(@ScriptName, 4) & "_cui.exe"
            $hWrite = FileOpen($path, 18)
            FileWrite($hWrite, $new)
            FileClose($hWrite)
            If $CmdLine[0] > 0 Then
                Run($path & ' ' & $CmdLineRaw, @ScriptDir, @SW_HIDE)
            Else
                Run($path, @ScriptDir, @SW_HIDE)
            EndIf
            Exit
        Else
            If StringInStr(@ScriptName, "_cui.exe") Then
                $file_name = StringTrimRight(@ScriptName, 8) & ".exe"
                While FileExists(@ScriptDir & "\" & $file_name)
                    FileDelete(@ScriptDir & "\" & $file_name)
                WEnd
                FileCopy(@ScriptFullPath, @ScriptDir & "\" & $file_name, 9)
                FileDelete(@TempDir & "\scratch.cmd")
                Local $cmdfile = ':loop' & @CRLF _
                         & 'del "' & @ScriptFullPath & '"' & @CRLF _
                         & 'if exist "' & @ScriptFullPath & '" goto loop' & @CRLF _
                         & 'del ' & @TempDir & '\scratch.cmd'
                FileWrite(@TempDir & "\scratch.cmd", $cmdfile)
                Run(@TempDir & "\scratch.cmd", @TempDir, @SW_HIDE)
               
                If $CmdLine[0] > 0 Then
                    ShellExecute(@ScriptDir & "\" & $file_name, $CmdLineRaw)
                Else
                    ShellExecute(@ScriptDir & "\" & $file_name)
                EndIf
                Exit
            Else
                Return 0
            EndIf
        EndIf
    EndIf
EndFunc