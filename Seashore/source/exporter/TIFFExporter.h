#import <Cocoa/Cocoa.h>
#import "Globals.h"
#import "SeaAbstractExporter.h"

@class SeaDocument;

/*!
	@class		TIFFExporter
	@abstract	Exports to the tagged image file format using Cocoa.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/
@interface TIFFExporter : NSObject <SeaAbstractExporter> {
	
	// The associated document
	IBOutlet SeaDocument *idocument;
	
	// The panel allowing colour space choice
	IBOutlet NSPanel *panel;
	
	// The radio buttons specifying the target
	IBOutlet NSMatrix *targetRadios;

}

/*!
	@method		targetChanged:
	@discussion	Called when the user adjusts the media target.
	@param		sender
				Ignored.
*/
- (IBAction)targetChanged:(id)sender;

/*!
	@method		endPanel:
	@discussion	Called to close the options dialog.
	@param		sender
				Ignored.
*/
- (IBAction)endPanel:(id)sender;

@end
