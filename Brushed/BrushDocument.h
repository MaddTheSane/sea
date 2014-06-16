/*
	Brushed 0.8.1
	
	This class loads and saves the brush. It also handles most
	editing of the brush.
	
	Copyright (c) 2002 Mark Pazolli
	Distributed under the terms of the GNU General Public License
*/

#import "Globals.h"
#import "BrushView.h"

typedef struct
{
	unsigned char *mask;
	unsigned char *pixmap;
	int width;
	int height;
	BOOL usePixmap;
} BitmapUndo;

@interface BrushDocument : NSDocument <NSWindowDelegate>
{
	// A grayscale mask of the brush
	unsigned char *mask;
	
	// A coloured pixmap of the brush (RGBA)
	unsigned char *pixmap;
	
	// All previous bitmaps (for undos)
	BitmapUndo *undoRecords;
	NSInteger undoRecordsSize;
	NSInteger curUndoPos;
	
	// The spacing between brush strokes
	int spacing;
	
	// The width and height of the brush
	int width;
	int height;
	
	// The name of the brush
	NSString *name;
	
	// A memory of all past names for the undo manager
	NSArray *pastNames;
	
	// Do we use the pixmap or the mask?
	BOOL usePixmap;
	
}

	// The view displaying the brush
@property (weak) IBOutlet BrushView *view;
	
	// The label and slider that present the brush's spacing options
@property (weak) IBOutlet NSTextField *spacingLabel;
@property (weak) IBOutlet NSSlider *spacingSlider;
	
	// The text field for the name
@property (weak) IBOutlet NSTextField *nameTextField;
	
	// The label specifying the brush type (monochrome or full colour)
@property (weak) IBOutlet NSButton *typeButton;
	
	// The label specifying the dimensions of the brush
@property (weak) IBOutlet NSTextField *dimensionsLabel;

// Set the values suitably for a new document
- (instancetype)init;

// Returns an image representing the brush
- (NSImage *)brushImage;

// Add current brush image to the undo records
- (void)addToUndoRecords;

// Adjust the image of the brush
- (BOOL)changeImage:(NSBitmapImageRep *)newImage;

// Adjust the name of the brush
- (IBAction)changeName:(id)sender;

// Adjust the brush's spacing
- (IBAction)changeSpacing:(id)sender;

// Adjust the brush's type
- (IBAction)changeType:(id)sender;

// Loads the given file from disk, returns success
- (BOOL)readFromFile:(NSString *)path ofType:(NSString *)docType;

// Undoes the image to that which is stored by a given undo record
- (void)undoImageTo:(NSInteger)index;

// Undoes the name to a given string
- (void)undoNameTo:(NSString *)string;

// Undoes the spacing to a given value
- (void)undoSpacingTo:(int)value;

// Returns the nib file associated with this class
- (NSString *)windowNibName;

// Writes to the given file on disk, returns success
- (BOOL)writeToFile:(NSString *)path ofType:(NSString *)docType;

// Import a graphic for the brush
- (IBAction)import:(id)sender;

// Export the brush's graphic
- (IBAction)exportGraphic:(id)sender;

// The following calls changeName: before scheduling saving (two events cannot occur in the same loop)
- (IBAction)preSaveDocument:(id)sender;
- (IBAction)preSaveDocumentAs:(id)sender;

// Allows the save panel to explore
- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel;

@end
