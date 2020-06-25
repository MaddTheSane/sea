> Note: Parts of this read-me might be outdated and incorrect!

# Seashore Source Code


## Introduction


The Seashore source code consists of several different modules. If you are accessing the source code through SVN you must make sure to download each of these modules. Alternatively, if you are accessing the source code through a disk image, all of these modules should be included on the disk image.

For the latest version of the Seashore source code please consult:

http://seashore.sourceforge.net/

Unless otherwise noted all of Seashore's source code is distributed under the GNU General Public License v2.0.

## Build Environment

Building Seashore requires Xcode 9.4 or later on Mac OS 10.13 or later. Seashore is a 64-bit application, and will run on any Macintosh computer running Mac OS 10.9 or later.

## Modules and Build Order

The following are the modules of Seashore. You can build them independently, but we recommend that you use the Seashore workspace, which has the correct dependencies.

### GIMPCore

GIMPCore contains parts of the GIMP's code that Seashore uses more or less unaltered. Seashore relies upon the presence of GIMPCore to work.

### TIFF

TIFF contains libtiff 3.8.2. Seashore relies upon the presence of the TIFF framework to write TIFF files. 

### Plug-ins

Plug-ins contains the various plug-ins of Seashore. It is not necessary to build any of Seashore's plug-ins to build the application but if you chose not to build them you should remove them from "Plug-ins" subgroup of the "Resources" group in the Seashore project.

### SVGImporter (not required)

SVGImporter adds SVG support to Seashore. You can optionally build the installer - this can be used to remove the importer from Seashore.

### Seashore

Seashore contains the main application Seashore. After this is compiled you should be able to launch and use Seashore as an application.

### Brushed (not required)

Brushed contains Seashore's brush editor. This is a stand-alone application which is not necessary for Seashore to function.

### Pat2PNG (not required)

Pat2PNG contains Seashore's texture to PNG converter. This is a stand-alone application which is not necessary for Seashore to function.

### Updater (not required)

Updater contains the updater Seashore uses when it ships patches. Unlike other modules, the updater will not compile out-of-the-box and is generally not required by most users. It is distributed under the MIT License (not the GNU General Public License).

### Developer Documentation

Seashore has full developer documentation using Apple's HeaderDoc documentation system. If you have HeaderDoc installed you can generate the HeaderDoc documentation by running the "document.sh" script in the "scripts" directory. That should generate a "doc" directory in the Seashore module which you can then explore with any modern web browser.

## Contributing

There are a few things you should note before contributing to the Seashore source code.

### 1. Source code in the Seashore module that does not have HeaderDoc commenting will not be accepted

All of the code in the Seashore module has HeaderDoc comments. These are the comments in the header file that begin with `/*!` and end with `*/`. In order to maintain some level of readability in the code, code that does not have HeaderDoc comments will not be accepted into the Seashore module. This rule does not apply for other modules.

### 2. Try and use a consistent coding style

Everyone's coding style is unique, but try and use a coding style consistent with the project's. Please also try and use tabs as opposed to spaces for indentation.

### 3. Proprietary add-ons or helper programs may be made

I or anyone else may at a later date decide to implement proprietary add-ons or helper programs. These will need to be consistent with the GNU General Public License which means they cannot incorporate your open source code. However if you have an ideological opposition to such extensions you probably should not contribute to Seashore. Seashore's Invert and Blend plug-ins have been placed in the public domain to allow proprietary plug-ins to be built from them.

### 4. Have fun and talk to us

The forums and mailing list are there for you to talk to us. If you're interested in contributing please talk to us through the website:

http://seashore.sourceforge.net/
