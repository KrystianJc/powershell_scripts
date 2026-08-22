$configPath = Join-Path $PSScriptRoot 'config.json'

if (-not (Test-Path $configPath)) {
    throw "Missing config.json - copy config.example.json, rename it and fill in your data."
}

$config = Get-Content $configPath -Raw | ConvertFrom-Json
$apiKey = $config.steamApiKey
$steamId = $config.steamId
$countryCode = $config.countryCode

if (-not $countryCode) {
    $countryCode = [System.Globalization.RegionInfo]::CurrentRegion.TwoLetterISORegionName
}

$url = "https://api.steampowered.com/IPlayerService/GetOwnedGames/v1/" +
       "?key=$apiKey&steamid=$steamId&include_appinfo=true&format=json"

$games = (Invoke-RestMethod $url).response.games 

if (-not $games) {
    throw "No games returned. Check your API key, SteamID and profile privacy settings."
}

$unplayed = $games | Where-Object playtime_forever -eq 0

$results = foreach ($game in $unplayed){
    $appId = $game.appid
    $response = Invoke-RestMethod "https://store.steampowered.com/api/appdetails?appids=$appId&cc=$countryCode&filters=price_overview"

    $entry = $response."$appId"
    $priceInfo = $entry.data.price_overview

    if (-not $entry.success) {
        $status = 'Not in store'
        $price = $null
        $priceRegular = $null
    }
    elseif (-not $priceInfo) {
        $status = 'Free'
        $price = 0
        $priceRegular = 0
    }
    else {
        $status = 'OK'
        $price = $priceInfo.final   / 100
        $priceRegular = $priceInfo.initial / 100
    }

    [PSCustomObject]@{
        Name = $game.name
        AppId = $game.appid
        Price = $price
        PriceRegular = $priceRegular
        Discount = $priceInfo.discount_percent
        Currency = $priceInfo.currency
        Status = $status
    }
}
$results |
    Sort-Object Name |
    Format-Table -AutoSize

$priced = $results | Where-Object Status -eq 'OK'

$currency = ($priced | Select-Object -First 1).Currency

if (-not $currency) { $currency = '?' }

$statsFinal = $priced | Measure-Object Price -Sum -Average
$statsRegular = $priced | Measure-Object PriceRegular -Sum -Average

$mostExpensiveFinal = $priced | Sort-Object Price -Descending | Select-Object -First 1
$mostExpensiveRegular = $priced | Sort-Object PriceRegular -Descending | Select-Object -First 1

Write-Host ""
Write-Host ("Unplayed games with a price:   {0}"           -f $statsFinal.Count)
Write-Host ("Total wasted (current prices): {0:N2} $currency" -f $statsFinal.Sum)   -ForegroundColor Red
Write-Host ("Total wasted (regular prices): {0:N2} $currency" -f $statsRegular.Sum) -ForegroundColor Red
Write-Host ("Discount value:                {0:N2} $currency" -f ($statsRegular.Sum - $statsFinal.Sum))
Write-Host ("Average price (current):       {0:N2} $currency" -f $statsFinal.Average)
Write-Host ("Average price (regular):       {0:N2} $currency" -f $statsRegular.Average)
Write-Host ("Most expensive (current):      {1:N2} $currency - {0}" -f $mostExpensiveFinal.Price, $mostExpensiveFinal.Name)
Write-Host ("Most expensive (regular):      {1:N2} $currency - {0}" -f $mostExpensiveRegular.PriceRegular, $mostExpensiveRegular.Name)
