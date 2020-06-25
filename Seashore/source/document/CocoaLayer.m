#import "SeaDocument.h"
#import "SeaContent.h"
#import "CocoaLayer.h"
#import "CocoaContent.h"
#import "Bitmap.h"

@implementation CocoaLayer

- (instancetype)initWithImageRep:(NSBitmapImageRep *)imageRep document:(SeaDocument*)doc spp:(int)lspp
{
	ColorSyncProfileRef cmProfileLoc = NULL;
	
	// Initialize superclass first
	if (![super initWithDocument:doc])
		return nil;
	
	// Fill out variables
	NSInteger bps = [imageRep bitsPerSample];
	NSInteger sspp = [imageRep samplesPerPixel];
	unsigned char *srcPtr = [imageRep bitmapData];
	NSBitmapFormat format = [imageRep bitmapFormat];
	
	// Determine the width and height of this layer
	width = (int)[imageRep pixelsWide];
	height = (int)[imageRep pixelsHigh];
	
	// Determine samples per pixel
	spp = lspp;

	// Determine the color space
	BMPColorSpace space = -1;
	if ([[imageRep colorSpaceName] isEqualToString:NSCalibratedWhiteColorSpace] || [[imageRep colorSpaceName] isEqualToString:NSDeviceWhiteColorSpace])
		space = BMPColorSpaceGray;
	if ([[imageRep colorSpaceName] isEqualToString:NSCalibratedRGBColorSpace] || [[imageRep colorSpaceName] isEqualToString:NSDeviceRGBColorSpace])
		space = BMPColorSpaceRGB;
	if ([[imageRep colorSpaceName] isEqualToString:NSDeviceCMYKColorSpace])
		space = BMPColorSpaceCMYK;
	if (space == -1) {
		NSLog(@"Color space %@ not yet handled.", [imageRep colorSpaceName]);
		return nil;
	}
	
	// Extract color profile
	NSData *profile = [imageRep valueForProperty:NSImageColorSyncProfileData];
	if (profile && [profile isKindOfClass:[NSData class]]) {
		cmProfileLoc = ColorSyncProfileCreate((__bridge CFDataRef)(profile), NULL);
	}
	
	// Convert data to what we want
	NSInteger bipp = [imageRep bitsPerPixel];
	NSInteger bypr = [imageRep bytesPerRow];
	data = SeaConvertBitmap(spp, (spp == 4) ? BMPColorSpaceRGB : BMPColorSpaceGray, 8, srcPtr, width, height, sspp, bipp, bypr, space, cmProfileLoc, bps, (GIMPBitmapFormat)format);
	if (cmProfileLoc) {
		CFRelease(cmProfileLoc);
	}
	if (!data) {
		NSLog(@"Required conversion not supported.");
		return nil;
	}
	
	// Check the alpha
	hasAlpha = NO;
	for (int i = 0; i < width * height; i++) {
		if (data[(i + 1) * spp - 1] != 255)
			hasAlpha = YES;
	}
	
	// Unpremultiply the image if required
	if (hasAlpha && !(format & NSAlphaNonpremultipliedBitmapFormat)) {
		SeaUnpremultiplyBitmap(spp, data, data, width * height);
	}
		
	return self;
}

@end
