#Requires -Version 7

$ErrorActionPreference = 'Stop'

$resp = Invoke-WebRequest 'https://www.nerdfonts.com/cheat-sheet'
if ($resp.StatusCode -ne 200) { throw 'network failure' }
[hashtable]$glyphs = [regex]::Match($resp.Content, 'const glyphs = ({[^}]*})').Groups[1].Value | ConvertFrom-Json -AsHashtable
if (-not $glyphs) { throw 'fail to parse glyphs' }

# tool functions

function toGlyph([string] $nfclass) {
    <#
        .EXAMPLE
        > toGlyph nf-cod-bug
        
    #>
    if ($nfclass -isnot [string] ) { throw "input is not string" }
    if (-not $glyphs.ContainsKey($nfclass)) { throw "$nfclass not in glyphs" }
    return [char]::ConvertFromUtf32([System.Convert]::ToInt32($glyphs[$nfclass], 16))
}
function toAnsiTextRGBColor([string]$hex) {
    <#
        .EXAMPLE
        > toAnsiTextRGBColor 00ff00
        \u001b[38;2;0;255;0m
    #>
    if ($hex.Length -ne 6) { throw "$hex has wrong length $($hex.Length)" }
    $t = 0, 2, 4 | ForEach-Object { ';'; [System.Convert]::ToInt32($hex.Substring($_, 2), 16) }
    return -join ((, "`e[38;2") + $t + 'm')
}
function saveTheme([string]$themeName) {    
    $theme = [ordered]@{
        palette               = $palette
        folder_default        = $folder_default
        folder_fullname       = $folder_fullname
        file_default          = $file_default
        file_fullname         = $file_fullname
        file_double_extension = $file_double_extension
        file_extension        = $file_extension
    }
    ConvertTo-Json $theme -Compress -Depth 99 -EscapeHandling EscapeNonAscii | Set-Content ".\Swift-Powershell-File-Icon\$themeName.theme.json"
}

# build seti theme

$folder_fullname = [ordered]@{
    'development'      = 'nf-cod-code'
    'src'              = 'nf-cod-code'
    'lib'              = 'nf-cod-library'
    'templates'        = 'nf-cod-notebook_template'
    'artifacts'        = 'nf-cod-package'
    'debug'            = 'nf-cod-package'
    'output'           = 'nf-cod-package'
    'release'          = 'nf-cod-package'
    'demo'             = 'nf-cod-preview'
    'demos'            = 'nf-cod-preview'
    'samples'          = 'nf-cod-preview'
    'projects'         = 'nf-cod-project'
    '.config'          = 'nf-custom-folder_config'
    '.vscode'          = 'nf-custom-folder_config'
    '.vscode-insiders' = 'nf-custom-folder_config'
    '.git'             = 'nf-custom-folder_git'
    '.github'          = 'nf-custom-folder_github'
    'github'           = 'nf-custom-folder_github'
    'node_modules'     = 'nf-custom-folder_npm'
    '.aws'             = 'nf-dev-aws'
    'bin'              = 'nf-dev-bintray'
    '.devcontainer'    = 'nf-dev-docker'
    '.docker'          = 'nf-dev-docker'
    'docker'           = 'nf-dev-docker'
    'fonts'            = 'nf-fa-font'
    'applications'     = 'nf-md-apps'
    'apps'             = 'nf-md-apps'
    '.cache'           = 'nf-md-cached'
    'contacts'         = 'nf-md-contacts'
    'desktop'          = 'nf-md-desktop_mac'
    'docs'             = 'nf-md-file_document_multiple'
    'documents'        = 'nf-md-file_document_multiple'
    'downloads'        = 'nf-md-folder_download'
    'images'           = 'nf-md-folder_image'
    'photos'           = 'nf-md-folder_image'
    'pictures'         = 'nf-md-folder_image'
    'music'            = 'nf-md-folder_music'
    'songs'            = 'nf-md-folder_music'
    'searches'         = 'nf-md-folder_search'
    'favorites'        = 'nf-md-folder_star'
    '.kube'            = 'nf-md-kubernetes'
    '.azure'           = 'nf-md-microsoft_azure'
    'onedrive'         = 'nf-md-microsoft_onedrive'
    'windows'          = 'nf-md-microsoft_windows'
    'media'            = 'nf-md-movie_open_play'
    'movies'           = 'nf-md-movie_open_play'
    'videos'           = 'nf-md-movie_open_play'
    'script'           = 'nf-md-script_text_play'
    'scripts'          = 'nf-md-script_text_play'
    'test'             = 'nf-md-test_tube'
    'tests'            = 'nf-md-test_tube'
    'benchmark'        = 'nf-md-timer'
    'tools'            = 'nf-md-tools'
}
$palette = @('', "`e[0m", "`e[44m")
$used_color = @('empty', 'reset', 'folder-default')
foreach ($k in [System.Object[]]$folder_fullname.Keys) {
    $folder_fullname[$k] = (toGlyph $folder_fullname[$k]), 2, 0, 1
}
$folder_default = (toGlyph 'nf-seti-folder') , 2, 0, 1
$seti_mapping = Import-PowerShellDataFile .\seti-mapping.psd1
$seti_mapping['.ps1xml'] = 'nf-seti-xml', 'blue'
$seti_ui = Import-PowerShellDataFile .\seti-ui.psd1
$file_default = (toGlyph 'nf-seti-default'), 0, 0, 0
$file_fullname = [ordered]@{}
$file_double_extension = [ordered]@{}
$file_extension = [ordered]@{}
foreach ($k in $seti_mapping.Keys) {
    $color = $seti_mapping[$k][1]
    if (($i = $used_color.IndexOf($color)) -lt 0) {
        $i = $used_color.Length
        $used_color += $color
        $palette += (toAnsiTextRGBColor $seti_ui[$color])
    }
    $v = (toGlyph $seti_mapping[$k][0]), $i, 0, 1
    if ($k[0] -eq '.') {
        $k = $k.Substring(1).Split('.')
        if ($k.Count -eq 1) {
            $file_extension[$k[0]] = $v
        }
        else {
            if ($k.Count -gt 2) { 
                throw
            }
            if (-not $file_double_extension[$k[1]]) { 
                $file_double_extension[$k[1]] = [ordered]@{} 
            }
            $file_double_extension[$k[1]][$k[0]] = $v
        }
    }
    else { $file_fullname[$k] = $v }
}
saveTheme seti