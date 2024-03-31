# Sketchfab Plugin Redone For Godot 4.0
**Import models from Sketchfab to Godot (v4.0+)**

* [Installation](#Installation)
* [Login](#Login)
* [Import a model from Sketchfab](#import-a-model-from-sketchfab)
* [Report an issue](#report-an-issue)

## Installation

Download the **sketchfab.zip** archive attached to the [latest release](https://github.com/StrayEddy/sketchfab-godot-plugin/releases/latest) of the plugin, and unzip it.

If you already have some plugins installed in your project, you will only need to copy the extracted directory to the `addons` directory (which you will need to create first if you did not use plugins previously).

You should therefore end up with this structure: `PROJECT_DIRECTORY/addons/sketchfab/[Zip content]`

Please note that if Godot is running, you might need to quit the editor and reopen it before loading the plugin.

Finally, you need to activate the plugin by going in the project settings (`Project -> Project settings`), and enabling the "Sketchfab" plugin in the Plugins tab.

The Sketchfab plugin should now be available in your project's tabs:

![godot1](https://user-images.githubusercontent.com/4066133/37650349-fabdf0e8-2c34-11e8-8c89-f7ecf5210472.JPG)

## Login

This plugin relies on the [Sketchfab download API](https://sketchfab.com/developers/download-api): a Sketchfab account is therefore **REQUIRED** to be able to download and import content from Sketchfab.

If you don't have one already, you can create it [here](https://sketchfab.com/signup).

Use your account email and password to login through the plugin interface, and you should now be able to import models from Sketchfab !

## Import a model from Sketchfab

Select the "Sketchfab" tab to open the browser window, and start browsing the library of 300k+ free models available on Sketchfab.

![godot2](https://user-images.githubusercontent.com/4066133/37650422-2e4c975c-2c35-11e8-8bf0-5cb6f3c972b7.JPG)

To download and import an asset, click on a model card to display the corresponding model page, and then click on "Download" to import the selected model into Godot.
![godot](https://user-images.githubusercontent.com/4066133/39196488-8db285ee-47e2-11e8-850e-82e1712d9bc9.jpg)

## Report an issue

If you feel like you've encountered a bug, or that the plugin lacks an important feature, you can [create an issue](https://github.com/StrayEddy/sketchfab-godot-plugin/issues/new) in this repository.

If you report a bug, please try to append any log from Godot or additional information (Godot version, Operating System...) in your message.
