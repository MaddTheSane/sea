#include <GIMPCore/GIMPCore.h>
#include <math.h>
#include <tgmath.h>
#include <simd/simd.h>
#import "Bitmap.h"
#import "CIGaussianBlurClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]
#define make_128(x) (x + 16 - (x % 16))

@implementation CIGaussianBlurClass
@synthesize radius;

- (instancetype)initWithManager:(SeaPlugins *)manager
{
	if (self = [super initWithManager:manager]) {
		NSArray *tmpArray;
		[gOurBundle loadNibNamed:@"CIGaussianBlur" owner:self topLevelObjects:&tmpArray];
		self.nibArray = tmpArray;
	}
	
	return self;
}

- (SeaPluginType)type
{
	return SeaPluginBasic;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Gaussian Blur" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Blur" table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

- (void)run
{
	PluginData *pluginData;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if ([defaults objectForKey:@"CIGaussianBlur.radius"])
		radius = [defaults integerForKey:@"CIGaussianBlur.radius"];
	else
		radius = 10;
	refresh = YES;
	
	if (radius < 1 || radius > 100)
		radius = 10;
	
	success = NO;
	pluginData = [self.seaPlugins data];
	//if ([pluginData spp] == 2 || [pluginData channel] != kAllChannels){
	newdata = malloc(make_128([pluginData width] * [pluginData height] * 4));
	//}
	[self preview:self];
	if ([pluginData window])
		[NSApp beginSheet:panel modalForWindow:[pluginData window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
	else
		[NSApp runModalForWindow:panel];
	// Nothing to go here
}

- (IBAction)apply:(id)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[super apply:sender];
	
	[defaults setInteger:radius forKey:@"CIGaussianBlur.radius"];
}

- (void)reapply
{
	PluginData *pluginData = [self.seaPlugins data];
	
	newdata = malloc(make_128([pluginData width] * [pluginData height] * 4));
	[self execute];
	[pluginData apply];
	if (newdata) {
		free(newdata);
		newdata = NULL;
	}
}

- (BOOL)canReapply
{
	return success;
}

- (unsigned char *)coreImageEffect:(PluginData *)pluginData withBitmap:(unsigned char *)data
{
	CIContext *context;
	CIImage *unclampedInput, *clampedInput, *crop_output, *output;
	CIFilter *clamp, *filter;
	CGImageRef temp_image;
	CGSize size;
	CGRect rect;
	size_t i, vec_len;
	int width, height;
	unsigned char *resdata;
	BOOL opaque, done;
	IntRect selection;
	simd_uint4 *vresdata;
	const simd_uint4 orvmask = simd_make_uint4(255, 255, 255, 255);
	
	// Find core image context
	context = [CIContext contextWithCGContext:[[NSGraphicsContext currentContext] graphicsPort] options:@{kCIContextWorkingColorSpace: (id)[pluginData displayProf], kCIContextOutputColorSpace: (id)[pluginData displayProf]}];
	
	// Get plug-in data
	width = [pluginData width];
	height = [pluginData height];
	selection = [pluginData selection];
	
	// Check if image is opaque
	opaque = ![pluginData hasAlpha] || ([pluginData channel] != SeaSelectedChannelAll);
	if (opaque == NO) {
		done = NO;
		for (i = 0; i < width * height && !done; i++) {
			if (data[i * 4] != 0xFF)
				done = YES;
		}
		if (done == NO) {
			opaque = YES;
		}
	}
	
	// Create core image with data
	size.width = width;
	size.height = height;
	unclampedInput = [CIImage imageWithBitmapData:[NSData dataWithBytesNoCopy:data length:width * height * 4 freeWhenDone:NO] bytesPerRow:width * 4 size:size format:kCIFormatARGB8 colorSpace:[pluginData displayProf]];
	
	// We need to apply a CIAffineClamp to prevent the black soft fringe we'd normally get from
	// the content outside the borders of the image
	clamp = [CIFilter filterWithName: @"CIAffineClamp"];
	[clamp setDefaults];
	[clamp setValue:[NSAffineTransform transform] forKey:@"inputTransform"];
	[clamp setValue:unclampedInput forKey: @"inputImage"];
	clampedInput = [clamp valueForKey: @"outputImage"];
	
	// Run filter
	filter = [CIFilter filterWithName:@"CIGaussianBlur"];
	if (filter == NULL) {
		@throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIGaussianBlur"] userInfo:NULL];
	}
	[filter setDefaults];
	[filter setValue:clampedInput forKey:@"inputImage"];
	[filter setValue:@(radius) forKey:@"inputRadius"];
	output = [filter valueForKey:@"outputImage"];
	
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
	
	// Handle opaque images
	if (opaque) {
		vec_len = [temp_rep pixelsWide] * [temp_rep pixelsHigh] * [temp_rep samplesPerPixel];
		if (vec_len % 16 == 0) { vec_len /= 16; }
		else { vec_len /= 16; vec_len++; }
		vresdata = (simd_uint4 *)resdata;
		for (int i = 0; i < vec_len; i++) {
			vresdata[i] = vresdata[i] | orvmask;
		}
	}
	
	return resdata;
}

- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end
