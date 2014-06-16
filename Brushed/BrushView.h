/*
	Brushed 0.8.1
	
	This class provides a visual representation of the brush.
	
	Copyright (c) 2002 Mark Pazolli
	Distributed under the terms of the GNU General Public License
*/

#import "Globals.h"
@class BrushDocument;

@interface BrushView : NSView
{

	// The document associated with this view
	IBOutlet BrushDocument *document;

}

@end
