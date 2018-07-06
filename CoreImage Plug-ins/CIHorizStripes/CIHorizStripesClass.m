#include <GIMPCore/GIMPCore.h>
#import "CIHorizStripesClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]
#define make_128(x) (x + 16 - (x % 16))

@implementation CIHorizStripesClass

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
	return [gOurBundle localizedStringForKey:@"name" value:@"Horizontal Stripes" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Generate" table:NULL];
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
	
	[self execute];
	[pluginData apply];
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

- (void)execute
{
	PluginData *pluginData = [self.seaPlugins data];
	
	if ([pluginData spp] == 2) {
		[self executeGrey:pluginData];
	} else {
		[self executeColor:pluginData];
	}
}

- (void)executeGrey:(PluginData *)pluginData
{
	IntRect selection;
	int i, j, width, height;
	unsigned char *overlay, *resdata;
	
	// Set-up plug-in
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:SeaOverlayBehaviourNormal];
	selection = [pluginData selection];
	
	// Get plug-in data
	width = [pluginData width];
	height = [pluginData height];
	overlay = [pluginData overlay];
	
	// Run CoreImage effect
	resdata = [self stripes:pluginData];
	
	// Copy to destination
	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height)) {
		for (j = 0; j < selection.size.height; j++) {
			for (i = 0; i < selection.size.width; i++) {
				overlay[(width * (selection.origin.y + j) + selection.origin.x + i) * 2] = resdata[i * 4];
				overlay[(width * (selection.origin.y + j) + selection.origin.x + i) * 2 + 1] = resdata[i * 4 + 3];
			}
		}
	} else {
		dispatch_apply(width * height, dispatch_get_global_queue(0, 0), ^(size_t i) {
			overlay[i * 2] = resdata[i * 4];
			overlay[i * 2 + 1] = resdata[i * 4 + 3];
		});
	}
}

- (void)executeColor:(PluginData *)pluginData
{
	IntRect selection;
	int width, height;
	unsigned char *resdata, *overlay;
	
	// Set-up plug-in
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:SeaOverlayBehaviourNormal];
	selection = [pluginData selection];
	
	// Get plug-in data
	width = [pluginData width];
	height = [pluginData height];
	overlay = [pluginData overlay];
	
	// Run CoreImage effect
	resdata = [self stripes:pluginData];

	// Copy to destination
	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height)) {
		dispatch_apply(selection.size.height, dispatch_get_global_queue(0, 0), ^(size_t i) {
			memcpy(&(overlay[(width * (selection.origin.y + i) + selection.origin.x) * 4]), &(resdata[selection.size.width * 4 * i]), selection.size.width * 4);
		});
	} else {
		memcpy(overlay, resdata, width * height * 4);
	}
}

- (unsigned char *)stripes:(PluginData *)pluginData
{
	CIContext *context;
	CIImage *crop_output, *pre_output, *output;
	CIFilter *filter;
	CGImageRef temp_image;
	NSAffineTransform *rotateTransform;
	CGSize size;
	CGRect rect;
	int width, height;
	unsigned char *resdata;
	IntRect selection;
	IntPoint point, apoint;
	CIColor *backColorAlpha = [[CIColor alloc] initWithColor:[pluginData backColor:YES]];
	CIColor *foreColorAlpha = [[CIColor alloc] initWithColor:[pluginData foreColor:YES]];
	int amount;
	
	// Find core image context
	context = [CIContext contextWithCGContext:[[NSGraphicsContext currentContext] graphicsPort] options:@{kCIContextWorkingColorSpace: (id)[pluginData displayProf], kCIContextOutputColorSpace: (id)[pluginData displayProf]}];
	
	// Get plug-in data
	width = [pluginData width];
	height = [pluginData height];
	selection = [pluginData selection];
	point = [pluginData point:0];
	apoint = [pluginData point:1];
	amount = abs(apoint.y - point.y);
	
	// Create core image with data
	size.width = width;
	size.height = height;
	
	// Run filter
	filter = [CIFilter filterWithName:@"CIStripesGenerator"];
	if (filter == NULL) {
		@throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CICircleSplash"] userInfo:NULL];
	}
	[filter setDefaults];
	[filter setValue:[CIVector vectorWithX:height - point.y Y:point.x] forKey:@"inputCenter"];
	[filter setValue:foreColorAlpha forKey:@"inputColor0"];
	[filter setValue:backColorAlpha forKey:@"inputColor1"];
	[filter setValue:@(amount) forKey:@"inputWidth"];
	[filter setValue:@1.0f forKey:@"inputSharpness"];
	pre_output = [filter valueForKey: @"outputImage"];
	
	// Run rotation
	filter = [CIFilter filterWithName:@"CIAffineTransform"];
	[filter setDefaults];
	rotateTransform = [NSAffineTransform transform];
	[rotateTransform rotateByDegrees:90.0];
	[filter setValue:pre_output forKey:@"inputImage"];
	[filter setValue:rotateTransform forKey:@"inputTransform"];
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
	temp_rep = [[NSBitmapImageRep alloc] initWithCGImage:temp_image];
	CGImageRelease(temp_image);
	resdata = [temp_rep bitmapData];
	
	return resdata;
}

- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end
