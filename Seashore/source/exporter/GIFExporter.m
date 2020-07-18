#import "GIFExporter.h"
#import "SeaContent.h"
#import "SeaDocument.h"
#import "SeaWhiteboard.h"
#import "Bitmap.h"

@implementation GIFExporter

- (BOOL) hasOptions
{
	return NO;
}

- (NSString *)optionsString
{
	return @"";
}

- (IBAction) showOptions: (id) sender
{
	
}

- (NSString *)fileType
{
	return (NSString*)kUTTypeGIF;
}

- (NSString *) title
{
	return @"Graphics Interchange Format (GIF)";
}

- (NSString *) extension
{
	return @"gif";
}

- (BOOL) writeDocument: (SeaDocument*) document toFileURL:(NSURL *)path error:(NSError *__autoreleasing *)outError
{
	// Get the image data
	unsigned char* srcData = [[document whiteboard] data];
	int width = [[document contents] width];
	int height = [[document contents] height];
	int spp = [[document contents] spp];
	
	// Strip the alpha channel (there is no alpha in then GIF format)
	unsigned char* destData = malloc(width * height * (spp - 1));
	SeaStripAlphaToWhite(spp, destData, srcData, width * height);
	spp--;
	
	// Make an image representation from the data
	NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc]	initWithBitmapDataPlanes: &destData
			pixelsWide: width 
			pixelsHigh: height 
			bitsPerSample: 8
			samplesPerPixel: spp
			hasAlpha: NO 
			isPlanar: NO 
			colorSpaceName: (spp > 2) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace 
			bytesPerRow:width * spp 
			bitsPerPixel: 8 * spp];
	
	// With these GIF properties, we will let the OS do the dithering
	NSDictionary *gifProperties = @{NSImageDitherTransparency: @YES};
	
	// Save to a file
	NSData* imageData = [imageRep representationUsingType: NSGIFFileType properties: gifProperties];
	BOOL success = [imageData writeToURL:path options:NSDataWritingAtomic error:outError];
	
	// Cleanup
	free(destData);
	
	return success;
}

@end
