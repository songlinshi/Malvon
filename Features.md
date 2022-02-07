# Features

### Hiding and Un-hiding tabs
    * Right click on the tab that you want to hide
    * To unhide the tabs, click on the tabbar, not the tabs, and click 'Unhide all tabs'
    * TODO: I'm planning to add a submenu list of all the hidden tabs

### Switching tabs ( `n` = the tab you want to switch to )
    * `CMD + n` switch to the tab
    * `CMD + OPTION + n` pause all the videos and switch to the tab
    * `CMD + CONTROL + n` close the tab at `n` position. There will be no switch to that tab
    
### Keyboard Shortcuts
    * New Tab: `CMD-T`
    * Close Tab: `CMD-W`
    * Reopen Tab: `CMD-SHIFT-T` ( **Error Saving UserDeaults** )
    * New Window: `CMD-N`
    * Close Window: `CMD-SHIFT-N`
    * Reopen Window: **TODO**
    * Reload Webpage: `CMD-SHIFT-R` ( I put shift because sometimes I accidently press this button when I wanted to create a new tab )
    * History: `CMD-SHIFT-H`
    * Downloads History: `CMD-SHIFT-D`
    * Open webpage file: `CMD-O` ( **TODO** )

# Features to add

### Tab Bar
    * Drag and Drop
        - NSDraggingSession 
    * Pinning Tabs
        - Changing the tab width, move the tab to the left side
        - Creating a new array called `pinnedTabs`, might use too much memory though...

### Preference
    * Let the user customize the web browser
    * Preference Items
        - Themes
        - Disable Web themes
        - Customize the tabs ( Width, Height etc..)
        - Faster Options? More Proforment, but uses more battery
        - Energy Saver Mode ( Disable web themes, disable other heavy features )

### Muting and Unmuting tabs
    * Check if the tab has any audio playing
    * Run a javascript code to mute the webview

### Password Manager
    * Javascript: Show a menu under the search field and send an alert to the webview saying that the user selected this.
    * Give the password and email address to Javascript
    * Javascript fills it in

### Themes
    * JSON Parser also disable web themes
