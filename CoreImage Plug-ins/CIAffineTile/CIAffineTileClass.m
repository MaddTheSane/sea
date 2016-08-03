#include <GIMPCore/GIMPCore.h>
#include <math.h>
#include <tgmath.h>
#import "Bitmap.h"
#import "CIAffineTileClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]
#define make_128(x) (x + 16 - (x % 16))

@implementation CIAffineTileClass

- (int)type
{
	return kPointPlugin;
}

- (int)points
{
	return 2;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Scale and Rotate" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Tile" table:NULL];
}

- (NSString *)instruction
{
	return [gOurBundle localizedStringForKey:@"instruction" value:@"Needs localization." table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

- (void)run
{
	PluginData *pluginData = [self.seaPlugins data];
	
	[self determineContentBorders:pluginData];
	newdata = malloc(make_128([pluginData width] * [pluginData height] * 4));
	[self execute];
	[pluginData apply];
	if (newdata) {
		free(newdata);
		newdata = NULL;
	}
	success = YES;
}

- (void)reapply
{
	[self run];
}

- (BOOL)canReapply
{
	return NO;
}

#define CLASSMETHOD tile
#include "CICommon.mi"

- (unsigned char *)tile:(PluginData *)pluginData withBitmap:(unsigned char *)data
{
	CIContext *context;
	CIImage *input, *crop_output, *imm_output_1, *imm_output_2, *output;
	CIFilter *filter;
	CGImageRef temp_image;
	CGSize size;
	CGRect rect;
	int width, height;
	unsigned char *resdata;
	IntRect selection;
	IntPoint point, apoint;
	CGFloat scale, angle;
	int baselen;
	NSAffineTransform *offsetTransform, *trueTransform;
	
	// Find core image context
	context = [CIContext contextWithCGContext:[[NSGraphicsContext currentContext] graphicsPort] options:@{kCIContextWorkingColorSpace: (id)[pluginData displayProf], kCIContextOutputColorSpace: (id)[pluginData displayProf]}];
	
	// Get plug-in data
	width = [pluginData width];
	height = [pluginData height];
	selection = [pluginData selection];
	point = [pluginData point:0];
	apoint = [pluginData point:1];
	baselen = (apoint.x - point.x) * (apoint.x - point.x) + (apoint.y - point.y) * (apoint.y - point.y);
	baselen = sqrt(baselen);
	if (boundsValid) scale = (float)baselen / (float)bounds.size.width;
	else scale = (float)baselen / (float)width;
	if (apoint.x - point.x != 0)
		angle = atan((float)(point.y - apoint.y) / (float)(apoint.x - point.x));
	else
		angle = M_PI / 2 * ((point.y - apoint.y > 0) ? 1 : -1);
	trueTransform = [NSAffineTransform transform];
	[trueTransform translateXBy:point.x yBy:height - point.y];
	[trueTransform scaleBy:scale];
	[trueTransform rotateByRadians:angle];
	
	// Create core image with data
	size.width = width;
	size.height = height;
	input = [CIImage imageWithBitmapData:[NSData dataWithBytesNoCopy:data length:width * height * 4 freeWhenDone:NO] bytesPerRow:width * 4 size:size format:kCIFormatARGB8 colorSpace:[pluginData displayProf]];
		
	// Position correctly
	if (boundsValid) {
		// Crop to selection
		filter = [CIFilter filterWithName:@"CICrop"];
		[filter setDefaults];
		[filter setValue:input forKey:@"inputImage"];
		[filter setValue:[CIVector vectorWithX:bounds.origin.x Y:height - bounds.size.height - bounds.origin.y Z:bounds.size.width W:bounds.size.height] forKey:@"inputRectangle"];
		imm_output_1 = [filter valueForKey:@"outputImage"];
		
		// Offset properly
		filter = [CIFilter filterWithName:@"CIAffineTransform"];
		[filter setDefaults];
		[filter setValue:imm_output_1 forKey:@"inputImage"];
		offsetTransform = [NSAffineTransform transform];
		[offsetTransform translateXBy:-bounds.origin.x yBy:-height + bounds.origin.y + bounds.size.height];
		[filter setValue:offsetTransform forKey:@"inputTransform"];
		imm_output_2 = [filter valueForKey:@"outputImage"];
	} else {
		imm_output_2 = input;
	}
	
	// Run filter
	filter = [CIFilter filterWithName:@"CIAffineTile"];
	if (filter == NULL) {
		@throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIAffineTile"] userInfo:NULL];
	}
	[filter setDefaults];
	[filter setValue:imm_output_2 forKey:@"inputImage"];
	[filter setValue:trueTransform forKey:@"inputTransform"];
	output = [filter valueForKey: @"outputImage"];
		
	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height)) {
		
		// Crop to selection
		filter = [CIFilter filterWithName:@"CICrop"];
		[filter setDefaults];
		[filter setValue:output forKey:@"inputImage"];
		[filter setValue:[CIVector vectorWithX:selection.origin.x Y:height - selection.size.height - selection.origin.y Z:selection.size.width W:selection.size.height] forKey:@"inputRectangle"];
		crop_output = [filter valueForKey:@"outputImage"];
		
		// Create output core image
		rect.origin.x = selection.origin.x;
		rect.origin.y = height - selection.size.height - selection.origin.y;
		rect.size.width = selection.size.width;
		rect.size.height = selection.size.height;
		temp_image = [context createCGImage:output fromRect:rect];		
	} else {
		// Create output core image
		rect.origin.x = 0;
		rect.origin.y = 0;
		rect.size.width = width;
		rect.size.height = height;
		temp_image = [context createCGImage:output fromRect:rect];
	}
	
	// Get data from output core image
	temp_rep = [NSBitmapImageRep imageRepWithData:[[[NSBitmapImageRep alloc] initWithCGImage:temp_image] TIFFRepresentation]];
	CGImageRelease(temp_image);
	resdata = [temp_rep bitmapData];
	
	return resdata;
}

- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end
