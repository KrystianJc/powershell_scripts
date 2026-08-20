$configPath = Join-Path $PSScriptRoot 'config.json'

if (-not (Test-Path $configPath)) {
    throw "Missing config.json - copy config.example.json, rename it and fill in your data."
}

$config  = Get-Content $configPath -Raw | ConvertFrom-Json
$apiKey  = $config.steamApiKey
$steamId = $config.steamId

$url = "https://api.steampowered.com/IPlayerService/GetOwnedGames/v1/" +
       "?key=$apiKey&steamid=$steamId&include_appinfo=true&format=json"

$games = (Invoke-RestMethod $url).response.games 

if (-not $games) {
    throw "No games returned. Check your API key, SteamID and profile privacy settings."
}


$unplayed = $games | Where-Object playtime_forever -eq 0

$unplayed |
    Sort-Object name |
    Select-Object name, appid |
    Format-Table -AutoSize

Write-Host "`nUntouched games: $($unplayed.Count) of $($games.Count)" -ForegroundColor Red


$results = foreach ($game in $unplayed){
    $appId = $game.appid
    $response = Invoke-RestMethod "https://store.steampowered.com/api/appdetails?appids=$appId&cc=pl&filters=price_overview"

    $entry     = $response."$appId"
    $priceInfo = $entry.data.price_overview

    if (-not $entry.success) {
        $status = 'Not in store'
        $price  = $null
    }
    elseif (-not $priceInfo) {
        $status = 'Free'
        $price  = 0
    }
    else {
        $status = 'OK'
        $price  = $priceInfo.final / 100
    }

    [PSCustomObject]@{
        Name     = $game.name
        AppId    = $game.appid
        Price    = $price
        Discount = $priceInfo.discount_percent
        Status   = $status
    }
}
$results | Format-Table -AutoSize