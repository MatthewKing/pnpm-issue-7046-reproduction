# pnpm issue reproduction

I'm having an [issue](https://github.com/pnpm/pnpm/issues/7046) with [pnpm](https://pnpm.io/) on Windows 11 where some files in `node_modules` are not being hardlinked back to their location in the pnpm store.

This repository exists as a very simple reproduction of the issue.

Here is a link to the issue itself: https://github.com/pnpm/pnpm/issues/7046

## Steps to reproduce:

(Note, if you don't want to manually follow these steps, you can just run `reproduce.ps1`)

First, run `pnpm install` on this repository.

Next, search for non-hardlinked files inside `node_modules`:

```powershell
# Return the top 5 non-hardlinked files within node_modules
Get-ChildItem -Path node_modules -File -Recurse | Where-Object { $_.LinkType -ne 'HardLink' } | Sort-Object -Property Length -Descending | Select-Object Name, LinkType, Length -First 5
```

Output:

```
Name                         LinkType    Length
----                         --------    ------
next-swc.win32-x64-msvc.node          115914752
lock.yaml                                  8555
.modules.yaml                              2425
next.ps1                                   2177
next.ps1                                   2169
```

Ok, so we can see that there are a bunch of non-hardlinked files in `node_modules`. Is this expected? No idea. Having a 110mb file not being hardlinked doesn't seem right to me, though?

Next, let's confirm that the above file is definitely not hardlinked, using [fsutil](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/fsutil):

```powershell
# Confirm that next-swc.win32-x64-msvc.node is not hardlinked
# A single result means the file only exists in one place, whereas multiple results mean it is hardlinked in multiple locations. We "expect" this to have multiple results since it should exist in the pnpm store AND in this repo, but the reproduction I am getting yields only a single result.
fsutil hardlink list node_modules\.pnpm\@next+swc-win32-x64-msvc@13.4.19\node_modules\@next\swc-win32-x64-msvc\next-swc.win32-x64-msvc.node
```

Output:
```
node_modules\.pnpm\@next+swc-win32-x64-msvc@13.4.19\node_modules\@next\swc-win32-x64-msvc\next-swc.win32-x64-msvc.node
```

OK, so at this point we can see that this file is NOT hardlinked. Just out of interest, we can also check if it exists in the pnpm store, and check if that file has any hardlinks:

```powershell
# Hash the file and find the match in the pnpm store. Check any hardlinks on the store file.
# As above, a single result means the file only exists in one place, whereas multiple results mean it is hardlinked in multiple locations. We "expect" this to have multiple results since it should also exist in the repository, but the reproduction I am getting yields only a single result.
$storePath = pnpm store path
$hash = Get-FileHash -Path node_modules\.pnpm\@next+swc-win32-x64-msvc@13.4.19\node_modules\@next\swc-win32-x64-msvc\next-swc.win32-x64-msvc.node -Algorithm SHA512
$storeFileName = ($hash.Hash).ToLower().Substring(2, 126)
$storeFile = Get-ChildItem -File -Path $storePath -Include $storeFileName -Recurse | Select-Object FullName -First 1
fsutil hardlink list $storeFile.FullName
```

Output:

```
\.pnpm-store\v3\files\5b\bcca87cf909f13a268702a5d1f2bde3f8517f4ba0f1fbd83ee10fe720d25381c91968bd599b74007382f72caea98fba9d42622cab10cf17bca52bd81e64151
```

