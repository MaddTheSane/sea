#import "SeaLayer.h"
#import "SeaContent.h"
#if MAIN_COMPILE
#import "SeaDocument.h"
#import "SeaLayerUndo.h"
#import "SeaController.h"
#import "UtilitiesManager.h"
#import "PegasusUtility.h"
#endif
#import "Bitmap.h"
#if MAIN_COMPILE
#import "SeaWarning.h"
#import "SeaPrefs.h"
#import "SeaPlugins.h"
#import "CIAffineTransformClass.h"
#endif
#include <ApplicationServices/ApplicationServices.h>
#include <sys/stat.h>
#include <sys/mount.h>
#if MAIN_COMPILE
#include <GIMPCore/GIMPCore.h>
#endif
#include <tgmath.h>

@implementation SeaLayer
@synthesize xOffset = xoff;
@synthesize yOffset = yoff;
@synthesize width;
@synthesize height;
@synthesize uniqueLayerID;

#if MAIN_COMPILE
- (instancetype)initWithDocument:(SeaDocument *)doc
{	
	// Set the data members to reasonable values
	if (self = [super init]) {
		opacity = 255;
		spp = 4; visible = YES;
		hasAlpha = YES;
		lostprops = NULL;
		document = doc;
		seaLayerUndo = [[SeaLayerUndo alloc] initWithDocument:doc forLayer:self];
		uniqueLayerID = [doc uniqueLayerID];
		if (uniqueLayerID == 0)
			name = [[NSString alloc] initWithString:LOCALSTR(@"background layer", @"Background")];
		else
			name = [[NSString alloc] initWithFormat:LOCALSTR(@"layer title", @"Layer %d"), uniqueLayerID];
		oldNames = [[NSArray alloc] init];
		undoFilePath = [[NSString alloc] initWithFormat:@"/tmp/seaundo-d%d-l%d", [document uniqueDocID], [self uniqueLayerID]];
		affinePlugin = [[SeaController seaPlugins] affinePlugin];
	}
	return self;
}

-  (instancetype)initWithDocument:(SeaDocument*)doc width:(int)lwidth height:(int)lheight opaque:(BOOL)opaque spp:(int)lspp;
{
	// Call the core initializer
	if (![self initWithDocument:doc])
		return nil;
	
	// Extract appropriate values of master
	width = lwidth; height = lheight;
	
	// Get the appropriate samples per pixel
	spp = lspp;
	
	// Create a representation in memory of the blank canvas
	data = malloc(make_128(width * height * spp));
	if (opaque)
		memset(data, 255, width * height * spp);
	else
		memset(data, 0, width * height * spp);
	
	// Remember the alpha situation
	hasAlpha = !opaque;
		
	return self;
}

- (instancetype)initWithDocument:(SeaDocument*)doc rect:(IntRect)lrect data:(unsigned char *)ldata spp:(int)lspp
{
	// Call the core initializer
	if (![self initWithDocument:doc])
		return nil;
	
	// Derive the width and height from the imageRep
	xoff = lrect.origin.x; yoff = lrect.origin.y;
	width = lrect.size.width; height = lrect.size.height;
	
	// Get the appropriate samples per pixel
	spp = lspp;
	
	// Copy over the bitmap data
	data = malloc(make_128(width * height * spp));
	memcpy(data, ldata, width * height * spp);

	// We should always have an alpha layer unless you turn it off
	hasAlpha = YES;
	
	return self;
}

- (instancetype)initWithDocument:(SeaDocument*)doc layer:(SeaLayer*)layer
{
	// Call the core initializer
	if (![self initWithDocument:doc])
		return nil;
		
	// Synchronize properties
	width = [layer width];
	height = [layer height];
	mode = [layer mode];
	spp = [[[layer document] contents] spp];
	data = malloc(make_128(width * height * spp));
	data = memcpy(data, [layer data], width * height * spp);
	xoff = [layer xoff];
	yoff = [layer yoff];
	visible = [layer isVisible];
	opacity = [layer opacity];
	name = [NSString stringWithString:[layer name]];
	
	// Assume we always have alpha
	hasAlpha = YES;
	
	// Finally convert the bitmap to the correct type
	[self convertFromType:[(SeaContent *)[[layer document] contents] type] to:[(SeaContent *)[document contents] type]];
	
	return self;
}

- (instancetype)initFloatingWithDocument:(SeaDocument*)doc rect:(IntRect)lrect data:(unsigned char *)ldata
{
	if (self = [self initWithDocument:doc]) {
		// Set the offsets, height and width
		xoff = lrect.origin.x;
		yoff = lrect.origin.y;
		width = lrect.size.width;
		height = lrect.size.height;
		
		// Set the other variables according to the arguments
		document = doc;
		data = ldata;
		
		// And then make some sensible choices for the other variables
		mode = 0;
		opacity = 255;
		spp = [[document contents] spp];
		visible = YES;
		hasAlpha = YES;
		compressed = NO;
		thumbnail = NULL; thumbData = NULL;
		floating = YES;
		affinePlugin = [[SeaController seaPlugins] affinePlugin];
		
		// Setup for undoing
		seaLayerUndo = [[SeaLayerUndo alloc] initWithDocument:doc forLayer:self];
		uniqueLayerID = [(SeaDocument *)doc uniqueFloatingLayerID];
		name = NULL; oldNames = NULL;
		undoFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"seaundo-d%d-l%d", [self uniqueLayerID], [document uniqueDocID]]];
	}
	return self;
}

#else

- (instancetype)init
{
	if (self = [super init]) {
		// Set the data members to reasonable values
		height = width = mode = 0;
		opacity = 255; xoff = yoff = 0;
		spp = 4;
		srand(time(NULL) & 0x7FFFFFFF);
		
		uniqueLayerID = rand();
		if (uniqueLayerID == 0)
			name = [[NSString alloc] initWithString:LOCALSTR(@"background layer", @"Background")];
		else
			name = [[NSString alloc] initWithFormat:LOCALSTR(@"layer title", @"Layer %d"), uniqueLayerID];
		oldNames = [[NSArray alloc] init];
	}
	
	return self;
}

#endif

- (void)dealloc
{
	if (data) free(data);
	if (thumbData) free(thumbData);
#if MAIN_COMPILE
	struct stat sb;
	if (data == NULL) {
		if (stat([undoFilePath fileSystemRepresentation], &sb) == 0) {
			unlink([undoFilePath fileSystemRepresentation]);
		}
	}
#endif
}

#if MAIN_COMPILE
- (void)compress
{
	FILE *file;
	
	// If the image data is not already compressed
	if (data) {
		
		// Do a check of the disk space
		if ([seaLayerUndo checkDiskSpace]) {
			
			// Open a file for writing the memory cache
			file = fopen([undoFilePath fileSystemRepresentation], "w");
			
			// Check we have a valid file handle
			if (file != NULL) {
				
				// Write the image data to disk
				fwrite(data, sizeof(char), width * height * spp, file);
				
				// Close the memory cache
				fclose(file);
				
				// Free the memory currently occupied the document's data
				free(data);
				data = NULL;
				
			}

			// Get rid of the thumbnail
			if (thumbData) free(thumbData);
			thumbnail = NULL; thumbData = NULL;
		}
	}
}

- (void)decompress
{
	FILE *file;

	// If the image data is not already decompressed
	if (data == NULL) {
		
		// Create space for the decompressed image data
		data = malloc(make_128(width * height * spp));
		
		// Open a file for writing the image data
		file = fopen([undoFilePath fileSystemRepresentation], "r");
		
		// Check we have a valid file handle
		if (file != NULL) {
			
			// Write the image data to disk
			fread(data, sizeof(char), width * height * spp, file);
			
			// Close the file
			fclose(file);
			
			// Delete the file (we have its contents in memory now)
			unlink([undoFilePath fileSystemRepresentation]);
		}
	}
}

- (id)document
{
	return document;
}
#endif

#if MAIN_COMPILE
- (IntRect)localRect
{
	return IntMakeRect(xoff, yoff, width, height);
}

- (void)setOffsets:(IntPoint)newOffsets
{
	xoff = newOffsets.x;
	yoff = newOffsets.y;
}

- (void)trimLayer
{
	int left, right, top, bottom;
	
	// Start out with invalid content borders
	left = right = top = bottom =  -1;
	
	// Determine left content margin
	for (int i = 0; i < width && left == -1; i++) {
		for (int j = 0; j < height && left == -1; j++) {
			if (data[j * width * spp + i * spp + (spp - 1)] != 0) {
				left = i;
			}
		}
	}
	
	// Determine right content margin
	for (int i = width - 1; i >= 0 && right == -1; i--) {
		for (int j = 0; j < height && right == -1; j++) {
			if (data[j * width * spp + i * spp + (spp - 1)] != 0) {
				right = width - 1 - i;
			}
		}
	}
	
	// Determine top content margin
	for (int j = 0; j < height && top == -1; j++) {
		for (int i = 0; i < width && top == -1; i++) {
			if (data[j * width * spp + i * spp + (spp - 1)] != 0) {
				top = j;
			}
		}
	}
	
	// Determine bottom content margin
	for (int j = height - 1; j >= 0 && bottom == -1; j--) {
		for (int i = 0; i < width && bottom == -1; i++) {
			if (data[j * width * spp + i * spp + (spp - 1)] != 0) {
				bottom = height - 1 - j;
			}
		}
	}
	
	// Make the change
	if (left != 0 || top != 0 || right != 0 || bottom != 0)
		[self setMarginLeft:-left top:-top right:-right bottom:-bottom];
}

- (void)flipHorizontally
{
	unsigned char temp[4];
	
	for (int j = 0; j < height; j++) {
		for (int i = 0; i < width / 2; i++) {
			memcpy(temp, &(data[(j * width + i) * spp]), spp);
			memcpy(&(data[(j * width + i) * spp]), &(data[(j * width + (width - i - 1)) * spp]), spp);
			memcpy(&(data[(j * width + (width - i - 1)) * spp]), temp, spp);
		}
	}
	
	xoff = [(SeaContent *)[document contents] width] - xoff - width;
}

- (void)flipVertically
{
	unsigned char temp[4];
	
	for (int j = 0; j < height / 2; j++) {
		for (int i = 0; i < width; i++) {
			memcpy(temp, &(data[(j * width + i) * spp]), spp);
			memcpy(&(data[(j * width + i) * spp]), &(data[((height - j - 1) * width + i) * spp]), spp);
			memcpy(&(data[((height - j - 1) * width + i) * spp]), temp, spp);
		}
	}
	
	yoff = [(SeaContent *)[document contents] height] - yoff - height;
}

- (void)rotateLeft
{
	int newWidth = height;
	int newHeight = width;
	unsigned char *newData = malloc(make_128(newWidth * newHeight * spp));
	
	for (int j = 0; j < height; j++) {
		for (int i = 0; i < width; i++) {
			for (int k = 0; k < spp; k++) {
				newData[((newHeight - i - 1) * newWidth + j) * spp + k] = data[(j * width + i) * spp + k]; 
			}
		}
	}
	free(data);
	
	int ox = [(SeaContent *)[document contents] width] - xoff - width;
	int oy = yoff;
	
	width = newWidth;
	height = newHeight;
	data = newData;
	
	xoff = oy;
	yoff = ox;
}

- (void)rotateRight
{
	int newWidth = height;
	int newHeight = width;
	unsigned char *newData = malloc(make_128(newWidth * newHeight * spp));
	
	for (int j = 0; j < height; j++) {
		for (int i = 0; i < width; i++) {
			for (int k = 0; k < spp; k++) {
				newData[(i * newWidth + (newWidth - j - 1)) * spp + k] = data[(j * width + i) * spp + k]; 
			}
		}
	}
	free(data);
	
	int ox = xoff;
	int oy = [(SeaContent *)[document contents] height] - yoff - height;
	
	width = newWidth;
	height = newHeight;
	data = newData;
	
	xoff = oy;
	yoff = ox;
}

- (void)setCocoaRotation:(CGFloat)degrees interpolation:(NSImageInterpolation)interpolation withTrim:(BOOL)trim
{
	NSAffineTransform *at, *tat;
	unsigned char *srcData;
	NSImage *image_out;
	NSBitmapImageRep *in_rep, *final_rep;
	NSPoint point[4], minPoint, maxPoint, transformPoint;
	int i, oldHeight, oldWidth;
	NSInteger ispp, bipp, bypr, ibps;
	
	// Define the rotation
	at = [NSAffineTransform transform];
	[at rotateByDegrees:degrees];
	
	// Determine the input image
	SeaPremultiplyBitmap(spp, data, data, width * height);
	in_rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&data pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:spp hasAlpha:YES isPlanar:NO colorSpaceName:(spp == 4) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:width * spp bitsPerPixel:8 * spp];

	// Determine the output size
	point[0] = [at transformPoint:NSMakePoint(0.0, 0.0)];
	point[1] = [at transformPoint:NSMakePoint(width, 0.0)];
	point[2] = [at transformPoint:NSMakePoint(0.0, height)];
	point[3] = [at transformPoint:NSMakePoint(width, height)];
	minPoint = point[0];
	for (i = 0; i < 4; i++) {
		if (point[i].x < minPoint.x)
			minPoint.x = point[i].x;
		if (point[i].y < minPoint.y)
			minPoint.y = point[i].y;
	}
	maxPoint = point[0];
	for (i = 0; i < 4; i++) {
		if (point[i].x > maxPoint.x)
			maxPoint.x = point[i].x;
		if (point[i].y > maxPoint.y)
			maxPoint.y = point[i].y;
	}
	oldWidth = width;
	oldHeight = height;
	width = ceilf(maxPoint.x - minPoint.x);
	height = ceilf(maxPoint.y - minPoint.y);
	xoff += oldWidth / 2 - width / 2;
	yoff += oldHeight / 2 - height / 2;
	
	// Determine the output image
	image_out = [[NSImage alloc] initWithSize:NSMakeSize(width, height)];
	[image_out recache];
	[image_out lockFocus];
	
	// Work out full transform
	tat = [NSAffineTransform transform];
	transformPoint.x = -minPoint.x;
	transformPoint.y = -minPoint.y;
	[tat translateXBy:transformPoint.x yBy:transformPoint.y];
	[at appendTransform:tat];
	
	[[NSGraphicsContext currentContext] setImageInterpolation:interpolation];
	[[NSAffineTransform transform] set];
	[[NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, width, height)] setClip];
	[at set];
	[in_rep drawAtPoint:NSMakePoint(0.0, 0.0)];
	[[NSAffineTransform transform] set];
	final_rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0.0, 0.0, width, height)];
	[image_out unlockFocus];
	
	// Start clean up
	free(data);
	
	// Make the swap
	srcData = [final_rep bitmapData];
	ispp = [final_rep samplesPerPixel];
	bipp = [final_rep bitsPerPixel];
	bypr = [final_rep bytesPerRow];
	BMPColorSpace ispace = (ispp > 2) ? kRGBColorSpace : kGrayColorSpace;
	ibps = [final_rep bitsPerPixel] / [final_rep samplesPerPixel];
	data = SeaConvertBitmap(spp, (spp == 4) ? kRGBColorSpace : kGrayColorSpace, 8, srcData, width, height, ispp, bipp, bypr, ispace, NULL, ibps, 0);
	
	// Clean up
	SeaUnpremultiplyBitmap(spp, data, data, width * height);
		
	// Make margin changes
	if (trim) [self trimLayer];
}

- (void)setCoreImageRotation:(CGFloat)degrees interpolation:(NSImageInterpolation)interpolation withTrim:(BOOL)trim
{
	unsigned char *newData;
	NSAffineTransform *at;
	int newWidth, newHeight, i;
	NSPoint point[4], minPoint, maxPoint;

	// Determine affine transform
	at = [NSAffineTransform transform];
	[at rotateByDegrees:degrees];
	
	// Determine the output size
	point[0] = [at transformPoint:NSMakePoint(0.0, 0.0)];
	point[1] = [at transformPoint:NSMakePoint(width, 0.0)];
	point[2] = [at transformPoint:NSMakePoint(0.0, height)];
	point[3] = [at transformPoint:NSMakePoint(width, height)];
	minPoint = point[0];
	for (i = 0; i < 4; i++) {
		if (point[i].x < minPoint.x)
			minPoint.x = point[i].x;
		if (point[i].y < minPoint.y)
			minPoint.y = point[i].y;
	}
	maxPoint = point[0];
	for (i = 0; i < 4; i++) {
		if (point[i].x > maxPoint.x)
			maxPoint.x = point[i].x;
		if (point[i].y > maxPoint.y)
			maxPoint.y = point[i].y;
	}
	newWidth = ceil(maxPoint.x - minPoint.x);
	newHeight = ceil(maxPoint.y - minPoint.y);
	
	// Run the transform
	newData = [affinePlugin runAffineTransform:at withImage:data spp:spp width:width height:height opaque:NO newWidth:&newWidth newHeight:&newHeight];
	
	// Replace the old bitmap with the new bitmap
	free(data);
	data = newData;
	xoff += width / 2 - newWidth / 2;
	yoff += height / 2 - newHeight / 2;
	width = newWidth; height = newHeight;
	
	// Destroy the thumbnail data
	if (thumbData) free(thumbData);
	thumbnail = NULL; thumbData = NULL;
	
	// Make margin changes
	if (trim) [self trimLayer];
}


- (void)setRotation:(CGFloat)degrees interpolation:(NSImageInterpolation)interpolation withTrim:(BOOL)trim
{
	if (affinePlugin && [[SeaController seaPrefs] useCoreImage]) {
		[self setCoreImageRotation:degrees interpolation:interpolation withTrim:trim];
	}
	else {
		[self setCocoaRotation:degrees interpolation:interpolation withTrim:trim];
	}
}
#endif

@synthesize visible;
@synthesize linked;
@synthesize opacity;
@synthesize mode;
@synthesize name;

#if MAIN_COMPILE
- (void)setName:(NSString *)newName
{
	if (name) {
		oldNames = [oldNames arrayByAddingObject:name];
		name = [newName copy];
	}
}
#endif

@synthesize data;
@synthesize hasAlpha;

#if MAIN_COMPILE
- (void)toggleAlpha
{
	// Do nothing if we can't do anything
	if (![self canToggleAlpha])
		return;
	
	// Change the alpha channel treatment
	hasAlpha = !hasAlpha;
	
	// Update the Pegasus utility
	[(PegasusUtility *)[[SeaController utilitiesManager] pegasusUtilityFor:document] update:kPegasusUpdateAll]; 

	// Make action undoable
	[[[document undoManager] prepareWithInvocationTarget:self] toggleAlpha];
}
#endif

- (void)introduceAlpha
{
	hasAlpha = YES;
}

#if MAIN_COMPILE
- (BOOL)canToggleAlpha
{
	int i;
	
	if (floating)
		return NO;
	
	if (hasAlpha) {
		for (i = 0; i < width * height; i++) {
			if (data[(i + 1) * spp - 1] != 255)
				return NO;
		}
	}
	
	return YES;
}
#endif

- (char *)lostprops
{
	return lostprops;
}

- (int)lostprops_len
{
	return lostprops_len;
}


#if MAIN_COMPILE
- (int)index
{
	int i;
	
	for (i = 0; i < [[document contents] layerCount]; i++) {
		if ([[document contents] layerAtIndex:i] == self)
			return i;
	}
	
	return -1;
}
#endif

@synthesize floating;

#if MAIN_COMPILE
- (id)seaLayerUndo
{
	return seaLayerUndo;
}

- (NSImage *)thumbnail
{
	NSBitmapImageRep *tempRep;
	
	// Check if we need an update
	if (thumbData == NULL) {
		
		// Determine the size for the image
		thumbWidth = width; thumbHeight = height;
		if (width > 40 || height > 32) {
			if ((float)width / 40.0 > (float)height / 32.0) {
				thumbHeight = (int)((float)height * (40.0 / (float)width));
				thumbWidth = 40;
			}
			else {
				thumbWidth = (int)((float)width * (32.0 / (float)height));
				thumbHeight = 32;
			}
		}
		if(thumbWidth <= 0){
			thumbWidth = 1;
		}
		if(thumbHeight <= 0){
			thumbHeight = 1;
		}
		// Create the thumbnail
		thumbData = malloc(thumbWidth * thumbHeight * spp);
		
		// Determine the thumbnail data
		[self updateThumbnail];
		
	}
	
	// Create the representation
	tempRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&thumbData pixelsWide:thumbWidth pixelsHigh:thumbHeight bitsPerSample:8 samplesPerPixel:spp hasAlpha:YES isPlanar:NO colorSpaceName:(spp == 4) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:thumbWidth * spp bitsPerPixel:8 * spp];
	
	// Wrap it up in an NSImage
	thumbnail = [[NSImage alloc] initWithSize:NSMakeSize(thumbWidth, thumbHeight)];
	[thumbnail addRepresentation:tempRep];
		
	return thumbnail;
}

- (void)updateThumbnail
{
	float horizStep, vertStep;
	int i, j, k, temp;
	int srcPos, destPos;
	
	if (thumbData) {
	
		// Determine the thumbnail data
		horizStep = (float)width / (float)thumbWidth;
		vertStep = (float)height / (float)thumbHeight;
		for (j = 0; j < thumbHeight; j++) {
			for (i = 0; i < thumbWidth; i++) {
				srcPos = ((int)(j * vertStep) * width + (int)(i * horizStep)) * spp;
				destPos = (j * thumbWidth + i) * spp;
				
				if (data[srcPos + (spp - 1)] == 255) {
					for (k = 0; k < spp; k++)
						thumbData[destPos + k] = data[srcPos + k];
				}
				else if (data[srcPos + (spp - 1)] == 0) {
					for (k = 0; k < spp; k++)
						thumbData[destPos + k] = 0;
				}
				else {
					for (k = 0; k < spp - 1; k++)
						thumbData[destPos + k] = int_mult(data[srcPos + k], data[srcPos + (spp - 1)], temp);
					thumbData[destPos + (spp - 1)] = data[srcPos + (spp - 1)];
				}
			}
		}
		
	}
}

- (NSData *)TIFFRepresentation
{
	NSBitmapImageRep *imageRep;
	NSData *imageTIFFData;
	unsigned char *pmImageData;
	int i, j, tspp;
	
	// Allocate room for the premultiplied image data
	if (hasAlpha)
		pmImageData = malloc(width * height * spp);
	else
		pmImageData = malloc(width * height * (spp - 1));
		
	// If there is an alpha channel...
	if (hasAlpha) {
		
		// Formulate the premultiplied data from the data
		SeaPremultiplyBitmap(spp, pmImageData, data, width * height);
	
	} else {
	
		// Strip the alpha channel
		for (i = 0; i < width * height; i++) {
			for (j = 0; j < spp - 1; j++) {
				pmImageData[i * (spp - 1) + j] = data[i * spp + j];
			}
		}
		
	}
	
	// Then create the representation
	tspp = (hasAlpha ? spp : spp - 1);
	imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&pmImageData pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:tspp hasAlpha:hasAlpha isPlanar:NO colorSpaceName:(spp == 4) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:width * tspp bitsPerPixel:8 * tspp];
	
	// Work out the image data
	imageTIFFData = [imageRep TIFFRepresentationUsingCompression:NSTIFFCompressionLZW factor:255];
	
	// Release the representation and the image data
	free(pmImageData);
	
	return imageTIFFData;
}

- (void)setMarginLeft:(int)left top:(int)top right:(int)right bottom:(int)bottom
{
	unsigned char *newImageData;
	int i, j, k, destPos, srcPos, newWidth, newHeight;
	
	// Allocate an appropriate amount of memory for the new bitmap
	newWidth = width + left + right;
	newHeight = height + top + bottom;
	newImageData = malloc(make_128(newWidth * newHeight * spp));
	// do_128_clean(newImageData, make_128(newWidth * newHeight * spp));
	
	// Fill the new bitmap with the appropriate values
	for (j = 0; j < newHeight; j++) {
		for (i = 0; i < newWidth; i++) {
			
			destPos = (j * newWidth + i) * spp;
			
			if (i < left || i >= left + width || j < top || j >= top + height) {
				if (!hasAlpha) { for (k = 0; k < spp; k++) newImageData[destPos + k] = 255; }
				else { for (k = 0; k < spp; k++) newImageData[destPos + k] = 0; }
			}
			else {
				srcPos = ((j - top) * width + (i - left)) * spp;
				for (k = 0; k < spp; k++)
					newImageData[destPos + k] = data[srcPos + k];
			}
			
		}
	}
	
	// Replace the old bitmap with the new bitmap
	free(data);
	data = newImageData;
	width = newWidth; height = newHeight;
	xoff -= left; yoff -= top; 
	
	// Destroy the thumbnail data
	if (thumbData) free(thumbData);
	thumbnail = NULL; thumbData = NULL;
}


- (void)setCocoaWidth:(int)newWidth height:(int)newHeight interpolation:(int)interpolation
{
	unsigned char *newData;
		
	// Allocate an appropriate amount of memory for the new bitmap
	newData = malloc(make_128(newWidth * newHeight * spp));
	
	// Do the scale
	GCScalePixels(newData, newWidth, newHeight, data, width, height, interpolation, spp);
	
	// Replace the old bitmap with the new bitmap
	free(data);
	data = newData;
	width = newWidth; height = newHeight;
	
	// Destroy the thumbnail data
	if (thumbData) free(thumbData);
	thumbnail = NULL; thumbData = NULL;
}


- (void)setCoreImageWidth:(int)newWidth height:(int)newHeight interpolation:(int)interpolation
{
	unsigned char *newData;
	NSAffineTransform *at;
	
	// Determine affine transform
	at = [NSAffineTransform transform];
	[at scaleXBy:(CGFloat)newWidth / (CGFloat)width yBy:(CGFloat)newHeight / (CGFloat)height];
	
	// Run the transform
	newData = [affinePlugin runAffineTransform:at withImage:data spp:spp width:width height:height opaque:!hasAlpha newWidth:&newWidth newHeight:&newHeight];
	
	// Replace the old bitmap with the new bitmap
	free(data);
	data = newData;
	width = newWidth; height = newHeight;
	
	// Destroy the thumbnail data
	if (thumbData) free(thumbData);
	thumbnail = NULL; thumbData = NULL;
}


- (void)setWidth:(int)newWidth height:(int)newHeight interpolation:(GimpInterpolationType)interpolation
{
	// The issue here is it looks like we're not smart enough to pass anything
	// to the affine plugin besides cubic, so if we're not cupbic we have to use cocoa
	if (affinePlugin && [[SeaController seaPrefs] useCoreImage] && interpolation == GIMP_INTERPOLATION_CUBIC) {
		[self setCoreImageWidth:newWidth height:newHeight interpolation:interpolation];
	}
	else {
		[self setCocoaWidth:newWidth height:newHeight interpolation:interpolation];
	}
}

- (void)convertFromType:(XcfImageType)srcType to:(XcfImageType)destType
{
	unsigned char *newData, *oldData;
	int i;
	
	// Destroy the thumbnail data
	if (thumbData) free(thumbData);
	thumbnail = NULL; thumbData = NULL;

	// Don't do anything if there is nothing to do
	if (srcType == destType)
		return;
		
	if (srcType == XCF_RGB_IMAGE && destType == XCF_GRAY_IMAGE) {
		ColorSyncProfileRef srcProf, destProf;
		ColorSyncTransformRef cw;

		// Create colour world
		srcProf = ColorSyncProfileCreateWithDisplayID(0);
		destProf = ColorSyncProfileCreateWithName(kColorSyncGenericGrayProfile);
		NSArray<NSDictionary<NSString*,id>*>*
		profSeq = @[
					@{(__bridge NSString*)kColorSyncProfile: (__bridge id)srcProf,
					  (__bridge NSString*)kColorSyncRenderingIntent: (__bridge NSString*)kColorSyncRenderingIntentPerceptual,
					  (__bridge NSString*)kColorSyncTransformTag: (__bridge NSString*)kColorSyncTransformDeviceToPCS,
					  },
					
					@{(__bridge NSString*)kColorSyncProfile: (__bridge id)destProf,
					  (__bridge NSString*)kColorSyncRenderingIntent: (__bridge NSString*)kColorSyncRenderingIntentPerceptual,
					  (__bridge NSString*)kColorSyncTransformTag: (__bridge NSString*)kColorSyncTransformPCSToDevice,
					  },
					];
		cw = ColorSyncTransformCreate((__bridge CFArrayRef)(profSeq), NULL);
	
		// Define the source
		oldData = data;
		
		// Define the destination
		newData = malloc(make_128(width * height * 2));
		
		// Execute the conversion
		ColorSyncTransformConvert(cw, width, height, newData, kColorSync8BitInteger, kColorSyncByteOrderDefault | kColorSyncAlphaLast, width * 2, oldData, kColorSync8BitInteger, kColorSyncByteOrderDefault | kColorSyncAlphaLast, width * 4, NULL);

		for (i = 0; i < width * height; i++)
			newData[i * 2 + 1] = oldData[i * 4 + 3];
		data = newData;
		free(oldData);
		spp = 2;
		
		// Get rid of the colour world - we no longer need it
		CFRelease(cw);
		CFRelease(srcProf);
		CFRelease(destProf);
		
	} else if (srcType == XCF_GRAY_IMAGE && destType == XCF_RGB_IMAGE) {
		ColorSyncProfileRef srcProf, destProf;
		ColorSyncTransformRef cw;

		// Create colour world
		destProf = ColorSyncProfileCreateWithDisplayID(0);
		srcProf = ColorSyncProfileCreateWithName(kColorSyncGenericGrayProfile);
		NSArray<NSDictionary<NSString*,id>*>*
		profSeq = @[
					@{(__bridge NSString*)kColorSyncProfile: (__bridge id)srcProf,
					  (__bridge NSString*)kColorSyncRenderingIntent: (__bridge NSString*)kColorSyncRenderingIntentPerceptual,
					  (__bridge NSString*)kColorSyncTransformTag: (__bridge NSString*)kColorSyncTransformDeviceToPCS,
					  },
					
					@{(__bridge NSString*)kColorSyncProfile: (__bridge id)destProf,
					  (__bridge NSString*)kColorSyncRenderingIntent: (__bridge NSString*)kColorSyncRenderingIntentPerceptual,
					  (__bridge NSString*)kColorSyncTransformTag: (__bridge NSString*)kColorSyncTransformPCSToDevice,
					  },
					];
		cw = ColorSyncTransformCreate((__bridge CFArrayRef)(profSeq), NULL);
		
		// Define the source
		oldData = data;
	
		// Define the destination
		newData = malloc(make_128(width * height * 4));
		
		// Execute the conversion
		ColorSyncTransformConvert(cw, width, height, newData, kColorSync8BitInteger, kColorSyncByteOrderDefault | kColorSyncAlphaLast, width * 4, oldData, kColorSync8BitInteger, kColorSyncByteOrderDefault | kColorSyncAlphaLast, width * 2, NULL);
		
		for (i = 0; i < width * height; i++)
			newData[i * 4 + 3] = oldData[i * 2 + 1];
		data = newData;
		free(oldData);
		spp = 4;
		
		// Get rid of the colour world - we no longer need it
		CFRelease(cw);
		CFRelease(srcProf);
		CFRelease(destProf);
	}
}
#endif

@end
