Param
(
	[string]$hostname,
	[string]$username,
	[string]$password,
	[string]$src
)

$pw = convertto-securestring -AsPlainText -Force -String $password
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username,$pw
$option = new-pssessionoption -SkipRevocationCheck -SkipCACheck
$session = new-pssession -connectionuri "https://$hostname" -credential $cred -sessionoption $option

$dstPath = "C:\Users\$username\rundeck-file-copier\"
$dst = $dstPath + [guid]::NewGuid() + [System.IO.Path]::GetExtension($src)
$dst = $dst.Replace(".bat", ".ps1")

Write-Host $dst

$sourceBytes = [System.IO.File]::ReadAllBytes($src);
$streamChunks = @();

$streamSize = 1MB;
for ($position = 0; $position -lt $sourceBytes.Length; $position += $streamSize)
{
	$remaining = $sourceBytes.Length - $position
	$remaining = [Math]::Min($remaining, $streamSize)
	
	$nextChunk = New-Object byte[] $remaining
	[Array]::Copy($sourcebytes, $position, $nextChunk, 0, $remaining)
	$streamChunks +=, $nextChunk
}
$remoteScript = {
	if (-not (Test-Path -Path $using:dstPath -PathType Container))
	{
		$null = New-Item -Path $using:dstPath -Type Directory -Force
	}
	$destBytes = New-Object byte[] $using:length
	$position = 0
	
	foreach ($chunk in $input)
	{
		[GC]::Collect()
		[Array]::Copy($chunk, 0, $destBytes, $position, $chunk.Length)
		$position += $chunk.Length
	}
	
	[IO.File]::WriteAllBytes($using:dst, $destBytes)
	[GC]::Collect()
}

$Length = $sourceBytes.Length
$streamChunks | Invoke-Command -Session $session -ScriptBlock $remoteScript

Remove-PSSession -Session $session