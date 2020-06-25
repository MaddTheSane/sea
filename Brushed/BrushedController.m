#import "BrushedController.h"
#import "Brushed-Swift.h"

#define document [[NSDocumentController sharedDocumentController] currentDocument]

@implementation BrushedController

- (IBAction)copy:(id)sender
{
	NSImage *image = [document brushImage];
	NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
	
	// Copy the image to the pasteboard
	[pasteboard declareTypes:@[NSPasteboardTypeTIFF] owner:nil];
	[pasteboard setData:[image TIFFRepresentation] forType:NSPasteboardTypeTIFF];
}

- (IBAction)paste:(id)sender
{
	NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
	NSString *dataType = [pasteboard availableTypeFromArray:@[NSPasteboardTypeTIFF]];
	
	// Copy the image from the pasteboard
	if (dataType) {
		[document changeImage:[NSBitmapImageRep imageRepWithData:[pasteboard dataForType:dataType]] error:NULL];
	}
}

- (BOOL)validateMenuItem:(id)menuItem
{
	if (document == NULL)
		return NO;
	
	return YES;
}

@end
