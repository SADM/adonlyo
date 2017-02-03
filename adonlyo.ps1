Import-Module ActiveDirectory
Get-Content ".\settings.txt" | foreach-object -begin {$h=@{}} -process { $k = [regex]::split($_,'='); if(($k[0].CompareTo("") -ne 0) -and ($k[0].StartsWith("[") -ne $True)) { $h.Add($k[0], $k[1]) } }
$portal=$h.portal.ToString()
$query = (Get-ADUser -filter {Enabled -eq "True"} -properties Mail, GivenName, Title, TelephoneNumber, Mobile)
$authParams = @{userName=$h.userName;password=$h.password}
$JSON = $authParams | Convertto-JSON
$authResponse = Invoke-WebRequest –Uri $portal/api/2.0/authentication.json -Body $JSON –ContentType application/json –Method   Post | ConvertFrom-Json |Select-Object response
$token = $authResponse.response.token
foreach ($user in $query) {
    $postParams = @{isVisitor="false";email=$user.Mail;firstname=$user.GivenName;lastname=$user.Surname}
    if ($user.Title){$postParams.Add("title",$user.Title)}
    $postParams.Add("files", $h.avatar)
    $contacts=@(@{Type="mail";Value=$user.Mail})
    if ($user.TelephoneNumber) {$contacts += @(@{Type="phone";Value=$user.TelephoneNumber})}
    if ($user.Mobile) {$contacts += @(@{Type="mobphone";Value=$user.Mobile})}
    $postParams.Add("contacts", $contacts)
    $JSON = $postParams | Convertto-JSON
    $encBody = [System.Text.Encoding]::UTF8.GetBytes($JSON)
    Invoke-WebRequest –Uri $portal/api/2.0/people -Headers @{"Authorization"=$token} -Body $encBody –ContentType application/json –Method   Post
}