
#*****************************************************************
#
#   Script Name:  TDMAPIExample.ps1
#   Version:  1.0
#   Author:  Keith Puzey 
#   Date:  January 08,  2019
#
#   Description:  Example Powershell script to interact with CA TDM API
#   
#
#*****************************************************************

#  Example -   powershell -file TDMAPIExample.ps1 -username administrator -password marmite -url http://10.130.127.71:8080 -ProjectName "Web Store Application" -Version 22 -Environment QA

param(
   [string]$username,
   [string]$url,
   [string]$ProjectName,
   [string]$Version,
   [string]$Environment,
   [string]$password
  )
  
 $authurl="${url}/TestDataManager/user/login"
 $projecturl="${url}/TDMProjectService/api/ca/v1/projects"
 
# Convert username and password (username:password) to Base64
  
 $stringtoencode="${username}:${password}"
 $EncodedText = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("$stringtoencode"))
 $Auth="Basic ${EncodedText}"

# TDM Version Project

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization",$Auth)
$headers.Add("ContentType",'application/json')
 
 try {
    $response=Invoke-RestMethod -Method 'Post' -Uri $authurl -Headers $headers
}
catch [System.Net.WebException] { 
    Write-Verbose "An exception was caught: $($_.Exception.Message)"
    $_.Exception.Response 
} 
$tokenorig = $response.token

$token="Bearer ${tokenorig}"

# TDM Project Response
 
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization",$token)
$headers.Add("ContentType",'application/json')
 
 try {
    $projectresponse=Invoke-RestMethod -Method 'Get' -Uri $projecturl -Headers $headers
}
catch [System.Net.WebException] { 
    Write-Verbose "An exception was caught: $($_.Exception.Message)"
    $_.Exception.Response 
} 

$projectID=($projectresponse | where {$_.name -eq $ProjectName})
$ProjectID=$projectID.id


# TDM Version Project

$versionurl="${url}/TDMProjectService/api/ca/v1/projects/$projectID/versions"


$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization",$token)
$headers.Add("ContentType",'application/json')
 
 try {
    $versionresponse=Invoke-RestMethod -Method 'Get' -Uri $versionurl -Headers $headers
}
catch [System.Net.WebException] { 
    Write-Verbose "An exception was caught: $($_.Exception.Message)"
    $_.Exception.Response 
} 

$versionID=($versionresponse | where {$_.name -eq $Version})
$VersionID=$versionID.id


# TDM Environment Response

$environmenturl="${url}/TDMDataReservationService/api/ca/v1/environments"


$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization",$token)
$headers.Add("ContentType",'application/json')

$EnvBody = @{"projectId"="$ProjectID";
 "versionId"="$VersionID";
 }
 
 try {
    $environmentresponse=Invoke-RestMethod -Method 'Get' -Uri $environmenturl -Headers $headers -Body $EnvBody
}
catch [System.Net.WebException] { 
    Write-Verbose "An exception was caught: $($_.Exception.Message)"
    $_.Exception.Response 
} 

$environmentid=($environmentresponse.elements | where {$_.name -eq $Environment})
$environmentID=$environmentid.id


# TDM Environment Details


$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization",$token)
$headers.Add("ContentType",'application/json')

$EnvBody = @{"projectId"="$ProjectID";
 "versionId"="$VersionID";
}
$environmentdetailurl="${url}/TDMDataReservationService/api/ca/v1/environments/$environmentID" 
 try {
    $environmentdetailresponse=Invoke-RestMethod -Method 'Get' -Uri $environmentdetailurl -Headers $headers -Body $EnvBody
}
catch [System.Net.WebException] { 
    Write-Verbose "An exception was caught: $($_.Exception.Message)"
    $_.Exception.Response 
} 


"`n""`n"
write-host Project Table
write-output $projectresponse | Sort-Object -Property name| Format-Table 
write-host Version Table for project ${ProjectName}
write-output  $versionresponse | Sort-Object -Property name| Format-Table 
write-host Environment Table ${ProjectName} / Version  $Version
write-output $environmentresponse.elements | Sort-Object -Property name| Format-Table 

Write-Host -NoNewline "Project ID for Project name  ${ProjectName} is" $ProjectID
"`n"
Write-Host -NoNewline "Version ID for Version ${Version} is" $VersionID
"`n"
Write-Host -NoNewline "Environment ID for Environment ${Environment} is" $environmentID
"`n"