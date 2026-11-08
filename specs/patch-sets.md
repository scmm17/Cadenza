I want a new feature for "patch sets"

# Patch sets functionality

- a patch set is represented by the state defined in the current settings YAML file.
- I want to allow multiple patch settings for a single song.
- There should be a notion of a current patch set used for the currently playing music
- Each patch setting is represented by a separate YAML file
- The YAML files will be stored in a sub-directory with the name of the song in the pattern: <song name.patch-sets>
- For legacy support, when a song without the patch-set sub-diectory is opened, we will create the sub directory and move the current YAML file to that directory.
- There should be a way to switch between patch sets.
  - Should work while playing and while stopped
- There should be a default patch set that is used when loading the song
- There should be a way to delete patch sets.
- There should be a way to create patch set based on the current settings. New patch sets should get a default unique name
- Patch sets should have a name and a way to change the name

# patch sets UI
- The patch sets UI should be to the right of the playback and tempo controls
- The default patch set should be shown initially when loading a song
- There should be a button the for patch sets
- The currently used patch set name should appear on the button
- When pressed it brings up the patch set dialog
  - The dialog is a list, one for each patch set for the song
  - The list entry should have a green check mark on the default patch set
  - The non-default entries should show a dim check mark, hight lighted on mouse over. If the user clicks oh the check mark, it becomes the default patch set.
  - There should be a "+" button at the top, creating a new patch set with the current settings.
  - The patch sets should be listed in alpahbetical order
  - There should be a dime "X" to the right of the check mark, highlighted on mouse over, when pressed the patch set is deleted, after a conformation dialog. If it was the default, the default reverts to the alphabetically first.
  - The currently selected patch set name at the top of the dialog should be an edit box letting you change the name
