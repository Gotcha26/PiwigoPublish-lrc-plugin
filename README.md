# PiwigoPublish-lrc-plugin

A Lightroom Classic plugin which uploads images to a Piwigo hosts via the Piwigo API.

Currently at beta 0.9.4 version

## The following fuctionality is available:

* Connect to Piwigo Server and download existing album structure
    * Published Collection Sets and Published Collections are created in the LrC Publish Service corresponding to the albums and sub-albums in Piwigo (see features under development)
    * Images are not downloaded from Piwigo as part of this, nor are existing images in LrC added to the newly created Published Collections
* Images added to LrC Publish Service are publish to corresponding album on Piwigo
* Images removed from LrC Publish Service are removed from correspoinding album on Piwigo
* Moving a Published Collection under a different Published Collection Set is reflected in the associated Piwigo albums
* create album on Piwigo
    * Adding new Published Collections will create a corresponding album on Piwigo
* Rename associated Piwigo album when a Published Collection name is changed in LrC
* Delete associated Piwigo album when Published Collection is deleted in LrC
* Multiple Publish Services connecting to different Piwigo hosts.

## The following functionality is under development:

* Set Album Cover from an image in the Published Collection
* Add images to a Piwigo album that has sub-albums. 
    * The complication is that in LrC, the publish service can have Published Collections - to which images can be added, and Published Collection Sets - to which images can't be added but child Published Collections can. In Piwigo, an album can both contain images and also have sub albums. The approach being worked on will create a published collection that is associated with it's parent published collection set such that images added to this collection will be published in the parent album on Piwigo, not a sub album.
* Import collection/set/image structure from another publish service
    * if remoteIds / URLs are present these will be copied. Useful to copy another publish service where a Piwigo host is the target
* Consistency Check - check for images missing on Piwigo and update published status accordingly
* Metadata Check - check metadata on Piwigo matches Lrc (Title, Caption, GPS, Creator)

## The following functionality is planned
* Import existing Piwigo Publish Service
    * create collection sets and collections mirroring an existing collection, copying remote ids and urls, and add photos in existing collections, again copying remote ids
* Support for Piwigo API Keys when released - due in Piwigo 16.0.0 (currently 16.0.0RC1) - https://piwigo.org/forum/viewtopic.php?id=34376
* Localisation

## The following functionality is not currently planned:
* Download images from Piwigo to local drive


## CREDITS

As a user of both Lightroom Classic and Piwigo, the ability use the powerful Publishing Service in LrC to keep my Piwigo galleries up to date is very appealing. I've been a long time user of a popular plugin that has been providing this functionality, but unfortunately since the version 15 release of LrC that has not been available. 

This plugin is my attempt to allow me to continue publishing to Piwigo from LrC, and I have looked at the work of others for help and ideas in developing this plugin. In particular, the following should be credited:

[All the contributers to Piwigo](https://piwigo.org/)

[Jeffrey Friedl for JSON.lua](http://regex.info/blog/lua/json)

[Bastian Machek with his Immich Plugin](https://github.com/bmachek/lrc-immich-plugin)

[Min Idzelis with his Immich Plugin](https://github.com/midzelis/mi.Immich.Publisher)


## Disclaimer

With the exception of JSON.lua, Copyright 2010-2017 Jeffrey Friedl, which is released under a Creative Commons CC-BY "Attribution" License: http://creativecommons.org/licenses/by/3.0/deed.en_US, this software is released under the GNU General Public License version 3 as published by the Free Software Foundation.
         
This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <https://www.gnu.org/licenses/>.

## Development and Testing

This plugin has been developed on an macOS platform with Apple silicon. I don't have a windows platform capable of running Lightroom Classic available so no testing at all has been carried out on a windows platform.

The environment is:
Apple macOS Tahoe 26.1
Lightroom Classic 15.0.1 release
Piwigo 15.7.0 on Ubuntu 22.04.5 LTS

The released version is currently at beta 0.9.4. As a beta release the code is still full of debugging messages as I've grappled with the complexities of accessing the Piwigo web srevice API via the LrHttp namespace with it's idiosyncrasies. These will be tidied up, and a more consistent pattern for the various LrHttp calls id planned to be implemented.

However, in the meantime this plugin does what I need and hasn't corrupted either my Lightroom catalog or my Piwigo installation. If others want to try it pending a more official plugin being avaiable again I sugguest the following:

1. Backup Lrc Catalog and Piwigo gallery
2. Install and enable this plugin.
3. Add a publish service and connect it to your Piwigo host in the Lightroom Publishing Manager
4. Once a connection is established, the Import Albums button will activate. Click this button to import the album struction from Piwigo. An important note is that this plugin does not yet support Piwigo albums having both photos in them, and sub albums (see planned functionality above). You will see a Collection Sets and Collections in the Publish Service corresponding to your albums in Piwigo.
5. You can then populate these collections as publish if you have a different Piwigo Publish service you can copy photos from the publish service collections to the new publish service. Clicking the Publish button will send these photos to the correspoding Piwigo album. It will create duplicate photos if they've already been added to the Piwigo album outside of this plugin, so you may wish to clear the album prior to running the export from LrC.
