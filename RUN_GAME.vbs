Option Explicit

Dim shell, root, loveExe, command
Set shell = CreateObject("WScript.Shell")
root = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)

loveExe = "love.exe"
If shell.Run("cmd /c where love.exe", 0, True) <> 0 Then
    If CreateObject("Scripting.FileSystemObject").FileExists(root & "\runtime\love.exe") Then
        loveExe = root & "\runtime\love.exe"
    ElseIf CreateObject("Scripting.FileSystemObject").FileExists(shell.ExpandEnvironmentStrings("%ProgramFiles%") & "\LOVE\love.exe") Then
        loveExe = shell.ExpandEnvironmentStrings("%ProgramFiles%") & "\LOVE\love.exe"
    ElseIf CreateObject("Scripting.FileSystemObject").FileExists(shell.ExpandEnvironmentStrings("%ProgramFiles(x86)%") & "\LOVE\love.exe") Then
        loveExe = shell.ExpandEnvironmentStrings("%ProgramFiles(x86)%") & "\LOVE\love.exe"
    Else
        MsgBox "LOVE 11.x was not found. Install it from https://love2d.org/.", vbExclamation, "Majic Blue Mechanics"
        WScript.Quit 1
    End If
End If

shell.CurrentDirectory = root
command = """" & loveExe & """ """" & root & """"
shell.Run command, 1, False
