@(Get-Command pwsh.exe -All) + @(Get-Command powershell.exe -All) | ForEach-Object {
    $_
    & $_.Source -Command "cd ""$PSScriptRoot"";Measure-Command {ipmo ..\Swift-Powershell-File-Icon}|select Milliseconds;ls|ft"
}
