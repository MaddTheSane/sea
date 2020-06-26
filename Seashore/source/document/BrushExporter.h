#import <Cocoa/Cocoa.h>
#ifdef SEASYSPLUGIN
#import "Globals.h"
#else
#import <SeashoreKit/Globals.h>
#endif

@class SeaDocument;
@class NSExtendedTableView;

/*!
	@class		TextureExporter
	@abstract	Exports a Seashore document as a texture.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface BrushExporter : NSObject <NSTableViewDataSource> {

	// The document associated with this object
    __weak IBOutlet SeaDocument *document;

	// The exporting panel
	__weak IBOutlet NSPanel *sheet;

	__weak IBOutlet NSExtendedTableView *categoryTable;
	
	__weak IBOutlet NSTextField *categoryTextbox;
	
	__weak IBOutlet NSButton *existingCategoryRadio;
	
	__weak IBOutlet NSButton *newCategoryRadio;
	
	__weak IBOutlet NSTextField *nameTextbox;
}

@property int spacing;
/*!
	@method		awakeFromNib
	@discussion	Configures the exporting panel's interface.
*/
- (void)awakeFromNib;

/*!
	@method		exportAsTexture:
	@discussion	Displays the exporting panel.
	@param		sender
				Ignored.
*/
- (IBAction)exportAsBrush:(id)sender;

/*!
	@method		apply:
	@discussion	Executes the export.
	@param		sender
				Ignored.
*/
- (IBAction)apply:(id)sender;

/*!
	@method		cancel:
	@discussion	Cancels the export.
	@param		sender
				Ignored.
*/
- (IBAction)cancel:(id)sender;

- (IBAction)existingCategoryClick:(id)sender;

- (IBAction)newCategoryClick:(id)sender;

/*
*/
- (void)selectButton:(int)button;

@end
