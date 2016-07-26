#import <Cocoa/Cocoa.h>
#import "Globals.h"

@class SeaDocument;

/*!
	@class		SVGImporter
	@abstract	Imports an SVG document as a layer.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/
@interface SVGImporter : NSObject {

	// The length warning panel
	IBOutlet NSPanel *waitPanel;
	
	// The spinner to update
	IBOutlet NSProgressIndicator *spinner;

	// The scaling panel
	IBOutlet NSPanel *scalePanel;
	
	// The slider indicating the extent of scaling
	IBOutlet NSSlider *scaleSlider;
	
	// A label indicating the document's expected size
	IBOutlet NSTextField *sizeLabel;
	
	// The document's actual and scaled size
	IntSize trueSize, size;

}

/*!
	@method		addToDocument:contentsOfFile:
	@discussion	Adds the given image file to the given document.
	@param		doc
				The document to add to.
	@param		path
				The path to the image file.
	@result		\c YES if the operation was successful, \c NO otherwise.
*/
- (BOOL)addToDocument:(SeaDocument*)doc contentsOfFile:(NSString *)path;

/*!
	@method		endPanel:
	@discussion	Closes the current modal dialog.
	@param		sender
				Ignored.
*/
- (IBAction)endPanel:(id)sender;

/*!
	@method		update:
	@discussion	Updates the document's expected size.
	@param		sender
				Ignored.
*/
- (IBAction)update:(id)sender;

@end
