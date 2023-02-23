Write-Host "


	@@@@@@@    @@@@@@    @@@@@@    @@@@@@   @@@  @@@  @@@  @@@@@@@@  @@@@@@@   @@@  @@@   @@@@@@   
	@@@@@@@@  @@@@@@@@  @@@@@@@   @@@@@@@   @@@  @@@  @@@  @@@@@@@@  @@@@@@@@  @@@@ @@@  @@@@@@@   
	@@!  @@@  @@!  @@@  !@@       !@@       @@!  @@!  @@@  @@!       @@!  @@@  @@!@!@@@  !@@       
	!@!  @!@  !@!  @!@  !@!       !@!       !@!  !@!  @!@  !@!       !@!  @!@  !@!!@!@!  !@!       
	@!@@!@!   @!@!@!@!  !!@@!!    !!@@!!    !!@  @!@  !@!  @!!!:!    @!@  !@!  @!@ !!@!  !!@@!!    
	!!@!!!    !!!@!!!!   !!@!!!    !!@!!!   !!!  !@!  !!!  !!!!!:    !@!  !!!  !@!  !!!   !!@!!!   
	!!:       !!:  !!!       !:!       !:!  !!:  :!:  !!:  !!:       !!:  !!!  !!:  !!!       !:!  
	:!:       :!:  !:!      !:!       !:!   :!:   ::!!:!   :!:       :!:  !:!  :!:  !:!      !:!   
	 ::       ::   :::  :::: ::   :::: ::    ::    ::::     :: ::::   :::: ::   ::   ::  :::: ::   
	 :         :   : :  :: : :    :: : :    :       :      : :: ::   :: :  :   ::    :   :: : :    

			|    GitHub: https://github.com/FAlhumaid
			|   Twitter: https://twitter.com/FS_Alhumaid
			|  LinkedIn: https://www.linkedin.com/in/FAlhumaid
" -ForegroundColor Cyan

function Typing-Effect {
    param (
        [string]$Text,
		[ConsoleColor]$Color = "White",
        [int]$Delay = 10
    )
    for ($i = 0; $i -lt $Text.Length; $i++) {
        Write-Host -NoNewline -ForegroundColor $Color $Text[$i]
        Start-Sleep -Milliseconds $Delay
    }
	Write-Host ""
}

Typing-Effect "[----------------------------------------------[Options]----------------------------------------------]" -Color Cyan

while (-not $validPath) {
    Typing-Effect "
[-] Enter the path for a file contains either IP Addresses or Domains (i.e: list.txt)" -Color Yellow
    $InputFile = Read-Host
    if ([string]::IsNullOrWhiteSpace($InputFile)) {
        Typing-Effect "[!] Your input cannot be empty. Please enter a valid file path." -Color Red
        continue
    }
    if (-not (Test-Path -LiteralPath $InputFile)) {
        Typing-Effect "[!] No such file has been found. Please enter a valid file path." -Color Red
        continue
    }
    if ((Get-Item $InputFile).PSIsContainer) {
        Typing-Effect "[!] Your input cannot be a directory or space. Please enter a valid file path." -Color Red
        continue
    }
    if (([System.IO.Path]::GetExtension($InputFile)) -ne ".txt") {
        Typing-Effect "[!] Only .txt files are accepted. Please enter a valid file path." -Color Red
        continue
    }
    $Inputs = Get-Content $InputFile
    if ([string]::IsNullOrWhiteSpace($Inputs)) {
        Typing-Effect "[!] Your file is empty. Please enter a file that has content." -Color Red
        continue
    }
    $validPath = $true
}

$hostnameRegex = "^(([a-zA-Z]{1})|([a-zA-Z]{1}[a-zA-Z]{1})|([a-zA-Z]{1}[0-9]{1})|([0-9]{1}[a-zA-Z]{1})|([a-zA-Z0-9][a-zA-Z0-9-_]{1,61}[a-zA-Z0-9]))\.([a-zA-Z]{2,6}|[a-zA-Z0-9-]{2,30}\.[a-zA-Z]{2,3})$"
$ipRegex = "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"
$invalidLines = @()

foreach ($input in $Inputs) {
    if (-not ($input -match $hostnameRegex) -and -not ($input -match $ipRegex)) {
        $invalidLines += $input
    }
}

if ($invalidLines.Count -gt 0) {
    Typing-Effect "[!] The following lines do not match the expected format:
" -Color Red
    foreach ($line in $invalidLines) {
        Typing-Effect "[!] $line" -Color Red
    }
    Typing-Effect "
[!] Please ensure that each line is either a domain name or IP address." -Color Red
	Typing-Effect "[-] Press Enter to close this script..." -Color Yellow
	Read-Host
	Exit
}

$SingleFile = ""

while($SingleFile -ne "y" -and $SingleFile -ne "n")
{
    Typing-Effect "
[-] Do you prefer all the results in one file? [Y/N]" -Color Yellow 
    $SingleFile = Read-Host
    if($SingleFile -ne "y" -and $SingleFile -ne "n")
    {
        Typing-Effect "
[!] Please enter either Y or N" -Color Red
    }
}

Typing-Effect "
[----------------------------------------------[Progress]---------------------------------------------]
" -Color Cyan

$AllDnsRecords = @()

foreach ($Query in $Inputs) {
	Start-Sleep -Seconds 1
    $DnsRecords = @()
    $Parameters = "?limit=0"
    $Response = Invoke-RestMethod -Uri "https://api.mnemonic.no/pdns/v3/$Query$Parameters" -Method Get
	Typing-Effect "[-] A request has been sent to check the PassiveDNS database for $Query." -Color Yellow
    $Counter = 0
    foreach($Data in $Response.data) {
        $Counter++
        $DnsRecords += [PSCustomObject]@{
            "No." = $Counter
            "Input:" = $Query
            "Query:" = $Data.query
            "Type:" = $Data.rrtype
            "Response:" = $Data.answer
            "Times Shown:" = $Data.times
            "First Seen (UTC):" = ([datetime]'1970-01-01').AddMilliseconds($Data.firstSeenTimestamp).ToString("yyyy-MM-dd HH:mm:ss")
            "Last Seen (UTC):" = ([datetime]'1970-01-01').AddMilliseconds($Data.lastSeenTimestamp).ToString("yyyy-MM-dd HH:mm:ss")
            "Minimum TTL:" = $Data.minTtl
            "Maximum TTL:" = $Data.maxTtl
        }
    }
	Start-Sleep -Seconds 6
	if($Counter -gt "0") {
		$AllDnsRecords += $DnsRecords
		Typing-Effect "[+] The response for $Query has been received with $Counter findings.
" -Color Green
	}
	else {
		Typing-Effect "[!] The response for $Query has been received, but no findings were found.
" -Color Red
	}
}

Typing-Effect "[----------------------------------------------[Results]----------------------------------------------]
" -Color Cyan

$SavePath = $PSScriptRoot

If ($SingleFile -eq "y") {
	$FullDateTime = Get-Date -Format "yyyy-MM-dd HH_mm_ss"
	$CsvFileName = "Results_($FullDateTime).csv"
	$CsvFilePath = Join-Path -Path $SavePath -ChildPath $CsvFileName
    $AllDnsRecords | Export-Csv $CsvFilePath -NoTypeInformation
		Typing-Effect "[-] New file created for all the results:" -Color Yellow
		Typing-Effect "$CsvFilePath
" -Color Green
} elseif($SingleFile -eq "n") {
    foreach ($Query in $Inputs) {
			$DateTime = Get-Date -Format "yyyy-MM-dd HH_mm_ss"
			$DnsRecords = $AllDnsRecords | Where-Object {$_. "Input:" -eq $Query}
		if ($DnsRecords.Count -gt 0) {
			$CsvFileName = "($Query)_($DateTime).csv"
			$CsvFilePath = Join-Path -Path $SavePath -ChildPath $CsvFileName
			$DnsRecords | Export-Csv $CsvFilePath -NoTypeInformation
			Typing-Effect "[-] New file created for ($Query):" -Color Yellow
			Typing-Effect "$CsvFilePath
" -Color Green
		}
		else {
			Typing-Effect "[-] No file created for ($Query) due to have 0 findings.
" -Color Red
		}
    }
}

Typing-Effect "[-----------------------------------------------[Exit]------------------------------------------------]
" -Color Cyan

Typing-Effect "[-] Press Enter to close this script..." -Color Yellow
Read-Host