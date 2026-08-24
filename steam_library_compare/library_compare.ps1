$configPath = Join-Path $PSScriptRoot 'config.json'

if (-not (Test-Path $configPath)) {
    throw "Missing config.json - copy config.example.json, rename it and fill in your data."
}

$config = Get-Content $configPath -Raw | ConvertFrom-Json
$apiKey = $config.steamApiKey
$yourId = $config.yourSteamId
$friendId = $config.friendSteamId

function Get-SteamLibrary {
    param(
        [string]$SteamId
    )

    $url = "https://api.steampowered.com/IPlayerService/GetOwnedGames/v1/" +
           "?key=$apiKey&steamid=$SteamId&include_appinfo=true&format=json"

    $games = (Invoke-RestMethod $url).response.games

    if (-not $games) {
        throw "No games for $SteamId - private profile or wrong ID."
    }

    return $games
}

$yourGames   = Get-SteamLibrary -SteamId $yourId
$friendGames = Get-SteamLibrary -SteamId $friendId

$sharedGames = Compare-Object $yourGames $friendGames -Property appid -IncludeEqual -ExcludeDifferent -PassThru

$url = "https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2/?key=$apiKey&steamids=$yourId,$friendId"
$players = (Invoke-RestMethod $url).response.players
$yourNick   = ($players | Where-Object steamid -eq $yourId).personaname
$friendNick = ($players | Where-Object steamid -eq $friendId).personaname

$friendLookup = @{}

foreach ($game in $friendGames) {
    $friendLookup[$game.appid] = $game
}

$comparison = foreach ($game in $sharedGames) {
    $friendGame = $friendLookup[$game.appid]

    $row = [ordered]@{    
    }
    $row['Game Name'] = $game.name
    $row[$yourNick]   = [math]::Round($game.playtime_forever / 60, 1)
    $row[$friendNick] = [math]::Round($friendGame.playtime_forever / 60, 1)

    [PSCustomObject]$row
}

$comparison |
    Sort-Object 'Game Name' |
    Format-Table -AutoSize