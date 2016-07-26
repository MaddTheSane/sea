#import <Cocoa/Cocoa.h>
#import "Globals.h"

/*!
	@class		LayerCell
	@abstract	A class to create a cell for the layers in the layers table.
	@discussion	N/A
	<br><br>
	<b>License:</b> GNU General Public License<br>
	<b>Copyright:</b> N/A
*/

@interface LayerCell : NSTextFieldCell {
	/// We need to know if the cell is selected because
	/// we do some drawing.
	BOOL selected;
}

/*!
	@property	image
	@discussion	Gets and sets the image used in this cell's view.
*/
@property (strong) NSImage *image;

/*!
	@method		drawWithFrame:inView:
	@discussion	For drawing the cell.
	@param		cellFrame
				The frame of the cell
	@param		controlView
				The view which will do the displaying
*/
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;

/*!
	@property	cellSize
	@discussion	Returns the dimensions of the cell
	@result		An NSSize.
*/
@property (readonly) NSSize cellSize;

/*
	@property	selected
	@discussion	Indicates whether or not we need the selection highlight.
*/
@property (getter=isSelected) BOOL selected;

@end
