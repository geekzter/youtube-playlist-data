# YouTube Playlist track metadata
 
This repo contains a script to fetch YouTube playlist information. It fetches metadata (title, description, etc) and is NOT a video downloader. For playlists containing music tracks, it parses Artist, Title, Version, Year into distinct fields.

## Pre-requisites
This uses the YouTube Data [API](https://developers.google.com/youtube/v3/docs/), which requires some configuration to access. 

### Retrieval
For retrieval operations (e.g. `get_playlist_data.ps1`) an API key is sufficient:

- Go to the [Google Developer Console](https://console.developers.google.com/)
- Create a project
- Add the YouTube API
- Create an API Key (under credentials)   

You can add the API key to the [config.json](config.json.sample) file, so you don't have to pass it to the script:
```
{
    "ApiKey" : "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
}
```

### Updates
For updates (e.g. `import_playlist.ps1`) you will need the following:

- Go to the [Google Developer Console](https://console.developers.google.com/)
- Create a project
- Add the YouTube API
- Create a Client Secret (under credentials)
- Download the JSON file
- Fetch a token:
```
oauth2l fetch --credentials ./client_secret_000000000000-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com.json --scope youtube.force-ssl
```
- This will construct you to open a browser and complete a OAuth flow

You can add the API key to the [config.json](config.json.sample) file, so you don't have to pass it to the script:
```
{
    "ClientCredentialFile" : "client_secret_000000000000-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com.json",
}
```

### Tools
You will also need [PowerShell](https://github.com/PowerShell/PowerShell#get-powershell) 5 or higher to run the script.


## Running the playlist export script
Get the id of the playlist from the playlist's page:    
![alt text](url.png "Playlist URL")

Run the script by specifying the playlist id e.g.:
```
./get_playlist_data.ps1 -PlayListID PLCEF0C193C82DABF2
```

The result:
```
position title                                                                                       parsed_artist                     parsed_title                          parsed_version                         parsed_year publishedAt            url                                         description
-------- -----                                                                                       -------------                     ------------                          --------------                         ----------- -----------            ---                                         -----------
       0 Format - #1 - Solid session                                                                 1                                 Solid session                                                                            11/14/2010 3:05:31 PM  https://www.youtube.com/watch?v=QpbT6gqiOYA TECHNO by bodo de frascati
       6 Inner City Feat. Kevin Saunderson -  Big Fun (Juan's Magic Remix)1988 Ten Records 12        Inner City Feat. Kevin Saunderson Big Fun                               Juan's Magic Remix                     1988        11/14/2010 3:05:31 PM  https://www.youtube.com/watch?v=gxLgcdfdmCk Inner City Feat. Kevin Saunderson - B2 - Big Fun (Juan's Magic Remix) ©1988 Ten Records 12''<br/><br/>old skool acid house
       7 Degrees Of Motion - Do You Want It Right Now (King Street Mix)                              Degrees Of Motion                 Do You Want It Right Now              King Street Mix                                    11/14/2010 3:05:31 PM  https://www.youtube.com/watch?v=Z0KlAI7oNtw 
      12 Fast Eddie - Acid Thunder                                                                   Fast Eddie                        Acid Thunder                                                                             11/14/2010 3:05:31 PM  https://www.youtube.com/watch?v=C6V9WBTJlhw Acid Thunder and Get U Some More
      13 Fast Eddie - Let's Go (Don't U Want Some More)                                              Fast Eddie                        Let's Go                                                                                 11/14/2010 3:05:31 PM  https://www.youtube.com/watch?v=hi_Df7VtWcM Released in 1988, this was a huge track in NYC for many years. http://www.discogs.com/release/2749<br/><br/>Photos are stills from a few snippets of Sound Factory footage that are included in a documentary about Junior Vasquez by Ralph TV:<br/>http://www.myspace.com/video/ralph/for-the-record/5791525<br/><br/>Think it probably dates from 93/94 sometime. There's also some footage shot at Sound Factory circa 1990 right at the end of this house dance video (the short section shot in black & white):<br/>http://www.youtube.com/watch?v=uGwzoJ7LFMs
      14 LFO - LFO                                                                                   LFO                               LFO                                                                                      11/14/2010 3:05:31 PM  https://www.youtube.com/watch?v=HROMVIHGpLE LFO - LFO<br/>Released 26 Jul 1990
      15 Homeboy, Hippie & A Funky Dredd - Total Confusion/Heavenly Mix                              Hippie & A Funky Dredd            Total Confusion                       Heavenly Mix                                       11/15/2010 11:04:28 PM https://www.youtube.com/watch?v=_uhybEdY_go Companies, etc.<br/>Phonographic Copyright (p) – Tam Tam Records<br/>Copyright (c) – Tam Tam Records<br/>Phonographic Copyright (p) – Savage Records Ltd.<br/>Copyright (c) – Savage Records Ltd.<br/>Pressed By – Damont<br/><br/>Credits<br/>Producer, Mixed By – The Rising High Collective*<br/>Written By – Pound / Williams / Winter<br/>Written-By – Pound*, Williams*, Winter*
      17 Private video                                                                                                                                                                                                          11/30/2010 10:30:35 PM https://www.youtube.com/watch?v=i0NFWiXaS3U This video is private.
      19 Frankie Knuckles - Your Love                                                                Frankie Knuckles                  Your Love                                                                                1/20/2011 9:15:11 PM   https://www.youtube.com/watch?v=LOLE1YE_oFQ The original 1987 best version<br/>Jamie Principle/Frankie Knuckles (I know it's a bit fast)
      22 JOEY BELTRAM energy flash                                                                                                                                                                                              11/28/2011 7:57:22 PM  https://www.youtube.com/watch?v=PQfKFwa-jEY 1991, R&S Records. Deep, moody, underground classic from the N.Y.C. legend. Downstairs play at Venus the Club, Nottingham
      23 MK - Burning (MK Extended Remix)                                                            MK                                Burning                               MK Extended Remix                                  11/28/2011 7:58:48 PM  https://www.youtube.com/watch?v=3PqMVK9OAco Label: Cardiac Records  <br/>Catalog#: 3-4035-0-DJ  <br/>Country: US
      24 Mix Masters - In The Mix                                                                    Mix Masters                       In The Mix                            Mix                                                12/3/2011 10:28:47 PM  https://www.youtube.com/watch?v=0kLAGVm9bsM DJ International Records 1990
      26 Clubland - Let's Get Busy                                                                   Clubland                          Let's Get Busy                                                                           12/24/2011 11:09:40 PM https://www.youtube.com/watch?v=ZoE_6_5bh7Q 
      29 LEFTFIELD not forgotten (hard hands mix)                                                                                                                            hard hands mix                                     1/19/2012 10:15:34 PM  https://www.youtube.com/watch?v=0jd7zbScttQ 1991, Outer Rhythm Records. Top tune from the Leftfield boys, championing the 'progressive house' movement 17 years ago!
      30 The Shamen - Progen - Land of Oz                                                            The Shamen                        Progen                                                                                   1/19/2012 10:16:35 PM  https://www.youtube.com/watch?v=rhA3Dlg83XI 
```

Once downloaded, you can search locally (without needing the YouTube Data API) with `search_playlist.ps1`. This will search through the latest CSV downloaded, e.g.:
```
./search_playlist.ps1 looney

position       : 445
title          : LOONEY TUNES - JUST AS LONG AS I GOT YOU (CLUB MIX) 1989
parsed_artist  : LOONEY TUNES
parsed_title   : JUST AS LONG AS I GOT YOU 
parsed_version : CLUB MIX
parsed_year    : 1989
publishedAt    : 10/8/2020 6:03:49 PM
url            : https://www.youtube.com/watch?v=GIXUw25v2VU
description    : LOONEY TUNES - VOLUME ONE JUST AS LONG AS I GOT YOU
                 NU GROOVE RECORDS NG 023B<br/>FORMAT: VINYL
                 COUNTRY 
                 OF RELEASE: U.S 

```

## Running the playlist import script
The CSV from a playlist export can be modified and imported into another playlist e.g.

```
./import_playlist.ps1 -CsvFile ./data/someplaylist-20201122112156.csv -PlaylistID XXXXXXXXXXXXXXXXXXXXXXXXXX
```

Please be aware that YouTube Data API requests are constrained by quota, and updates are a lot more 'expensive' than retrieval operations. See [YouTube Data API (v3) - Quota Calculator](https://developers.google.com/youtube/v3/determine_quota_cost).