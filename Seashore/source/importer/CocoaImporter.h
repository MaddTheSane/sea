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
	@class		CocoaImporter
	@abstract	Imports a Cocoa-compatible document as a layer.
	@discussion	Cocoa-compatible image files are those supported by the
				NSBitmapImageRep class.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/
@interface CocoaImporter : NSObject <SeaImporter> {
	IBOutlet NSPanel *pdfPanel;
	IBOutlet NSTextField *pageLabel;
	IBOutlet NSTextField *pageInput;
	IBOutlet NSPopUpButton *resMenu;
}

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

/*!
	@method		endPanel:
	@discussion	Closes the current modal dialog.
	@param		sender
				Ignored.
*/
- (IBAction)endPanel:(id)sender;

@end
