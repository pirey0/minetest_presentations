# minetest_presentations
A mod for minetest that allows displaying images downloadable at runtime

The mod adds two items to the game: (You can find both by typing "presentation" in the search bar)

The display item

The display remote item 
	 

DISPLAY:
Requires "presentations" privilage to be edited.

The display item is a canvas that display images (.png or .jpg). It can display a multitude of images if multiple are specified in the respective image list.

You can set it up and edit it by right clicking.

This includes changing size, proportions, rotation, position and images to display.

You can change the current displayed image by punching the canvas (left click) OR by using a display remote (see below)

To add images you need to paste a link ending in .png or .jpg. 

Adding images is ONLY available through http. So no uploading.

The image will be downloaded ONCE and then will be available with the specified name.

The image name is the last part of the url! So: "www.foo.com/bar.png" will be saved as "bar.png".

If an image with the same name already exist it will NOT be overritten! So be careful with the names of your images! Used images are right now also not removed!

Avoid downloading big pictures or useless pictures as it will slow down the connection time for new clients. (A filesize limit of 2MB has been added for this reason)
 
 
REMOTE:
The remote is used to facilitate the presentation, it is not necessary. 

Left clicking with a remote on a display will "connect" the remote to that presentation

Left clicking while connected opens up a UI that lets you change slides.

You can give a connected remote to a user WITHOUT the presentations privilage to allow them to change slides.
