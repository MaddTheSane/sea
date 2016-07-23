#import "Globals.h"

@class StatusUtility;

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
	CGFloat oldWidth;
	NSPoint oldPoint;
	
	// The other views in the window
	IBOutlet NSView *leftPane;
	IBOutlet NSView *rightPane;
	
	// The buttons
	IBOutlet NSButton *newButton;
	IBOutlet NSButton *dupButton;
	IBOutlet NSButton *delButton;
	IBOutlet NSButton *shButton;
	
	IBOutlet NSView *divider;
	
	BOOL drawThumb;
	
	IBOutlet StatusUtility *statusUtility;
}

@property BOOL hasResizeThumb;
- (void)setHasResizeThumb:(BOOL)hasIt;

@end
