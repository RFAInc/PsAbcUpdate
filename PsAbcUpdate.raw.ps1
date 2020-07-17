# Load other modules
$web = New-Object Net.WebClient
$Functions = @(
    'Get-AbcUpdateLog'
    'Import-AbcUpdateLog'
)
Foreach ($f in $Functions) {
    $uri = "https://raw.githubusercontent.com/RFAInc/PsAbcUpdate/master/$($f).ps1"
    $web.DownloadString($uri) | Invoke-Expression
}
$web.Dispose | Out-Null

