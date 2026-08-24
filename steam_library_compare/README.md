# Steam Library Compare

Compares two Steam libraries and shows the games both players own, with each
player's total playtime side by side. Runs as an interactive menu.

## Setup

1. Get a Steam Web API key: https://steamcommunity.com/dev/apikey
   (any domain name works in the form - it is just a label)
2. Find both SteamID64 values (Steam client -> Account details,
   or https://steamid.io)
3. Set both profiles and **Game details** to public in Steam privacy settings -
   the API returns nothing for private profiles
4. Copy `config.example.json` to `config.json` and fill in your data

```json
{
  "steamApiKey": "your key here",
  "yourSteamId": "your SteamID64 here",
  "friendSteamId": "friend's SteamID64 here"
}
```

Only one API key is needed - the same key can query any public profile.

## Usage

```powershell
.\library_compare.ps1
```

A menu appears:

```
1. Run comparison          - fetch both libraries and show shared games
2. Change your SteamID      - saved to config.json
3. Change friend's SteamID  - saved to config.json
4. Change API key           - saved to config.json
5. Exit
```

Options 2-4 write straight to `config.json`, so changes stick between runs.

## Notes

Playtime is shown in hours (e.g. `92,7h`), rounded to one decimal place.
The decimal separator follows your system's regional settings.

Free-to-play games you have played (like Counter-Strike 2) are included -
Steam leaves them out of the library API by default, so the script asks
for them explicitly.

Playtime reflects the account's total on record; Steam does not expose
per-session history through the API.
