# Minetest Presentations
A mod for minetest that allows displaying images downloadable at runtime.  
It servers two main purpuses:  
1. Displaying images ingame, for the use in virtual exhibitions/galleries or simply for decoration.  
2. Holding virtual presentations.  

To achieve this two items are added to the game:   
(You can find both by typing "presentation" in the search bar)  
1. Display  
2. Display Remote  
	 
---

### Example 
I made this mod to hold my Bachelor Thesis presentation during COVID times.  
Here is what it looked like:  


![Example Use1](https://user-images.githubusercontent.com/38705070/107877861-3caa2000-6ecf-11eb-997d-abee3c550fed.png)

![Example Use2](https://user-images.githubusercontent.com/38705070/107877865-459af180-6ecf-11eb-9bbd-d4396549e7b5.png)

---

### Display

The display item is a canvas that display images (.png or .jpg).  
It can display a multitude of images if multiple are specified in the respective image list.  
You can set it up and edit it by right clicking.  
This includes changing size, proportions, rotation, position and images to display.  
You can change the current displayed image by punching the canvas (left click) OR by using a display remote (see below)  

To add images you need to paste a link ending in .png or .jpg into the "URLS" input fields, multiple images can be downloaded at once.   
The image will be downloaded once and will then be available with the specified name.  
The image name becomes the last part of the url, so: "http://www.foo.com/bar.png" will be saved as "bar.png".  
If an image with the same name already exist it will NOT be overritten! Only one image with the same name can exist at once.  
A filesize limit of 2MB has been added to avoid the download of massive files.    
Requires "presentations" privilage to be edited.   
Adding images is ONLY available through http. So no uploading and no https support as of right now.  

![Display UI](https://user-images.githubusercontent.com/38705070/107877925-97dc1280-6ecf-11eb-916d-e43f2e7705e0.png)

---

### Display Remote
The remote is used to facilitate the presentation, it is not necessary.   
Left clicking with a remote on a display will "connect" the remote to that presentation  
Left clicking while connected opens up a UI that lets you change slides.  
You can give a connected remote to a user without the "presentations" privilage to allow them to change slides.  

![Remote UI](https://user-images.githubusercontent.com/38705070/107877924-9579b880-6ecf-11eb-9533-aeb11abbd380.png)

---


### Installation

To install it copy the downloaded folder (see releases) to the /mods/ folder of your server.  
(The mod uses [*luasocket*](http://w3.impa.br/~diego/software/luasocket/). Releases include a copy of it. If installing from source, you will need to install it manually.) 

To allow downloading images at runtime the mod needs to get added to the *trusted_mods* in the minetest.conf.  
Add this line to your minetest.conf:  
`"secure.trusted_mods = presentations"`  


Once ingame you will need the "presentations" privilage to edit/add displays.  
`/grant username presentations`    
