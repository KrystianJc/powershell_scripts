function Get-SteamLibrary {
    param(
        [string]$SteamId
    )

    $url = "https://api.steampowered.com/IPlayerService/GetOwnedGames/v1/" +
       "?key=$apiKey&steamid=$SteamId&include_appinfo=true&include_played_free_games=true&format=json"

    $games = (Invoke-RestMethod $url).response.games

    if (-not $games) {
        throw "No games for $SteamId - private profile or wrong ID."
    }

    return $games
}

function Invoke-Comparison {

    if (-not $apiKey -or -not $yourId -or -not $friendId) {
        Write-Host "Fill in API key and both SteamIDs first (options 2-4)." -ForegroundColor Yellow
        return
    }

    $yourGames   = Get-SteamLibrary -SteamId $yourId
    $friendGames = Get-SteamLibrary -SteamId $friendId

    $sharedGames = Compare-Object $yourGames $friendGames -Property appid -IncludeEqual -ExcludeDifferent -PassThru

    $summaryUrl = "https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2/?key=$apiKey&steamids=$yourId,$friendId"
    $players = (Invoke-RestMethod $summaryUrl).response.players
    $yourNick   = ($players | Where-Object steamid -eq $yourId).personaname
    $friendNick = ($players | Where-Object steamid -eq $friendId).personaname

    $friendLookup = @{}
    foreach ($game in $friendGames) {
        $friendLookup[$game.appid] = $game
    }

    $comparison = foreach ($game in $sharedGames) {
        $friendGame = $friendLookup[$game.appid]

        $row = [ordered]@{}
        $row['Game Name'] = $game.name
        $row[$yourNick] = "$([math]::Round($game.playtime_forever / 60, 1))h"
        $row[$friendNick] = "$([math]::Round($friendGame.playtime_forever / 60, 1))h"

        [PSCustomObject]$row
    }

    $comparison |
        Sort-Object 'Game Name' |
        Format-Table -AutoSize

    Read-Host "Press Enter to return to menu"
}

function Set-YourSteamId {
    $newId = Read-Host "Enter your new SteamID64"

    if (-not $newId) {
        Write-Host "Nothing entered, keeping the old value." -ForegroundColor Yellow
        return
    }

    $config.yourSteamId = $newId
    $script:yourId = $newId
    $config | ConvertTo-Json | Set-Content $configPath -Encoding utf8

    Write-Host "Saved. Your SteamID is now $newId" -ForegroundColor Green
}
function Set-FriendSteamId {
    $newId = Read-Host "Enter your friend's new SteamID64"

    if (-not $newId) {
        Write-Host "Nothing entered, keeping the old value." -ForegroundColor Yellow
        return
    }

    $config.friendSteamId = $newId
    $script:friendId = $newId
    $config | ConvertTo-Json | Set-Content $configPath -Encoding utf8

    Write-Host "Saved. Friend's SteamID is now $newId" -ForegroundColor Green
}
function Set-ApiKey {
    $newKey = Read-Host "Enter your new Steam API key"

    if (-not $newKey) {
        Write-Host "Nothing entered, keeping the old value." -ForegroundColor Yellow
        return
    }

    $config.steamApiKey = $newKey
    $script:apiKey = $newKey
    $config | ConvertTo-Json | Set-Content $configPath -Encoding utf8

    Write-Host "Saved. API key updated." -ForegroundColor Green
}

$configPath = Join-Path $PSScriptRoot 'config.json'

if (-not (Test-Path $configPath)) {
    throw "Missing config.json - copy config.example.json, rename it and fill in your data."
}

$config = Get-Content $configPath -Raw | ConvertFrom-Json
$apiKey = $config.steamApiKey
$yourId = $config.yourSteamId
$friendId = $config.friendSteamId



$running = $true

while ($running) {
    Write-Host ""
    Write-Host "=== Steam Library Compare ===" -ForegroundColor Cyan
    Write-Host "1. Run comparison"
    Write-Host "2. Change your SteamID"
    Write-Host "3. Change friend's SteamID"
    Write-Host "4. Change API key"
    Write-Host "5. Exit"
    Write-Host ""

    $choice = Read-Host "Choose an option"

    switch ($choice) {
        '1' {
    try {
        Invoke-Comparison
    }
    catch {
        Write-Host "Comparison failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}
        '2' { Set-YourSteamId }
        '3' { Set-FriendSteamId }
        '4' { Set-ApiKey }
        '5' { $running = $false }
        default { Write-Host "Invalid option, try again" -ForegroundColor Red }
    }
}

