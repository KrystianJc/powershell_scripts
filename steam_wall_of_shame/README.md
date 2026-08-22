# Steam Wall of Shame

Lists games from your Steam library that you have never played, together with
their current and regular store prices, and sums up how much that pile is worth.

## Setup

1. Get a Steam Web API key: https://steamcommunity.com/dev/apikey
2. Find your SteamID64 (Steam client -> Account details, or https://steamid.io)
3. Set your profile and **Game details** to public in Steam privacy settings —
   the API returns nothing for private profiles
4. Copy `config.example.json` to `config.json` and fill in your data

```json
{
  "steamApiKey": "your key here",
  "steamId": "your SteamID64 here",
  "countryCode": ""
}
```

Leave `countryCode` empty to detect it from your system settings, or set it
explicitly (`PL`, `US`, `DE`, ...) to see prices in another region.

## Usage

```powershell
.\steam-stats.ps1
```

## Rate limits

The store API used for prices is undocumented and rate limited. Community
reports suggest roughly **200 requests per 5 minutes** — one request per
unplayed game. Exceeding it returns empty responses for a few minutes.

The script does not throttle or cache, so:

- large libraries may hit the limit partway through
- running the script repeatedly in a short time makes it more likely
- if results come back empty, wait about 5 minutes and try again
- the script has no cache, so re-running it starts over from the first game
  and never gets past the limit on large libraries

A delay between requests and a local price cache would fix this properly.

## Notes

Prices reflect the **current** store price, not what you actually paid.
Steam does not expose purchase history through the API.
