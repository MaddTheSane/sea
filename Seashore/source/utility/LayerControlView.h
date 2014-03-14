#import "Globals.h"

/*!
	@class		LayerControlView
	@abstract	The view for Layer controls
	@discussion	Draws a background and borders for the buttons.
	<br><br>
	<b>License:</b> GNU General Public License<br>
	<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli	
*/

@interface LayerControlView : NSView {
	// If the user is dragging right now
	BOOL intermediate;
	
	// The previous width before the drag
	float oldWidth;
	NSPoint oldPoint;
	
	// The other views in the window
	IBOutlet id leftPane;
	IBOutlet id rightPane;
	
	// The buttons
	IBOutlet NSButton *newButton;
	IBOutlet NSButton *dupButton;
	IBOutlet NSButton *delButton;
	IBOutlet NSButton *shButton;
	
	IBOutlet id divider;
	
	BOOL drawThumb;
	
	IBOutlet id statusUtility;
}

- (void)setHasResizeThumb:(BOOL)hasIt;

@end
