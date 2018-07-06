#include <GIMPCore/GIMPCore.h>
#import "Bitmap.h"
#import "CICMYKHalftoneClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]
#define make_128(x) (x + 16 - (x % 16))

@implementation CICMYKHalftoneClass
@synthesize angle;
@synthesize sharpness;
@synthesize gcr;
@synthesize ucr;
@synthesize dotWidth;

- (instancetype)initWithManager:(SeaPlugins *)manager
{
	if (self = [super initWithManager:manager]) {
		NSArray *tmpArray;
		[gOurBundle loadNibNamed:@"CICMYKHalftone" owner:self topLevelObjects:&tmpArray];
		self.nibArray = tmpArray;
	}
	
	return self;
}

- (int)type
{
	return kBasicPlugin;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"CMYK Halftone" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Halftone" table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

- (void)run
{
	PluginData *pluginData;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if ([defaults objectForKey:@"CICMYKHalftone.width"])
		self.dotWidth = [defaults integerForKey:@"CICMYKHalftone.width"];
	else
		self.dotWidth = 6;
	
	if ([defaults objectForKey:@"CICMYKHalftone.angle"])
		self.angle = [defaults floatForKey:@"CICMYKHalftone.angle"];
	else
		self.angle = 0.0;
	
	if ([defaults objectForKey:@"CICMYKHalftone.sharpness"])
		self.sharpness = [defaults floatForKey:@"CICMYKHalftone.sharpness"];
	else
		self.sharpness = 0.7;
	
	if ([defaults objectForKey:@"CICMYKHalftone.gcr"])
		self.gcr = [defaults floatForKey:@"CICMYKHalftone.gcr"];
	else
		self.gcr = 1.0;
	
	if ([defaults objectForKey:@"CICMYKHalftone.ucr"])
		self.ucr = [defaults floatForKey:@"CICMYKHalftone.ucr"];
	else
		self.ucr = 0.5;
	
	if (dotWidth < 2 || dotWidth > 100)
		self.dotWidth = 6;
	
	if (angle < -3.14 || angle > 3.14)
		self.angle = 0.0;
	
	if (sharpness < 0.0 || sharpness > 1.0)
		self.sharpness = 0.7;
	
	if (gcr < 0.0 || gcr > 1.0)
		self.gcr = 1.0;
	
	if (ucr < 0.0 || ucr > 1.0)
		self.ucr = 0.5;
	
	refresh = YES;
	success = NO;
	pluginData = [self.seaPlugins data];
	newdata = malloc(make_128([pluginData width] * [pluginData height] * 4));
	[self preview:self];
	if ([pluginData window])
		[NSApp beginSheet:panel modalForWindow:[pluginData window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
	else
		[NSApp runModalForWindow:panel];
	// Nothing to go here
}

- (IBAction)apply:(id)sender
{
	PluginData *pluginData = [self.seaPlugins data];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if (refresh)
		[self execute];
	[pluginData apply];
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	if ([pluginData window]) [NSApp endSheet:panel];
	[panel orderOut:self];
	success = YES;
	if (newdata) {
		free(newdata);
		newdata = NULL;
	}
		
	[defaults setInteger:dotWidth forKey:@"CICMYKHalftone.width"];
	[defaults setFloat:angle forKey:@"CICMYKHalftone.angle"];
	[defaults setFloat:sharpness forKey:@"CICMYKHalftone.sharpness"];
	[defaults setFloat:gcr forKey:@"CICMYKHalftone.gcr"];
	[defaults setFloat:ucr forKey:@"CICMYKHalftone.ucr"];
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
	CIImage *input, *crop_output, *output;
	CIFilter *filter;
	CGImageRef temp_image;
	CGSize size;
	CGRect rect;
	int width, height;
	unsigned char *resdata;
	IntRect selection;
	
	// Find core image context
	context = [CIContext contextWithCGContext:[[NSGraphicsContext currentContext] graphicsPort] options:@{kCIContextWorkingColorSpace: (id)[pluginData displayProf], kCIContextOutputColorSpace: (id)[pluginData displayProf]}];
	
	// Get plug-in data
	width = [pluginData width];
	height = [pluginData height];
	selection = [pluginData selection];
	
	// Create core image with data
	size.width = width;
	size.height = height;
	input = [CIImage imageWithBitmapData:[NSData dataWithBytesNoCopy:data length:width * height * 4 freeWhenDone:NO] bytesPerRow:width * 4 size:size format:kCIFormatARGB8 colorSpace:[pluginData displayProf]];
	
	// Run filter
	filter = [CIFilter filterWithName:@"CICMYKHalftone"];
	if (filter == NULL) {
		@throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CICMYKHalftone"] userInfo:NULL];
	}
	[filter setDefaults];
	[filter setValue:input forKey:@"inputImage"];
	[filter setValue:[CIVector vectorWithX:width / 2 Y:height / 2] forKey:@"inputCenter"];
	[filter setValue:@(dotWidth) forKey:@"inputWidth"];
	[filter setValue:@(angle) forKey:@"inputAngle"];
	[filter setValue:@(sharpness) forKey:@"inputSharpness"];
	[filter setValue:@(gcr) forKey:@"inputGCR"];
	[filter setValue:@(ucr) forKey:@"inputUCR"];
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
		
	}
	else {
	
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
	PluginData *pluginData = [self.seaPlugins data];
	
	if (pluginData != NULL) {
		if ([pluginData channel] == SeaSelectedChannelAlpha)
			return NO;
		
		if ([pluginData spp] == 2)
			return NO;
	}
	
	return YES;
}

@end
