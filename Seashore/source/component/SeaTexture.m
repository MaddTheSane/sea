#import "SeaTexture.h"

@implementation SeaTexture
@synthesize name;
@synthesize width;
@synthesize height;

- (instancetype)initWithContentsOfFile:(NSString *)path
{
	if (self = [super init]) {
	unsigned char *tempBitmap;
	NSBitmapImageRep *tempBitmapRep;
	BOOL isDir;
	
	// Check if file is a directory
	if ([gFileManager fileExistsAtPath:path isDirectory:&isDir] && isDir) {
		return NULL;
	}
	
	// Get the image
	tempBitmapRep = [NSBitmapImageRep imageRepWithData:[NSData dataWithContentsOfFile:path]];
	width = (int)[tempBitmapRep pixelsWide];
	height = (int)[tempBitmapRep pixelsHigh];
	NSInteger spp = [tempBitmapRep samplesPerPixel];
	NSInteger bpr = [tempBitmapRep bytesPerRow];
	tempBitmap = [tempBitmapRep bitmapData];
	
	// Check the bps
	if ([tempBitmapRep bitsPerSample] != 8) {
		NSLog(@"Texture \"%@\" failed to load\n", [path lastPathComponent]);
		return NULL;
	}
	
	// Allocate space for the greyscale and color textures
	colorTexture = malloc(width * height * 3);
	greyTexture = malloc(width * height);
	
	// Copy in the data
	if ((spp == 3 || spp == 4) && ([[tempBitmapRep colorSpaceName] isEqualTo:NSCalibratedRGBColorSpace] || [[tempBitmapRep colorSpaceName] isEqualTo:NSDeviceRGBColorSpace])) {
		
		for (int j = 0; j < height; j++) {
			if (spp == 3)
				memcpy(&(colorTexture[j * width * 3]), &(tempBitmap[j * bpr]), width * 3);
			else {
				for (int k = 0; k < width; k++) {
					for (int l = 0; l < spp - 1; l++)
						colorTexture[k * 3 + l] = tempBitmap[j * bpr + k * 4 + l];
				}
			}
		}
		
		for (int k = 0; k < width * height; k++) {
			greyTexture[k] = (unsigned char)(((int)(colorTexture[k * 3]) + (int)(colorTexture[k * 3 + 1]) + (int)(colorTexture[k * 3 + 2])) / 3);
		}
		
	} else if ((spp == 1 || spp == 2) && ([[tempBitmapRep colorSpaceName] isEqualTo:NSCalibratedWhiteColorSpace] || [[tempBitmapRep colorSpaceName] isEqualTo:NSDeviceWhiteColorSpace])) {
		
		for (int j = 0; j < height; j++) {
			if (spp == 1) {
				memcpy(&(greyTexture[j * width]), &(tempBitmap[j * bpr]), width);
			} else {
				for (int k = 0; k < width * height; k++) {
					greyTexture[k] = tempBitmap[j * bpr + k * 2];
				}
			}
		}
		
		for (int k = 0; k < width * height; k++) {
			colorTexture[k * 3] = greyTexture[k];
			colorTexture[k * 3 + 1] = greyTexture[k];
			colorTexture[k * 3 + 2] = greyTexture[k];
		}
		
	} else {
		NSLog(@"Texture \"%@\" failed to load\n", [path lastPathComponent]);
		return NULL;
	}
	
	// Remember the texture name
	name = [[path lastPathComponent] stringByDeletingPathExtension];
	}
	
	return self;
}

- (void)dealloc
{
	if (colorTexture) free(colorTexture);
	if (greyTexture) free(greyTexture);
}

- (void)activate
{
}

- (void)deactivate
{
}

- (NSImage *)thumbnail
{
	NSBitmapImageRep *tempRep;
	int thumbWidth, thumbHeight;
	NSImage *thumbnail;
	
	// Determine the thumbnail size
	thumbWidth = width;
	thumbHeight = height;
	if (width > 44 || height > 44) {
		if (width > height) {
			thumbHeight = (int)((CGFloat)height * (44.0 / (CGFloat)width));
			thumbWidth = 44;
		}
		else {
			thumbWidth = (int)((CGFloat)width * (44.0 / (CGFloat)height));
			thumbHeight = 44;
		}
	}
	
	// Create the representation
	tempRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&colorTexture pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:3 hasAlpha:NO isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:width * 3 bitsPerPixel:8 * 3];

	// Wrap it up in an NSImage
	thumbnail = [[NSImage alloc] initWithSize:NSMakeSize(thumbWidth, thumbHeight)];
	[thumbnail addRepresentation:tempRep];
	
	return thumbnail;
}

- (unsigned char *)texture:(BOOL)color
{
	return (color) ? colorTexture : greyTexture;
}

- (NSColor *)textureAsNSColor:(BOOL)color
{
	NSColor *nsColor;
	NSImage *image;
	NSBitmapImageRep *rep;
	
	image = [[NSImage alloc] initWithSize:NSMakeSize(width, height)];
	
	if (color)
		rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&colorTexture pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:3 hasAlpha:NO isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:width * 3 bitsPerPixel:24];
	else
		rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&greyTexture pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:1 hasAlpha:NO isPlanar:NO colorSpaceName:NSDeviceWhiteColorSpace bytesPerRow:width bitsPerPixel:8];
	
	[image addRepresentation:rep];
	
	nsColor = [NSColor colorWithPatternImage:image];
	
	return nsColor;
}

- (NSComparisonResult)compare:(SeaTexture*)other
{
	return [[self name] caseInsensitiveCompare:[other name]];
}

@end
