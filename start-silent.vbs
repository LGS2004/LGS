' Plays the DeepSeek Harness boot animation, then opens the client.
' Runs PowerShell with a hidden window so only the animation is visible.
Option Explicit

Dim shell, fso, here, command
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

here = fso.GetParentFolderName(WScript.ScriptFullName)
command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & here & "\launch.ps1"""

shell.Run command, 0, False
