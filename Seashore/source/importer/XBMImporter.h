#import <Cocoa/Cocoa.h>
#ifdef SEASYSPLUGIN
#import "Globals.h"
#import "SeaImporter.h"
#else
#import <SeashoreKit/Globals.h>
#import <SeashoreKit/SeaImporter.h>
#endif

@class SeaDocument;

/*!
	@class		XBMImporter
	@abstract	Imports an XBM file as a layer.
	@discussion	See http://www.dcs.ed.ac.uk/home/mxr/gfx/2d/XBM.txt for more
				information on the X BitMap Format.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/
@interface XBMImporter : NSObject <SeaImporter>

/*!
	@method		addToDocument:contentsOfFile:
	@discussion	Adds the given image file to the given document.
	@param		doc
				The document to add to.
	@param		path
				The path to the image file.
	@result		YES if the operation was successful, NO otherwise.
*/
- (BOOL)addToDocument:(SeaDocument*)doc contentsOfFile:(NSString *)path DEPRECATED_ATTRIBUTE;

/*!
 @method		addToDocument:contentsOfURL:error:
 @discussion	Adds the given image file to the given document.
 @param			doc
 				The document to add to.
 @param			path
 				The file URL to the image file.
 @result		\c YES if the operation was successful, \c NO otherwise.
 */
- (BOOL)addToDocument:(SeaDocument*)doc contentsOfURL:(NSURL *)path error:(NSError *__autoreleasing*)error;

@end
