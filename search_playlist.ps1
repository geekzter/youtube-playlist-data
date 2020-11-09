#!/usr/bin/env pwsh
<# 
.SYNOPSIS 
    Searches downloaded playlist data
.EXAMPLE
    ./search_playlist.ps1 textimlookingfor
.EXAMPLE
    ./search_playlist.ps1 -CsvFile ./data/myplaylist-20201108155030.csv -Year 1989
#> 
#Requires -Version 5

### Arguments
[CmdletBinding(DefaultParameterSetName="Text")]
param ( 
    [parameter(Mandatory=$false,ParameterSetName="Text",Position=0)][string]$Text,
    [parameter(Mandatory=$false,ParameterSetName="Attribute")][string]$Artist,
    [parameter(Mandatory=$false,ParameterSetName="Attribute")][string]$Title,
    [parameter(Mandatory=$false,ParameterSetName="Attribute")][string]$Version,
    [parameter(Mandatory=$false)][int]$Year,
    [parameter(Mandatory=$false)][string]$CsvFile
) 

Write-Information $MyInvocation.line
$scriptDirectory = (Split-Path -parent -Path $MyInvocation.MyCommand.Path)
$dataDirectory = (Join-Path $scriptDirectory "data") 

if ($CsvFile) {
    if (Test-Path $CsvFile) {
        $dataFile = Get-Item $CsvFile
    } else {
        Write-Warning "$CsvFile not found"
        exit
    }
} else {
    # Find latest playlist data to be downloaded
    $dataFile = Get-ChildItem -Filter *.csv -Path $dataDirectory | Sort-Object CreationTime -Descending | Select-Object -First 1
    if (!$dataFile) {
        Write-Warning "No CSV file found in $dataDirectory. Please run get_playlist_data.ps1 first"
        exit
    }
}
$dataFileName = Join-Path $dataDirectory $dataFile.Name
# Load data
$data = Import-Csv $dataFileName

if ($Text) {
    $data = ($data | Where-Object {$_.Title -imatch $Text -or $_.description -imatch $Text})
}
if ($Artist) {
    $data = ($data | Where-Object parsed_artist -imatch $Artist)
}
if ($Title) {
    $data = ($data | Where-Object parsed_title -imatch $Title)
}
if ($Version) {
    $data = ($data | Where-Object parsed_version -imatch $Version)
}
if ($Year) {
    $data = ($data | Where-Object parsed_year -match $Year)
}

if ($data.Count -le 1) {
    $data | Format-List
} else {
    $data | Format-Table
}
