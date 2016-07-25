#import <AppKit/AppKit.h>
#import "Globals.h"

/*!
	@enum		k...Mode
	@constant	kDefaultMode
				Default selection.
	@constant	kAddMode
				Add to the selection.
	@constant	kSubtractMode
				Subtract from the selection.
	@constant	kMultiplyMode
				Multiply the selections.
	@constant	kSubtractProductMode
				Subtract the product of the selections.
	@constant	kForceNewMode
				For a new selection
*/
typedef NS_ENUM(int, SeaSelectMode) {
	SeaSelectDefault,
	SeaSelectAdd,
	SeaSelectSubtract,
	SeaSelectMultiply,
	SeaSelectSubtractProduct,
	SeaSelectForceNew,
	
	kDefaultMode NS_SWIFT_UNAVAILABLE("Use .Default instead") = SeaSelectDefault,
	kAddMode NS_SWIFT_UNAVAILABLE("Use .Add instead") = SeaSelectAdd,
	kSubtractMode NS_SWIFT_UNAVAILABLE("Use .Subtract instead") = SeaSelectSubtract,
	kMultiplyMode NS_SWIFT_UNAVAILABLE("Use .Multiply instead") = SeaSelectMultiply,
	kSubtractProductMode NS_SWIFT_UNAVAILABLE("Use .SubtractProduct instead") = SeaSelectSubtractProduct,
	kForceNewMode NS_SWIFT_UNAVAILABLE("Use .ForceNew instead") = SeaSelectForceNew
};

@class SeaDocument;

/*!
	@class		SeaSelection
	@abstract	Manages user selections.
	@discussion	This class is yet to be fully implemented.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface SeaSelection : NSObject {

	// The document associated with this object
	SeaDocument *document;

	// The current selection rectangle
	IntRect rect, globalRect;
	
	// The current selection bitmap and mask
	unsigned char *mask;
	
	// Used to determine if the selection is active
	BOOL active;
	
	// Help present the user with a visual representation of the mask
	int selectionColorIndex;
	unsigned char *maskBitmap;
	NSBitmapImageRep *maskBitmapRep;
	NSImage *maskImage;
	
	// The point of the last copied selection and its size
	IntPoint sel_point;
	IntSize sel_size;
	
}

/*!
	@method		initWithDocument:
	@discussion	Initializes an instance of this class with the given document.
	@param		doc
				The document with which to initialize the instance.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (instancetype)initWithDocument:(SeaDocument*)doc;

/*!
	@method		active
	@discussion	Returns whether the current selection is active or not.
	@result		Returns YES if the selection is active, NO otherwise.
*/
- (BOOL)active;

/*!
	@property	floating
	@discussion	Returns whether the current selection is floating or not.
				Floating implies that the selection's bitmap data is a detached
				from the layer.
	@result		Returns YES if the selection is floating, NO otherwise.
*/
@property (readonly) BOOL floating;

/*!
	@property	mask
	@discussion	Returns a mask indicating the opacity of the selection, if NULL
				is returned the selection rectangle should be assumed to be
				entirely opaque.
	@result		Returns a reference to an 8-bit single-channel bitmap or NULL.
*/
@property (readonly) unsigned char *mask NS_RETURNS_INNER_POINTER;

/*!
	@property	maskImage
	@discussion	Returns an image of the mask in the current selection colour.
				This is used so the selection can be represented to users.
*/
@property (readonly, strong) NSImage *maskImage;

/*!
	@property	maskOffset
	@discussion	Returns the offset of the mask.
	@result		Returns an IntPoint indicating the point in the mask that
				corresponds to the top-left corner of localRect.
*/
@property (readonly) IntPoint maskOffset;

/*!
	@property	maskSize
	@discussion	Returns the size of the mask.
	@result		Returns an IntSize indicating the size of the mask.
*/
@property (readonly) IntSize maskSize;

/*!
	@property	trueLocalRect
	@discussion	Returns the selection's true rectangle (this rectangle may
				be larger than the active layer and should rarely be required).
	@result		Returns an IntRect reprensenting the rectangle selection's true
				rectangle in the overlay's co-ordinates.
*/
@property (readonly) IntRect trueLocalRect;

/*!
	@property	globalRect
	@discussion	Returns a rectangle enclosing the current selection.
	@result		Returns an IntRect reprensenting the rectangle that encloses the
				current selection in the document's co-ordinates.
*/
@property (readonly) IntRect globalRect;

/*!
	@property	localRect
	@discussion	Returns a rectangle enclosing the current selection.
	@result		Returns an IntRect reprensenting the rectangle that encloses the
				current selection in the overlay's co-ordinates.
*/
@property (readonly) IntRect localRect;

/*!
	@method		selectRect:
	@discussion Selects the given rectangle in the document (handles updates and
				undos).
	@param		selectionRect
				The rectangle to select in the overlay's co-ordinates.
	@param		mode
				The mode of the selection (see above).
*/
- (void)selectRect:(IntRect)selectionRect mode:(SeaSelectMode)mode;

/*!
	@method		selectEllipse:intermediate:
	@discussion Selects the given ellipse in the document.
	@param		selectionRect
				The rectangle containing the ellipse to select in the overlay's
				co-ordinates.
	@param		mode
				The mode of the selection (see above).
*/
- (void)selectEllipse:(IntRect)selectionRect mode:(SeaSelectMode)mode;

/*!
	@method		selectRoundedRect:intermediate:
	@discussion Selects the given rounded rectangle in the document.
	@param		selectionRect
				The rectangle containing the rounded rectangle to select in the
				overlay's co-ordinates.
	@param		radius
				An integer indicating the rounded rectangle's curve radius.
	@param		mode
				The mode of the selection (see above).
*/
- (void)selectRoundedRect:(IntRect)selectionRect radius:(int)radius mode:(SeaSelectMode)mode;

/*!
	@method		selectOverlay:inRect:mode:
	@discussion Selects the area given by the overlay's alpha channel.
	@param		destructively
				YES if the overlay is to be destroyed during the selection, NO
				otherwise.
	@param		selectionRect
				The rectangle contianing the section of the overlay to be
				considered for selection.
	@param		mode
				The mode of the selection (see above).
*/
- (void)selectOverlay:(BOOL)destructively inRect:(IntRect)selectionRect mode:(SeaSelectMode)mode;

/*!
	@method		selectOpaque
	@discussion	Selects the opaque parts of the active layer.
*/
- (void)selectOpaque;

/*!
	@method		moveSelection:
	@discussion	This moves the selection (but not the selection's contents) to the
				new origin.
	@param		newOrigin
				The new origin.
*/
- (void)moveSelection:(IntPoint)newOrigin;

/*!
	@method		readjustSelection
	@discussion	Readjusts the selection so it does not extend beyond the layer's
				boundaries.
*/
- (void)readjustSelection;

/*!
	@method		clearSelection
	@discussion	Makes the current selection void (don't confuse this with
				deleteSelection).
*/
- (void)clearSelection;

/*!
	@method		flipSelection:
	@discussion	Flips the current selection's mask in the desired manner (does
				not affect content).
	@param		type
				The type of flip (see SeaFlip).
*/
- (void)flipSelection:(int)type;

/*!
	@method		invertSelection
	@discussion	Inverts the current selection (i.e. selects everything in the
				layer that is not selected or nothing if everything is
				selected).
*/
- (void)invertSelection;

/*!
	@method		selectionData
	@discussion	Returns a block of memory containing the layer data encapsulated
				by the rectangle.
	@param		premultiplied
				YES if the returned data should be premultiplied, NO otherwise.
	@result		Returns a pointer to a block of memory containing the layer data
				encapsulated by the rectangle.
*/
- (unsigned char *)selectionData:(BOOL)premultiplied;

/*!
	@method		selectionSizeMatch:
	@discussion	Compares the given size to the size of the last selection.
	@param		inp_size
				The size for comparison.
	@result		Returns YES if the size is equal to the size of the last selection,
				NO otherwise.
*/
- (BOOL)selectionSizeMatch:(IntSize)inp_size;

/*!
	@method		selectionPoint
	@discussion	Returns the point from which the last selection was copied.
	@result		Returns an IntPoint indicating the point from which the last
				selection was copied.
*/
- (IntPoint)selectionPoint;

/*!
	@method		cutSelection
	@discussion	Calls copySelection followed by deleteSelection.
*/
- (void)cutSelection;

/*!
	@method		copySelection
	@discussion	Copies the current selection to the clipboard.
*/
- (void)copySelection;

/*!
	@method		deleteSelection
	@discussion	Deletes the contents of the current selection from the active
				layer (don't confuse this with clearSelection).
*/
- (void)deleteSelection;

/*!
	@method		adjustOffset:
	@discussion	Adjusts the offset of the selection rectangle.
	@param		offset
				An IntPoint representing the adjustment in the offset of the
				selection rectangle.
*/
- (void)adjustOffset:(IntPoint)offset;

/*!
	@method		scaleSelectionHorizontally:vertically:
	@discussion	Scales the current selection.
	@param		xScale
				The scaling to be done horizontally on the selection.
	@param		yScale
				The scaling to be done vertically on the selection.
	@param		interpolation
				The interpolation to be used when scaling (see GIMPCore).
*/
- (void)scaleSelectionHorizontally:(float)xScale vertically:(float)yScale interpolation:(int)interpolation;

/*!
	@method		scaleSelectionTo:from:interpolation:usingMask:
	@discussion	Scales the current selection.
	@param		newRect
				The rectangle of the new selection.
	@param		oldRect
				The rectangle of the old selection.
	@param		interpolation
				The interpolation to be used when scaling (see GIMPCore).
	@param		oldMask
				The mask that should be scaled to the newRect.
*/
- (void)scaleSelectionTo:(IntRect)newRect from:(IntRect)oldRect interpolation:(int)interpolation usingMask:(unsigned char*)oldMask;

/*!
	@method		trimSelection
	@discussion	Trims the selection so it contains no redundant parts, that is,
				so every line in the mask contains some white.
*/
- (void)trimSelection;

@end
