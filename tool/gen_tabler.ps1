$src = "C:\Users\PC\AppData\Local\Pub\Cache\hosted\pub.dev\tabler_icons_plus-3.47.0\lib\tabler_icons_plus.dart"
$out = "C:\Users\PC\Desktop\App\step_reminder\lib\util\tabler_catalog.dart"

$text = Get-Content $src -Raw
$pattern = 'static const IconData (\w+) = IconData\(\s*(0x[0-9a-fA-F]+),\s*fontFamily: (_kFontFam|_kFontFamFilled),'
$matches = [regex]::Matches($text, $pattern)
Write-Output ("matched: " + $matches.Count)

function Convert-Name([string]$camel) {
  # camelCase -> snake_case, and split a digit run off the word before it
  # so clockHour3 reads as clock_hour_3 rather than clock_hour3.
  # Split a run of capitals before the next word first, so aBOff becomes
  # a_b_off rather than a_boff.
  $s = [regex]::Replace($camel, '([A-Z]+)([A-Z][a-z])', '$1_$2')
  $s = [regex]::Replace($s, '([a-z0-9])([A-Z])', '$1_$2')
  $s = [regex]::Replace($s, '([A-Za-z])(\d)', '$1_$2')
  return $s.ToLowerInvariant()
}

$outline = [System.Collections.Generic.SortedDictionary[string, string]]::new()
$filled = [System.Collections.Generic.SortedDictionary[string, string]]::new()

foreach ($m in $matches) {
  $name = Convert-Name $m.Groups[1].Value
  $code = $m.Groups[2].Value
  if ($m.Groups[3].Value -eq '_kFontFamFilled') {
    if (-not $filled.ContainsKey($name)) { $filled[$name] = $code }
  } else {
    if (-not $outline.ContainsKey($name)) { $outline[$name] = $code }
  }
}

Write-Output ("outline: " + $outline.Count + "  filled: " + $filled.Count)

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("// GENERATED from tabler_icons_plus 3.47.0 by tool/gen_tabler.ps1.")
[void]$sb.AppendLine("// Do not edit by hand.")
[void]$sb.AppendLine("//")
[void]$sb.AppendLine("// The package exposes camelCase constants only, with no way to look an")
[void]$sb.AppendLine("// icon up by name. The picker searches by name, so the codepoints are")
[void]$sb.AppendLine("// lifted out here as snake_case to match how Material Symbols are named.")
[void]$sb.AppendLine("library;")
[void]$sb.AppendLine()
[void]$sb.AppendLine("const tablerFontPackage = 'tabler_icons_plus';")
[void]$sb.AppendLine("const tablerOutlineFamily = 'tabler-icons';")
[void]$sb.AppendLine("const tablerFilledFamily = 'tabler-icons-filled';")
[void]$sb.AppendLine()
[void]$sb.AppendLine("const tablerOutline = <String, int>{")
foreach ($k in $outline.Keys) { [void]$sb.AppendLine("  '$k': $($outline[$k]),") }
[void]$sb.AppendLine("};")
[void]$sb.AppendLine()
[void]$sb.AppendLine("const tablerFilled = <String, int>{")
foreach ($k in $filled.Keys) { [void]$sb.AppendLine("  '$k': $($filled[$k]),") }
[void]$sb.AppendLine("};")

Set-Content -Path $out -Value $sb.ToString() -Encoding utf8
Write-Output ("wrote: " + $out)
Write-Output "==== sample ===="
Get-Content $out | Select-Object -Skip 12 -First 6
