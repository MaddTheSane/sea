#import <Cocoa/Cocoa.h>
#import "Globals.h"

/*!
	@class		SeaTexture
	@abstract	Represents a single texture.
	@discussion	N/A 
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/
@interface SeaTexture : NSObject {
	// The texture
	unsigned char *colorTexture;
	unsigned char *greyTexture;
	
	// The width and height of the texture
	int width;
	int height;
	
	// The name of the texture
	NSString *name;
}

/*!
	@method		initWithContentsOfFile:
	@discussion	Initializes an instance of this class with the given image file.
				The image must be 8-bit, may or may not have an alpha channel in
				either case such a channel is ignored) and must be an RGB or
				greyscale (with white = 255) image.
	@param		path
				The path of the file with which to initalize this class.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (instancetype)initWithContentsOfFile:(NSString *)path;

/*!
	@method		activate
	@discussion	Activates the texture.
*/
- (void)activate;

/*!
	@method		deactivate
	@discussion	Deactivates the texture.
*/

- (void)deactivate;

/*!
	@property	thumbnail
	@discussion	Returns a thumbnail of the texture.
	@result		Returns an NSImage that is no greater in size than 44 by 44
				pixels.
*/
@property (readonly, copy) NSImage *thumbnail;

/*!
	@property	name
	@discussion	Returns the name of the texture.
	@result		Returns an NSString representing the name of the texture.
*/
@property (readonly, copy) NSString *name;

/*!
	@property	width
	@discussion	Returns the width of the texture.
	@result		Returns the width of the texture in pixels.
*/
@property (readonly) int width;

/*!
	@property	height
	@discussion	Returns the height of the texture.
	@result		Returns the height of the texture in pixels.
*/
@property (readonly) int height;

/*!
	@method		texture:
	@discussion	Returns a bitmap representation of the texture. The bitmap
				representation can be requested in colour or greyscale versions
				and is always without an alpha channel.
	@param		color
				A boolean specifying whether the returned bitmap should be
				colour or greyscale.
	@result		Returns a reference to a 8-bit bitmap with 3 channels (RGB) if
				\c color is \c YES or 1 channel (W) if \c color is <code>NO</code>.
*/
- (unsigned char *)texture:(BOOL)color;

/*!
	@method		textureAsNSColor:
	@discussion	Returns a NSColor representation of the texture. The \c NSColor
				representation can be requested in colour or greyscale versions
				and is always without an alpha channel.
	@param		color
				A boolean specifying whether the returned \c NSColor should be
				colour or greyscale.
	@result		Returns a reference to either a NSColor.
*/
- (NSColor *)textureAsNSColor:(BOOL)color;

/*!
	@method		compare:
	@discussion	Compares two brushes to see which should come first in the
				texture utility (comparisons are currently based on the
				texture's name).
	@param		other
				The other texture with which to compare this texture.
	@result		Returns an <code>NSComparisonResult</code>.
*/
- (NSComparisonResult)compare:(SeaTexture*)other;

@end
