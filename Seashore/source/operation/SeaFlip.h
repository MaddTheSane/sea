#import "Globals.h"

@class SeaDocument;

/*!
	@class		SeaFlip
	@abstract	Handles the flipping of selections for Seashore.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/
@interface SeaFlip : NSObject
{
	// The document associated with this object
    IBOutlet SeaDocument *document;
}

- (void)floatingFlip:(SeaFlipType)type;
- (void)floatingHorizontalFlip;
- (void)floatingVerticalFlip;
- (void)standardFlip:(SeaFlipType)type;

/*!
	@method		simpleFlipOf:width:height:spp:type:
	@discussion	Flips the given data
	@param		data
				A pointer to the data to flip.
	@param		width
				The width of the data.
	@param		height
				The height of the data.
	@param		spp
				The samples per pixel of the data.
	@param		type
				The type of flip to preform on the data.
*/
- (void)simpleFlipOf:(unsigned char*)data width:(int)width height:(int)height spp:(int)spp type:(SeaFlipType)type;

/*!
	@method		run:
	@discussion	Flips the current selection in the desired manner or, if nothing
				is selected, the entire layer.
	@param		type
				The type of flip (see SeaFlip).
*/
- (void)run:(SeaFlipType)type;

@end
