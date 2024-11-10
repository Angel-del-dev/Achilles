# Custom videplayer
Language: **Delphi**  
Date creation: **2024-11-10**  
APIs: **ActiveX**, **Windows Media player**  
Architecture: **32bits**
# Functionalities
* Add a specific **Video** file
* Add all **Video** files from a folder (**Recursive**)
    * CheckBox to remove old saved Data
* Filter by name
    * OnKeyUp
        * Displays a **label** next to the input to show the amount of similar items
        * Displays a **ComboBox** with every similar item
* **ComboBox** width similar items
    * Click
        * The item is selected in the **ListBox** container ready for the **User's OnClick** event
* Select a **Video**
    * OnClick
        * A loader is displayed and when the **Video** is loaded it disapears and the **Selected Video** starts playing

* Watching a **Video**
    * OnStop
        * The Video disapears and the previous screen is **shown**