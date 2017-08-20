' Portable Node.js install script
' 2016/03/24 by thinkbase.net@gmail.com
' Reference: https://github.com/dmrub/portable-node/blob/master/bin/install-node.vbs

NODE_VERSION="v6.11.1"

' Declare all global variables
Dim FSO, WshShell, WshEnv, thisDir, VERBOSE

' Create objects that will be shared by all following code
Set FSO = CreateObject("Scripting.FileSystemObject")
Set WshShell = Wscript.CreateObject("Wscript.Shell")
Set WshEnv = WshShell.Environment("PROCESS")
Set stdout = FSO.GetStandardStream(1)
Set stderr = FSO.GetStandardStream(2)

thisDir = FSO.GetParentFolderName(Wscript.ScriptFullName)
baseDir = thisDir

' Check thisDir for existence
Assert FSO.FolderExists(thisDir), "Bootstrap: There is no directory " & thisDir & ", something is wrong"

' Set VERBOSE to True if we Wscript.Echo will print to console
VERBOSE = InConsole()

' Process command-line arguments
Set args = Wscript.Arguments

Dim nodeVersion, nodeArch, nodeURL, nodeMSIFile

nodeVersion = NODE_VERSION
nodeArch = "x86"
forceInstall = False

If args.Count > 0 Then
    If args(0) = "-h" Or args(0) = "-?" Or _
        args(0) = "--help" Or args(0) = "/?" Then
        Wscript.Echo "Node Portable Environment Setup Script" & vbCrLf & _
                    "Usage : " & Wscript.ScriptName & " [ /? ] [/version:node-version /arch:x86|x86_64|32|64 /force]" & vbCrLf & vbCrLf & _
                    "Options: /version:node-version         select node version to download (default : " & nodeVersion & ")" & vbCrLf & _
                    "         /arch:x86|x64|x86_64|32|64    select node architecture to download (default : " & nodeArch & ")" & vbCrLf & _
                    "         /force                        force download and installation" & vbCrLf & _
                    "         /?                            print this" & vbCrLf
        Wscript.Quit
    End If
    If args.Named.Exists("version") Then
        nodeVersion = args.Named.Item("version")
    End If
    If args.Named.Exists("arch") Then
        nodeArch = args.Named.Item("arch")
    End If
    If nodeArch = "x86_64" Then nodeArch = "x64"
    If nodeArch = "32" Then nodeArch = "x86"
    If nodeArch = "64" Then nodeArch = "x64"
    ' Check
    If nodeArch <> "x86" And nodeArch <> "x64" Then
        Error "Unsupported architecture: " & nodeArch, 1
    End If
    
    For i = 0 to args.Count-1
        arg = args.Item(i)
        If arg = "/force" Or arg = "-force" Then forceInstall = True
    Next
    
End If

' Setup paths
nodePrefix = "node-" & nodeVersion & "-" & nodeArch
nodeMSIFile = nodePrefix & ".msi"
If nodeArch = "x86" Then
    nodeURL = "http://nodejs.org/dist/" & nodeVersion & "/" & nodeMSIFile
Else
    nodeURL = "http://nodejs.org/dist/" & nodeVersion & "/x64/" & nodeMSIFile
End If

nodeBaseDirRel = "." 'relative to baseDir
nodeBaseDir = FSO.BuildPath(baseDir, nodeBaseDirRel)
nodeMSIPath = FSO.GetAbsolutePathName(FSO.BuildPath(nodeBaseDir & "\tmp", nodeMSIFile))
nodeInstallPathRel = nodeBaseDirRel & "\bin\" & ("node-" & nodeVersion & "-win-" & nodeArch) ' relative to baseDir
nodeInstallPath = FSO.GetAbsolutePathName(FSO.BuildPath(baseDir, nodeInstallPathRel))

Wscript.Echo "[PortableNodeJS] version: " & nodeVersion & " for architecture: " & nodeArch

' Extract node.js
nodeExePath = FSO.BuildPath(nodeInstallPath, "nodejs")
nodeExePathRel = FSO.BuildPath(nodeInstallPathRel, "nodejs")
nodeExeFile = FSO.BuildPath(nodeExePath, "node.exe")
nodeExeFileRel = FSO.BuildPath(nodeExePathRel, "node.exe")
If Not FSO.FileExists(nodeExeFile) Or forceInstall Then
	' Download node.js
	CreateFolderTree(nodeBaseDir & "\tmp")
	If Not FSO.FileExists(nodeMSIPath) Or forceInstall Then
		If Not Download(nodeURL, nodeMSIPath) Then Error "Could not download URL: " & nodeURL, 2
	Else
		Echo "File " & nodeMSIPath & " already exists, use /force to reload."
	End If

    Dim extractCmd
    extractCmd = "msiexec.exe /a """ & nodeMSIPath & """ /qn TARGETDIR=""" & nodeInstallPath & """"
    
    If FSO.FolderExists(nodeInstallPath) Then
        Echo "Deleting folder: " & nodeInstallPath
        FSO.DeleteFolder(nodeInstallPath)
    End If

    Echo "Running: " & extractCmd
    result = WshShell.Run(extractCmd, 1, True)
    Echo "Installation process for node.js return: " & result
    If result <> 0 Then Error "Could not install node.js", 3
    
    ' Delete MSI file produced by installer
    Dim msiFile2
    msiFile2 = FSO.BuildPath(nodeInstallPath, nodeMSIFile)
    If FSO.FileExists(msiFile2) Then
        Echo "Deleting file: " & msiFile2
        FSO.DeleteFile(msiFile2)
    End If

	Wscript.Echo "[PortableNodeJS] Installation finished: " & nodeExeFile
Else
    Wscript.Echo "[PortableNodeJS] installed: " & nodeExeFile & ". (else use /force to reinstall)."
End If

' Create node.js launch script
nodeScriptFile = FSO.BuildPath(baseDir, "bin\start-node.bat")
'If Not FSO.FileExists(nodeScriptFile) Or forceInstall Then
    Dim nodeCmdLine
    nodeCmdLine = """" & nodeExeFile & """ %*"
	Dim nodeScript
	Set nodeScript = FSO.CreateTextFile(nodeScriptFile, True)
	nodeScript.WriteLine("@echo [PortableNodeJS] call " & nodeCmdLine)
	nodeScript.WriteLine("@echo.")
	nodeScript.WriteLine("call " & nodeCmdLine)
	nodeScript.Close
	Wscript.Echo "[PortableNodeJS] node.js launch script: " & nodeScriptFile
'End If
' Create npm launch script
npmScriptFile = FSO.BuildPath(baseDir, "bin\start-npm.bat")
'If Not FSO.FileExists(npmScriptFile) Or forceInstall Then
	Dim npmCmdLine
    npmCmdLine = """" & nodeExeFile & """ """ & nodeExePath & "\node_modules\npm\bin\npm-cli.js"" %*"
	Dim npmRC
	npmRC = nodeExePath & "\node_modules\npm\npmrc"
	Dim npmScript
	Set npmScript = FSO.CreateTextFile(npmScriptFile, True)
	npmScript.WriteLine("@echo [PortableNodeJS] call " & npmCmdLine)
	npmScript.WriteLine("@echo.")
	npmScript.WriteLine("@SET BIN_PATH=" & nodeBaseDir + "\bin")
	npmScript.WriteLine("@echo prefix=%BIN_PATH%\npm-global > """  & npmRC & """")
	npmScript.WriteLine("@echo cache=%BIN_PATH%\npm-cache >> """ & npmRC & """")
	npmScript.WriteLine("@echo registry=https://registry.npm.taobao.org >> """ & npmRC & """")
	npmScript.WriteLine("call " & npmCmdLine)
	npmScript.Close
	Wscript.Echo "[PortableNodeJS] npm launch script: " & npmScriptFile
'End If

Wscript.Quit

' Help procedures and functions

' Download url and save to path
' http://www.codeproject.com/Tips/506439/Downloading-files-with-VBScript
Function Download(url, path)
    Dim objHTTP, objFSO
    ' Get file name from URL.
    ' http://download.windowsupdate.com/microsoftupdate/v6/wsusscan/wsusscn2.cab -> wsusscn2.cab

    Echo "Download URL: " & url & " to: " & path

    ' Create an HTTP object
    Set objHTTP = CreateObject( "WinHttp.WinHttpRequest.5.1" )

    ' Download the specified URL
    objHTTP.Open "GET", url, False
    ' Use HTTPREQUEST_SETCREDENTIALS_FOR_PROXY if user and password is for proxy, not for download the file.
    ' objHTTP.SetCredentials "User", "Password", HTTPREQUEST_SETCREDENTIALS_FOR_SERVER
    objHTTP.Send

    Set objFSO = CreateObject("Scripting.FileSystemObject")
    If objFSO.FileExists(path) Then
        objFSO.DeleteFile(path)
    End If

    If objHTTP.Status = 200 Then
        Dim objStream
        Set objStream = CreateObject("ADODB.Stream")
        With objStream
            .Type = 1 'adTypeBinary
            .Open
            .Write objHTTP.ResponseBody
            .SaveToFile path
            .Close
        End With
        set objStream = Nothing
    Else
        stderr.WriteLine "Could not download: " & url & " : " & objHTTP.Status & " " & objHTTP.StatusText
    End If

    If objFSO.FileExists(path) Then
        Echo "Download to `" & path & "` completed successfully."
        Download = True
    Else
        Download = False
    End If
End Function

Sub CreateFolderTree(folderPath)
    Dim objFSO, parent
    Set objFSO = CreateObject("Scripting.FileSystemObject")
    parent = objFSO.GetParentFolderName(folderPath)
    If Len(parent) > 0 And Not objFSO.FolderExists(parent) Then
        CreateFolderTree(parent)
    End If
    If Not objFSO.FolderExists(folderPath) Then
        objFSO.CreateFolder(folderPath)
    End If
End Sub

' Checks whether the script is started in text console (through CSCRIPT.EXE)
' or not
Function InConsole()
  InConsole = (UCase(Left(FSO.GetFileName(Wscript.FullName),7))  = "CSCRIPT")
End Function

' Echoes message if the script is in VERBOSE mode
' VERBOSE mode will be set at script start through call to InConsole
Sub Echo(msg)
    If VERBOSE Then Wscript.Echo "> " & msg
End Sub

' Show error message in message box or console and exit
Sub Error(msg, exitCode)
    If InConsole() Then
        stderr.WriteLine "Setup Error: " & msg 
    Else
        MsgBox msg, vbExclamation, "Setup Error"
    End If
    Wscript.Quit exitCode
End Sub

Sub Assert(cond, msg)
  If Not cond Then
    Error msg, 1
  End If
End Sub

' If VBasic error was happened exit script
Sub CheckVBError(msg,exitCode)
  If Err.Number <> 0 Then
    MsgBox msg & vbCrLf & Err.Description,vbExclamation, "Error"
    Wscript.Quit exitCode
  End If
End Sub
