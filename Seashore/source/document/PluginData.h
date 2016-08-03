#import <Cocoa/Cocoa.h>
#ifdef SEASYSPLUGIN
#import "Globals.h"
#import "Constants.h"
#import "SeaWhiteboard.h"
#else
#import <SeashoreKit/Globals.h>
#import <SeashoreKit/Constants.h>
#import <SeashoreKit/SeaWhiteboard.h>
#endif

/*!
	@class		PluginData
	@abstract	The object shared between Seashore and most plug-ins.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain 2004<br>
				<b>Copyright:</b> N/A
*/

@class SeaDocument;

@interface PluginData : NSObject

//! The document associated with this object
@property (weak) IBOutlet SeaDocument *document;

/*!
	@property	selection
	@discussion	Returns the rectange bounding the active selection in the
				layer's co-ordinates.
	@result		Returns a IntRect indicating the active selection.
*/
@property (readonly) IntRect selection;

/*!
	@property	data
	@discussion	Returns the bitmap data of the layer.
	@result		Returns a pointer to the bitmap data of the layer.
*/
@property (readonly) unsigned char *data NS_RETURNS_INNER_POINTER;

/*!
	@property	whiteboardData
	@discussion	Returns the bitmap data of the document.
	@result		Returns a pointer to the bitmap data of the document.
*/
@property (readonly) unsigned char *whiteboardData NS_RETURNS_INNER_POINTER;

/*!
	@property	replace
	@discussion	Returns the replace mask of the overlay.
	@result		Returns a pointer to the 8 bits per pixel replace mask of the
				overlay.
*/
@property (readonly) unsigned char *replace NS_RETURNS_INNER_POINTER;

/*!
	@property	overlay
	@discussion	Returns the bitmap data of the overlay.
	@result		Returns a pointer to the bitmap data of the overlay.
*/
@property (readonly) unsigned char *overlay NS_RETURNS_INNER_POINTER;

/*!
	@property	spp
	@discussion	Returns the document's samples per pixel (either 2 or 4).
	@result		Returns an integer indicating the document's sample per pixel.
*/
@property (readonly) int spp;

/*!
	@property	channel
	@discussion	Returns the currently selected channel.
	@result		Returns an integer representing the currently selected channel.
*/
@property (readonly) SeaSelectedChannel channel;

/*!
	@property	width
	@discussion	Returns the layer's width in pixels.
	@result		Returns an integer indicating the layer's width in pixels.
*/
@property (readonly) int width;

/*!
	@property	height
	@discussion	Returns the layer's height in pixels.
	@result		Returns an integer indicating the layer's height in pixels.
*/
@property (readonly) int height;

/*!
	@property	hasAlpha
	@discussion	Returns if the layer's alpha channel is enabled.
	@result		Returns YES if the layer's alpha channel is enabled, NO
				otherwise.
*/
@property (readonly) BOOL hasAlpha;

/*!
	@method		point:
	@discussion	Returns the given point from the effect tool. Only valid
				for plug-ins with type one.
	@param		index
				An integer from zero to less than the plug-in's specified
				value.
	@result		The corresponding point from the effect tool.
*/
- (IntPoint)point:(NSInteger)index;

/*!
	@method		foreColor
	@discussion	Return the active foreground colour.
	@param		calibrated
				YES if the colour is to be calibrated (usually bad), NO otherwise.
	@result		Returns an NSColor representing the active foreground
				colour.
*/
- (NSColor *)foreColor:(BOOL)calibrated;

/*!
	@method		backColor
	@discussion	Return the active background colour.
	@param		calibrated
				YES if the colour is to be calibrated (usually bad), NO otherwise.
	@result		Returns an NSColor representing the active background
				colour.
*/
- (NSColor *)backColor:(BOOL)calibrated;

/*!
	@property	displayProf
	@discussion	Returns the current display profile.
	@result		Returns a CGColorSpaceRef representing the ColorSync display profile
				Seashore is using.
*/
@property (readonly) CGColorSpaceRef displayProf CF_RETURNS_NOT_RETAINED;

/*!
	@method		window
	@discussion	Returns the window to use for the plug-in's panel.
	@result		Returns the window to use for the plug-in's panel.
*/
- (NSWindow *)window;

//! The overlay behaviour
@property SeaOverlayBehaviour overlayBehaviour;

/*!
	@method		setOverlayBehaviour:
	@discussion	Sets the overlay behaviour.
	@param		value
				The new overlay behaviour (see SeaWhiteboard).
*/
- (void)setOverlayBehaviour:(SeaOverlayBehaviour)value;

//! The opacity of the overlay
@property int overlayOpacity;

/*!
	@method		setOverlayOpacity:
	@discussion	Sets the opacity of the overlay.
	@param		value
				An integer from 0 to 255 representing the revised opacity of the
				overlay.
*/
- (void)setOverlayOpacity:(int)value;

/*!
	@method		applyWithNewDocumentData:spp:width:height:
	@discussion	Creates a new document with the given data.
	@param		data
				The data of the new document (must be a multiple of 128-bits in
				length).
	@param		spp
				The samples per pixel of the new document.
	@param		width
				The width of the new document.
	@param		height
				The height of the new document.
*/
- (void)applyWithNewDocumentData:(unsigned char *)data spp:(int)spp width:(int)width height:(int)height;

/*!
	@method		apply
	@discussion	Apply the plug-in changes.
*/
- (void)apply;

/*!
	@method		preview
	@discussion	Preview the plug-in changes.
*/
- (void)preview;

/*!
	@method		cancel
	@discussion	Cancel the plug-in changes.
*/
- (void)cancel;

@end
