#include <GIMPCore/GIMPCore.h>
#import <Cocoa/Cocoa.h>
#ifdef SEASYSPLUGIN
#import "Globals.h"
#import "SeaPrefs.h"
#else
#import <SeashoreKit/Globals.h>
#import <SeashoreKit/SeaPrefs.h>
#endif

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
	SeaSelectDefault,			///< Default selection.
	SeaSelectAdd,				///< Add to the selection.
	SeaSelectSubtract,			///< Subtract from the selection.
	SeaSelectMultiply,			///< Multiply the selections.
	SeaSelectSubtractProduct,	///< Subtract the product of the selections.
	SeaSelectForceNew,			///< For a new selection
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

NS_ASSUME_NONNULL_BEGIN

@interface SeaSelection : NSObject {
	/// The document associated with this object
	__weak SeaDocument *document;

	/// The current selection rectangle
	IntRect rect, globalRect;
	
	/// The current selection bitmap and mask
	unsigned char *mask;
	
	/// Used to determine if the selection is active
	BOOL active;
	
	// Help present the user with a visual representation of the mask
	SeaGuideColor selectionColorIndex;
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
	@property	active
	@discussion	Returns whether the current selection is active or not.
	@result		Returns \c YES if the selection is active, \c NO otherwise.
*/
@property (readonly, getter=isActive) BOOL active;

/*!
	@property	floating
	@discussion	Returns whether the current selection is floating or not.
				Floating implies that the selection's bitmap data is a detached
				from the layer.
	@result		Returns \c YES if the selection is floating, \c NO otherwise.
*/
@property (readonly, getter=isFloating) BOOL floating;

/*!
	@property	mask
	@discussion	Returns a mask indicating the opacity of the selection, if \c NULL
				is returned the selection rectangle should be assumed to be
				entirely opaque.
	@result		Returns a reference to an 8-bit single-channel bitmap or NULL.
*/
@property (readonly, nullable) unsigned char *mask NS_RETURNS_INNER_POINTER;

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
				\c YES if the overlay is to be destroyed during the selection, \c NO
				otherwise.
	@param		selectionRect
				The rectangle contianing the section of the overlay to be
				considered for selection.
	@param		mode
				The mode of the selection (see above).
*/
- (void)selectOverlay:(BOOL)destructively inRect:(IntRect)selectionRect mode:(SeaSelectMode)mode NS_SWIFT_NAME(selectOverlay(destructively:in:mode:));

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
- (void)moveSelection:(IntPoint)newOrigin NS_SWIFT_NAME(moveSelection(_:));

/*!
	@method		readjustSelection
	@discussion	Readjusts the selection so it does not extend beyond the layer's
				boundaries.
*/
- (void)readjustSelection NS_SWIFT_NAME(readjustSelection());

/*!
	@method		clearSelection
	@discussion	Makes the current selection void (don't confuse this with
				deleteSelection).
*/
- (void)clearSelection NS_SWIFT_NAME(clearSelection());

/*!
	@method		flipSelection:
	@discussion	Flips the current selection's mask in the desired manner (does
				not affect content).
	@param		type
				The type of flip (see <code>SeaFlipType</code>).
*/
- (void)flipSelection:(SeaFlipType)type NS_SWIFT_NAME(flipSelection(_:));

/*!
	@method		invertSelection
	@discussion	Inverts the current selection (i.e. selects everything in the
				layer that is not selected or nothing if everything is
				selected).
*/
- (void)invertSelection NS_SWIFT_NAME(invertSelection());

/*!
	@method		selectionData
	@discussion	Returns a block of memory containing the layer data encapsulated
				by the rectangle.
	@param		premultiplied
				\c YES if the returned data should be premultiplied, \c NO otherwise.
	@result		Returns a pointer to a block of memory containing the layer data
				encapsulated by the rectangle.
*/
- (unsigned char *)selectionData:(BOOL)premultiplied NS_SWIFT_NAME(selectionData(premultiplied:));

/*!
	@method		selectionSizeMatch:
	@discussion	Compares the given size to the size of the last selection.
	@param		inp_size
				The size for comparison.
	@result		Returns \c YES if the size is equal to the size of the last selection,
				\c NO otherwise.
*/
- (BOOL)selectionSizeMatch:(IntSize)inp_size;

/*!
	@property	selectionPoint
	@discussion	Returns the point from which the last selection was copied.
	@result		Returns an \c IntPoint indicating the point from which the last
				selection was copied.
*/
@property (readonly) IntPoint selectionPoint;

/*!
	@method		cutSelection
	@discussion	Calls copySelection followed by deleteSelection.
*/
- (void)cutSelection NS_SWIFT_NAME(cutSelection());

/*!
	@method		copySelection
	@discussion	Copies the current selection to the clipboard.
*/
- (void)copySelection NS_SWIFT_NAME(copySelection());

/*!
	@method		deleteSelection
	@discussion	Deletes the contents of the current selection from the active
				layer (don't confuse this with clearSelection).
*/
- (void)deleteSelection NS_SWIFT_NAME(deleteSelection());

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
- (void)scaleSelectionHorizontally:(CGFloat)xScale vertically:(CGFloat)yScale interpolation:(GimpInterpolationType)interpolation NS_SWIFT_NAME(scaleSelection(horizontally:vertically:interpolation:));

/*!
	@method		scaleSelectionToRect:fromRect:interpolation:usingMask:
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
- (void)scaleSelectionToRect:(IntRect)newRect fromRect:(IntRect)oldRect interpolation:(GimpInterpolationType)interpolation usingMask:(nullable unsigned char*)oldMask NS_SWIFT_NAME(scaleSelection(to:from:interpolation:usingMask:));

/*!
	@method		trimSelection
	@discussion	Trims the selection so it contains no redundant parts, that is,
				so every line in the mask contains some white.
*/
- (void)trimSelection NS_SWIFT_NAME(trimSelection());

@end

static const SeaSelectMode kDefaultMode NS_DEPRECATED_WITH_REPLACEMENT_MAC("SeaSelectDefault", 10.2, 10.8) = SeaSelectDefault;
static const SeaSelectMode kAddMode NS_DEPRECATED_WITH_REPLACEMENT_MAC("SeaSelectAdd", 10.2, 10.8) = SeaSelectAdd;
static const SeaSelectMode kSubtractMode NS_DEPRECATED_WITH_REPLACEMENT_MAC("SeaSelectSubtract", 10.2, 10.8) = SeaSelectSubtract;
static const SeaSelectMode kMultiplyMode NS_DEPRECATED_WITH_REPLACEMENT_MAC("SeaSelectMultiply", 10.2, 10.8) = SeaSelectMultiply;
static const SeaSelectMode kSubtractProductMode NS_DEPRECATED_WITH_REPLACEMENT_MAC("SeaSelectSubtractProduct", 10.2, 10.8) = SeaSelectSubtractProduct;
static const SeaSelectMode kForceNewMode NS_DEPRECATED_WITH_REPLACEMENT_MAC("SeaSelectForceNew", 10.2, 10.8) = SeaSelectForceNew;

NS_ASSUME_NONNULL_END
