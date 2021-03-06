#import "CocoaImporter.h"
#import "CocoaLayer.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaView.h"
#import "CenteringClipView.h"
#import "SeaOperations.h"
#import "SeaAlignment.h"
#import "SeaController.h"
#import "SeaWarning.h"

@implementation CocoaImporter

- (BOOL)addToDocument:(SeaDocument*)doc contentsOfFile:(NSString *)path
{
	return [self addToDocument:doc contentsOfURL:[NSURL fileURLWithPath:path] error:NULL];
}

- (BOOL)addToDocument:(SeaDocument *)doc contentsOfURL:(NSURL *)path error:(NSError *__autoreleasing *)error
{
	__kindof NSImageRep *imageRep;
	NSImage *image;
	SeaLayer *layer;
	NSInteger value;
	// NSPoint centerPoint;
	
	// Open the image
	image = [[NSImage alloc] initByReferencingURL:path];
	if (image == NULL) {
		if (error) {
			*error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:NULL];
		}
		return NO;
	}
	
	// Form a bitmap representation of the file at the specified path
	imageRep = NULL;
	if ([[image representations] count] > 0) {
		imageRep = [image representations][0];
		if (![imageRep isKindOfClass:[NSBitmapImageRep class]]) {
			if ([imageRep isKindOfClass:[NSPDFImageRep class]]) {
				if ([imageRep pageCount] > 1) {
					[NSBundle loadNibNamed:@"CocoaContent" owner:self];
					[resMenu setEnabled:NO];
					[pdfPanel center];
					[pageLabel setStringValue:[NSString stringWithFormat:@"of %ld", (long)[imageRep pageCount]]];
					[NSApp runModalForWindow:pdfPanel];
					[pdfPanel orderOut:self];
					value = [pageInput integerValue];
					if (value > 0 && value <= [imageRep pageCount])
						[imageRep setCurrentPage:value - 1];
				}
			}
			imageRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];
		}
	}
	if (imageRep == NULL) {
		if (error) {
			*error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:NULL];
		}
		return NO;
	}
		
	// Warn if 16-bit image
	if ([imageRep bitsPerSample] == 16) {
		[[SeaController seaWarning] addMessage:LOCALSTR(@"16-bit message", @"Seashore does not currently support the editing of 16-bit images. This image has been resampled at 8 bits to be imported.") forDocument: doc level:SeaWarningImportanceHigh];
	}
		
	// Create the layer
	layer = [[CocoaLayer alloc] initWithImageRep:imageRep document:doc spp:[[doc contents] spp]];
	if (layer == NULL) {
		if (error) {
			*error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:NULL];
		}
		return NO;
	}
	
	// Rename the layer
	[layer setName:[[path lastPathComponent] stringByDeletingPathExtension]];
	
	// Add the layer
	[[doc contents] addLayerObject:layer];
	
	// Now forget the NSImage
	
	// Position the new layer correctly
	[[[doc operations] seaAlignment] centerLayerHorizontally:NULL];
	[[[doc operations] seaAlignment] centerLayerVertically:NULL];
	
	return YES;
}

- (IBAction)endPanel:(id)sender
{
	[NSApp stopModal];
}

@end
