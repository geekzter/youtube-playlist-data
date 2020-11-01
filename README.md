# YouTube Playlist (meta)data
 
This repo contains a script to fetch YouTube playlist information. It fetches metadata (title, description, etc) and is NOT a video downloader.

## Pre-requisites
This uses the YouTube Data [API](https://developers.google.com/youtube/v3/docs/), you'll need an API key to access it. This can be obtained [here](https://console.developers.google.com/). You can add the API key to the [settings.json](settings.json.sample) file, so you don't have to pass it to the script:
```
{
    "ApiKey" : "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
}
```


## Running the script
Get the id of the playlist from the playlist's page:
![alt text](url.png "Playlist URL")

Run the script by specifying the playlist id e.g.:
```
./get_playlist_data.ps1 -PlayListID PLbpi6ZahtOH54xRLxXzDneuhq12k36PFj
```
