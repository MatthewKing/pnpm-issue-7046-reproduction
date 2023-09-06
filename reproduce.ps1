Write-Host "First, ensure pnpm has installed the packages:"
pnpm install

Write-Host
Write-Host

Write-Host "Here is the largest non-hardlinked file within node_modules:"
Write-Host "(It should be next-swc.win32-x64-msvc.node)"
Write-Host
$topNonHardLinkedFile = Get-ChildItem -Path "$PSScriptRoot\node_modules" -File -Recurse | Where-Object { $_.LinkType -ne 'HardLink' } | Sort-Object -Property Length -Descending | Select-Object FullName, LinkType, Length -First 1
Write-Host $topNonHardLinkedFile

Write-Host
Write-Host

Write-Host "Let's confirm with fsutil that it is indeed not hardlinked:"
Write-Host "(If things are working as expected, we should have multiple results here, but my reproduction only yields a single result)"
Write-Host
fsutil hardlink list $topNonHardLinkedFile.FullName

Write-Host
Write-Host

Write-Host "Finally, let's see if we can find this file in the pnpm store, and check for hardlinks on that:"
Write-Host ("Again, we'd expect multiple results, but my reproduction only yields a single result")
Write-Host
$storePath = pnpm store path
$hash = Get-FileHash -Path $topNonHardLinkedFile.FullName -Algorithm SHA512
$storeFileName = ($hash.Hash).ToLower().Substring(2, 126)
$storeFile = Get-ChildItem -File -Path $storePath -Include $storeFileName -Recurse | Select-Object FullName -First 1
fsutil hardlink list $storeFile.FullName
