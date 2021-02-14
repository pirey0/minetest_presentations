# Minetest Presentations
A mod for minetest that allows displaying images downloadable at runtime.  
It servers two main purpuses:  
1. Displaying images ingame, for the use in virtual exhibitions/galleries or simply for decoration.  
2. Holding virtual presentations.  

To achieve this he mod adds two items to the game:   
(You can find both by typing "presentation" in the search bar)  
1. The display item  
2. The display remote item  
	 

### DISPLAY:  
Requires "presentations" privilage to be edited.  
The display item is a canvas that display images (.png or .jpg).  
It can display a multitude of images if multiple are specified in the respective image list.  
You can set it up and edit it by right clicking.  
This includes changing size, proportions, rotation, position and images to display.  
You can change the current displayed image by punching the canvas (left click) OR by using a display remote (see below)  
To add images you need to paste a link ending in .png or .jpg.   
Adding images is ONLY available through http. So no uploading and as of right now no https.  
The image will be downloaded once and will then be available with the specified name.  
The image name becomes the last part of the url, so: "http://www.foo.com/bar.png" will be saved as "bar.png".  
If an image with the same name already exist it will NOT be overritten! Only one image with the same name can exist at once.  
A filesize limit of 2MB has been added to avoid the download of massive files.  



### DISPLAY REMOTE:
The remote is used to facilitate the presentation, it is not necessary.   
Left clicking with a remote on a display will "connect" the remote to that presentation  
Left clicking while connected opens up a UI that lets you change slides.  
You can give a connected remote to a user WITHOUT the presentations privilage to allow them to change slides.  
