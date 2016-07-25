#import "SeaBrush.h"
#import "Bitmap.h"

typedef struct {
  unsigned int   header_size;  /*  header_size = sizeof (BrushHeader) + brush name  */
  unsigned int   version;      /*  brush file version #  */
  unsigned int   width;        /*  width of brush  */
  unsigned int   height;       /*  height of brush  */
  unsigned int   bytes;        /*  depth of brush in bytes */
  unsigned int   magic_number; /*  GIMP brush magic number  */
  unsigned int   spacing;      /*  brush spacing  */
} BrushHeader;

#define GBRUSH_MAGIC    (('G' << 24) + ('I' << 16) + ('M' << 8) + ('P' << 0))

//TODO: Anti-aliasing for pixmap brushes?

extern void determineBrushMask(unsigned char *input, unsigned char *output, int width, int height, int index1, int index2);

@implementation SeaBrush
@synthesize usePixmap;
@synthesize name;
@synthesize spacing;
@synthesize width;
@synthesize height;
@synthesize mask;
@synthesize pixmap;

- (instancetype)initWithContentsOfFile:(NSString *)path
{
	if (self = [super init]) {
	FILE *file;
	BrushHeader header;
	BOOL versionGood = NO;
	char nameString[512];
	int nameLen, tempSize;
	
	// Open the brush file
	file = fopen([path fileSystemRepresentation] ,"rb");
	if (file == NULL) {
		NSLog(@"Brush \"%@\" failed to load\n", [path lastPathComponent]);
		return NULL;
	}
	
	// Read in the header
	fread(&header, sizeof(BrushHeader), 1, file);
	
	// Convert brush header to proper endianess
#ifdef __LITTLE_ENDIAN__
	header.header_size = CFSwapInt32BigToHost(header.header_size);
	header.version = CFSwapInt32BigToHost(header.version);
	header.width = CFSwapInt32BigToHost(header.width);
	header.height = CFSwapInt32BigToHost(header.height);
	header.bytes = CFSwapInt32BigToHost(header.bytes);
	header.magic_number = CFSwapInt32BigToHost(header.magic_number);
	header.spacing = CFSwapInt32BigToHost(header.spacing);
#endif

	// Check version compatibility
	versionGood = (header.version == 2 && header.magic_number == GBRUSH_MAGIC);
	versionGood = versionGood || (header.version == 1); 
	if (!versionGood) {
		NSLog(@"Brush \"%@\" failed to load\n", [path lastPathComponent]);
		return NULL;
	}
	
	// Accomodate version 1 brushes (no spacing)
	if (header.version == 1) {
		fseek(file, -8, SEEK_CUR);
		header.header_size += 8;
		header.spacing = 25;
	}
	
	// Store information from the header
	width = header.width;
	height = header.height;
	spacing = header.spacing;
	
	// Read in brush name
	nameLen = header.header_size - sizeof(header);
	if (nameLen > 512) {
		return nil;
	}
	if (nameLen > 0) {
		fread(nameString, sizeof(char), nameLen, file);
		name = [[NSString alloc] initWithUTF8String:nameString];
	}
	else {
		name = [[NSString alloc] initWithString:LOCALSTR(@"untitled", @"Untitled")];
	}
	
	// And then read in the important stuff
	switch (header.bytes) {
		case 1:
			usePixmap = NO;
			tempSize = width * height;
			mask = malloc(make_128(tempSize));
			if (fread(mask, sizeof(char), tempSize, file) < tempSize) {
				NSLog(@"Brush \"%@\" failed to load\n", [path lastPathComponent]);
				return NULL;
			}
			break;
			
		case 4:
			usePixmap = YES;
			tempSize = width * height * 4;
			pixmap = malloc(make_128(tempSize));
			if (fread(pixmap, sizeof(char), tempSize, file) < tempSize) {
				NSLog(@"Brush \"%@\" failed to load\n", [path lastPathComponent]);
				return nil;
			}
			prePixmap = malloc(tempSize);
			premultiplyBitmap(4, prePixmap, pixmap, width * height);
			break;
			
		default:
			NSLog(@"Brush \"%@\" failed to load\n", [path lastPathComponent]);
			return nil;
			break;
	}

	// Close the brush file
	fclose(file);
	}
	
	return self;
}

- (void)dealloc
{
	int i;
	
	if (maskCache) {
		for (i = 0; i < kBrushCacheSize; i++) {
			if (maskCache[i].cache)
				free(maskCache[i].cache);
		}
		free(maskCache);
	}
	if (scaled)
		free(scaled);
	if (positioned)
		free(positioned);
	if (mask)
		free(mask);
	if (pixmap)
		free(pixmap);
	if (prePixmap)
		free(prePixmap);
}

- (void)activate
{
	// Deactivate ourselves first (just in case)
	[self deactivate];
	
	// Reset the cache
	checkCount = 0;
	maskCache = malloc(sizeof(CachedMask) * kBrushCacheSize);
	for (int i = 0; i < kBrushCacheSize; i++) {
		maskCache[i].cache = malloc(make_128((width + 2) * (height + 2)));
		maskCache[i].index1 = maskCache[i].index2 = maskCache[i].scale = -1;
		maskCache[i].lastCheck = 0;
	}
	scaled = malloc(make_128(width * height));
	positioned = malloc(make_128(width * height));
}

- (void)deactivate
{
	// Free the cache
	if (maskCache) {
		for (int i = 0; i < kBrushCacheSize; i++) {
			if (maskCache[i].cache) free(maskCache[i].cache);
			maskCache[i].cache = NULL;
		}
		free(maskCache);
		maskCache = NULL;
	}
	if (scaled) {
		free(scaled);
		scaled = NULL;
	}
	if (positioned) {
		free(positioned);
		positioned = NULL;
	}
}

- (NSString *)pixelTag
{
	unichar tchar;
	int i, start, end;
	BOOL canCut = NO;
	
	if (width > 40 || height > 40) {
		start = end = -1;
		for (i = 0; i < [name length]; i++) {
			tchar = [name characterAtIndex:i];
			if (tchar == '(') { 
				start = i + 1;
				canCut = YES;
			}
			else if (canCut) {
				if (tchar == '0')
					start = i + 1;
				else
					canCut = NO;
			}
			if (tchar == ')') end = i;
		}
		if (start != -1 && end != -1) {
			return [name substringWithRange:NSMakeRange(start, end - start)];
		}
	}
	
	return nil;
}

- (NSImage *)thumbnail
{
	NSBitmapImageRep *tempRep;
	int thumbWidth, thumbHeight;
	NSImage *thumbnail;
	
	// Determine the thumbnail size
	thumbWidth = width;
	thumbHeight = height;
	if (width > 40 || height > 40) {
		if (width > height) {
			thumbHeight = (int)((CGFloat)height * (40.0 / (CGFloat)width));
			thumbWidth = 40;
		} else {
			thumbWidth = (int)((CGFloat)width * (40.0 / (CGFloat)height));
			thumbHeight = 40;
		}
	}
	
	// Create the representation
	if (usePixmap) {
		tempRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&prePixmap pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:width * 4 bitsPerPixel:8 * 4];
	} else {
		tempRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&mask pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:1 hasAlpha:NO isPlanar:NO colorSpaceName:NSDeviceBlackColorSpace bytesPerRow:width * 1 bitsPerPixel:8 * 1];
	}
	
	// Wrap it up in an NSImage
	thumbnail = [[NSImage alloc] initWithSize:NSMakeSize(thumbWidth, thumbHeight)];
	[thumbnail addRepresentation:tempRep];
	
	return thumbnail;
}

- (int)fakeWidth
{
	return usePixmap ? width : width + 2;
}

- (int)fakeHeight
{
	return usePixmap ? height : height + 2;
}

- (unsigned char *)maskForPoint:(NSPoint)point pressure:(int)value
{
	float remainder, factor, xextra, yextra;
	int i, index1, index2, scale, scalew, scaleh, minCheckPos;
	
	// Determine the scale
	factor = (0.30 * ((float)value / 255.0) + 0.70);
	if (width >= height) {
		scale = factor * width;
	}
	else {
		scale = factor * height;
	}
	scalew = factor * width;
	scaleh = factor * height;
	if ((scalew % 2 == 1 && width % 2 == 0) || (scalew % 2 == 0 && width % 2 == 1)) xextra = 1;
	else xextra = 0;
	if ((scaleh % 2 == 1 && height % 2 == 0) || (scaleh % 2 == 0 && height % 2 == 1)) yextra = 1;
	else yextra = 0;
	 
	// Determine the horizontal shift
	remainder = (point.x + xextra) - floor (point.x + xextra);
	index1 = (int)(remainder * (float)(kSubsampleLevel + 1));
	
	// Determine the vertical shift
	remainder = (point.y + yextra) - floor (point.y + yextra);
	index2 = (int)(remainder * (float)(kSubsampleLevel + 1));

	 // Increment the checkCount
	 checkCount++;
	 minCheckPos = 0;
	 
	// Check for existing brushes
	for (i = 0; i < kBrushCacheSize; i++) {
		if (maskCache[i].index1 == index1) {
			if (maskCache[i].index2 == index2) {
				if (maskCache[i].scale == scale) {
					maskCache[i].lastCheck = checkCount;
					return maskCache[i].cache;
				}
			}
		}
		if (maskCache[minCheckPos].lastCheck < maskCache[i].lastCheck) {
			minCheckPos = i;
		}
	}
	
	// Determine the mask
	if ((width >= height && scale != width) || (height > width && scale != height)) {
		GCScalePixels(scaled, scalew, scaleh,  mask, width, height, GIMP_INTERPOLATION_LINEAR, 1);
		arrangePixels(positioned, width, height, scaled, scalew, scaleh);
		determineBrushMask(positioned, maskCache[minCheckPos].cache, width, height, index1, index2);
	}
	else {
		determineBrushMask(mask, maskCache[minCheckPos].cache, width, height, index1, index2);
	}
	maskCache[minCheckPos].index1 = index1;
	maskCache[minCheckPos].index2 = index2;
	maskCache[minCheckPos].scale = scale;
	maskCache[minCheckPos].lastCheck = checkCount;
	
	return maskCache[minCheckPos].cache;
}

- (unsigned char *)pixmapForPoint:(NSPoint)point
{
	return pixmap;
}

- (NSComparisonResult)compare:(SeaBrush*)other
{
	return [[self name] caseInsensitiveCompare:[other name]];
}

@end
