#import "PNGExporter.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "SeaDocument.h"
#import "SeaWhiteboard.h"

@implementation PNGExporter

- (BOOL)hasOptions
{
	return NO;
}

- (NSString *)fileType
{
	return (NSString*)kUTTypePNG;
}

- (NSString *)optionsString
{
	return @"";
}

- (IBAction)showOptions:(id)sender
{
}

- (NSString *)title
{
	return @"Portable Network Graphics image";
}

- (NSString *)extension
{
	return @"png";
}

- (BOOL)writeDocument:(SeaDocument*)document toFileURL:(NSURL *)path error:(NSError *__autoreleasing *)outError
{
	int i, j, width, height, spp;
	unsigned char *srcData, *destData;
	NSBitmapImageRep *imageRep;
	NSData *imageData;
	BOOL hasAlpha = NO;
	
	// Get the data to write
	srcData = [[document whiteboard] data];
	width = [[document contents] width];
	height = [[document contents] height];
	spp = [[document contents] spp];
	
	// Determine whether or not an alpha channel would be redundant
	for (i = 0; i < width * height && hasAlpha == NO; i++) {
		if (srcData[(i + 1) * spp - 1] != 255)
			hasAlpha = YES;
	}
	
	// Strip the alpha channel if necessary
	if (!hasAlpha) {
		spp--;
		destData = malloc(width * height * spp);
		for (i = 0; i < width * height; i++) {
			for (j = 0; j < spp; j++)
				destData[i * spp + j] = srcData[i * (spp + 1) + j];
		}
	}
	else
		destData = srcData;
	
	// Make an image representation from the data
	imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&destData pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:spp hasAlpha:hasAlpha isPlanar:NO colorSpaceName:(spp > 2) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:width * spp bitsPerPixel:8 * spp];
	imageData = [imageRep representationUsingType:NSPNGFileType properties:@{}];
		
	// Save our file and let's go
	BOOL success = [imageData writeToURL:path options:NSDataWritingAtomic error:outError];
	
	// If the destination data is not equivalent to the source data free the former
	if (destData != srcData)
		free(destData);
	
	return success;
}

@end
