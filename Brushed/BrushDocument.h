/*
	Brushed 0.8.1
	
	This class loads and saves the brush. It also handles most
	editing of the brush.
	
	Copyright (c) 2002 Mark Pazolli
	Distributed under the terms of the GNU General Public License
*/

#import "Globals.h"
#import "BrushView.h"
#include <stdbool.h>

typedef struct
{
	unsigned char *mask;
	unsigned char *pixmap;
	int width;
	int height;
	bool usePixmap;
} BitmapUndo;
