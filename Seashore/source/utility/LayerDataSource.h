#import <Cocoa/Cocoa.h>
#import "Globals.h"

@class SeaDocument;
@class SeaOutlineView;
@class SeaLayer;

/*!
	@class		LayerDataSource
	@abstract	The view for Layer controls
	@discussion	Draws a background and borders for the buttons.
	<br><br>
	<b>License:</b> GNU General Public License<br>
	<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli	
*/
@interface LayerDataSource : NSObject <NSOutlineViewDataSource> {
	/// The document this data source is connected to
	IBOutlet SeaDocument *document;

	/// The nodes that are being dragged (if any)
	/// This should be null during no dragging
    NSArray<SeaLayer *> *draggedNodes;
	
	/// A reference back to the outline view
    IBOutlet SeaOutlineView *outlineView;
}

/*!
	@method		outlineViewAction:
	@discussion	Called when outline view is chicked on.
	@param		sender
				Ignored.
*/
- (IBAction)outlineViewAction:(id)sender;

/*!
	@property	draggedNodes
	@discussion	The nodes being dragged
	@result		An NSArray
*/
@property (readonly, retain) NSArray<SeaLayer *> *draggedNodes;

/*!
	@property	selectedNodes
	@discussion	The nodes selected
	@result		An NSArray
*/
@property (readonly, copy) NSArray<SeaLayer *> *selectedNodes;

/*!
	@method		update
	@discussion	Called when the data changes.
*/
- (void)update;
@end
