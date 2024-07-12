$moduleRoot = $PSScriptRoot
function Get-Icontheme {
    [CmdletBinding()]
    param()
    Get-ChildItem "$moduleRoot\*.theme.json" | ForEach-Object { $_.Name.Split('.')[0] }
}
function Set-Icontheme {
    [CmdletBinding()]
    param (
        [ArgumentCompleter({ 
                param ($commandName,
                    $parameterName,
                    $wordToComplete,
                    $commandAst,
                    $fakeBoundParameters 
                )
                Get-Icontheme | Where-Object {
                    $_ -like "$wordToComplete*"
                }
            })]
        [string]
        $Name
    )
    $json = [System.IO.File]::ReadAllText("$moduleRoot\$Name.theme.json")
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        $Script:icontheme = ConvertFrom-Json $json -AsHashtable
    }
    else {
        Add-Type -AssemblyName System.Web.Extensions
        $Script:icontheme = [System.Web.Script.Serialization.JavaScriptSerializer]::new().DeserializeObject($json)
    }
    $Script:palette = $icontheme['palette']
    $Script:folder_default = $icontheme['folder_default']
    $Script:folder_fullname = $icontheme['folder_fullname']
    $Script:file_default = $icontheme['file_default']
    $Script:file_fullname = $icontheme['file_fullname']
    $Script:file_double_extension = $icontheme['file_double_extension']
    $Script:file_extension = $icontheme['file_extension']
}
function Format-FileName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.IO.FileSystemInfo]
        $InputObject,
        [switch]$WithLinkTarget
    )
    $name = $InputObject.Name.ToLower()
    $icon = $null
    if ($InputObject -is [System.IO.DirectoryInfo]) {
        $icon = $folder_fullname[$name]
        if (-not $icon) { $icon = $folder_default }
    }
    else {
        if ($InputObject -isnot [System.IO.FileInfo]) { throw }
        $icon = $file_fullname[$name]
        if (-not $icon) {
            $name = $name.Split('.')
            $icon = $file_double_extension[$name[-1]]
            if ($icon -and $name[-2]) { $icon = $icon[$name[-2]] }
        }
        if (-not $icon) {
            $icon = $file_extension[$name[-1]]
        }
        if (-not $icon) { $icon = $file_default }
    }
    $result = $palette[$icon[1]], $icon[0], ' ', $palette[$icon[2]], $InputObject.Name, $palette[$icon[3]]
    if ($WithLinkTarget) {
        if (($linktarget = $InputObject.LinkTarget)) {
            $result += ' -> ', $linktarget
        }
    }
    return -join $result
}

Set-Icontheme seti
if ($PSVersionTable.PSVersion.Major -ge 7 -and $PSVersionTable.PSVersion.Minor -ge 2) {
    foreach ($typename in "System.IO.DirectoryInfo", "System.IO.FileInfo") {
        $typedata = Get-TypeData $typename
        Remove-TypeData $typename
        $typedata.Members['NameString'] = [System.Management.Automation.Runspaces.ScriptPropertyData]::new('NameString', { Format-FileName $this -WithLinkTarget }, $null)
        Update-TypeData -TypeData $typedata
    }
}
else { Update-FormatData -PrependPath $moduleRoot\FileSystem.Format.ps1xml }
