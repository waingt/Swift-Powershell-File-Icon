# Get-FormatData System.IO.FileInfo, System.IO.DirectoryInfo | Export-FormatData -Path $moduleRoot\FileSystem.Format.ps1xml -IncludeScriptBlock
# $t = Get-Content $moduleRoot\FileSystem.Format.ps1xml -Raw
# $t = $t.Replace('<PropertyName>Name</PropertyName>', '<ScriptBlock>Format-FileName $_</ScriptBlock>')
# $t = $t.Replace('<PropertyName>NameString</PropertyName>', '<ScriptBlock>Format-FileName $_ -WithLinkTarget</ScriptBlock>')
# Set-Content -Path $moduleRoot\FileSystem.Format.ps1xml -Value $t
class AccessTool {
    $Value
    static [AccessTool] Wrap($value) {
        if ($value) { return [AccessTool]@{Value = $value } }
        return $null
    }
    [AccessTool] Field($name) {
        return [AccessTool]::Wrap($this.Value.GetType().GetField($name, 60).GetValue($this.Value))
    }
    [void] SetField($name, $value) {
        $this.Value.GetType().GetField($name, 60).SetValue($this.Value, $value)
    }
    [AccessTool] Property($name) {
        return [AccessTool]::Wrap($this.Value.GetType().GetProperty($name, 60).GetValue($this.Value))
    }
    [AccessTool[]] AsArray() {
        if ($this.Value -isnot [System.Collections.IEnumerable]) { throw }
        return $this.Value | ForEach-Object { [AccessTool]@{Value = $_ } }
    }
}

$viewDefinitionList = [AccessTool]::Wrap($ExecutionContext).Field('_context').Property('FormatDBManager').Property('Database').Field('viewDefinitionsSection').Field('viewDefinitionList').AsArray()
$controls = $viewDefinitionList | Where-Object { $_.Field('name').Value -eq 'children' } | ForEach-Object { $_.Field('mainControl') }
$row = $controls.Field('defaultDefinition').Field('rowItemDefinitionList').AsArray()
$row.Field('formatTokenList').AsArray().Field('expression').Field('expressionValue')