# **Achilles** Video player
Language: **Delphi**  
Date creation: **2024-11-10**  
APIs: **ActiveX**, **Windows Media player** *(legacy)*  
Architecture: **32bits**
# Notes
**When executing for the first time, it will create all necessary files**

# TODO
## Next release
* Playlist
    * Create new **playlist**
    * Remove focused **playlist**
    * Rename focused **playlist**
    * Copy Selected **Video** to another **playlist**
    * Remove Selected **Video** from focused **playlist**
    * Change focused **playlist**

## Uknown release
* Advanced options
    * From the focused **playlist**, automatically generate **playlists** with similarly named **Video**
        * Only if the count of total items is >= 2
        * The name of the playlist might be a fixed size  random string waiting for the user to rename it
* Upgrade architecture to 64bit
    * Change Windows Media Player API for a more suitable component

# Features
* Add a specific **Video** file
* Add all **Video** files from a folder (**Recursive**)
* Remove all saved **Video** from **playlists**
* Select a **Video**
    * OnDblClickClick
        * A loader is displayed
        * When the **Video** is loaded the loader disapears and the **Selected Video** starts playing

* Watching a **Video**
    * OnStop
        * The **Video** stops playing
        * It is possible to replay the **Video** by pressing the play video