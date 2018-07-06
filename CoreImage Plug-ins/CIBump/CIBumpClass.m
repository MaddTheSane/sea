#include <GIMPCore/GIMPCore.h>
#include <math.h>
#include <tgmath.h>
#import "Bitmap.h"
#import "CIBumpClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]
#define make_128(x) (x + 16 - (x % 16))

@implementation CIBumpClass
@synthesize scale;

- (instancetype)initWithManager:(SeaPlugins *)manager
{
	if (self = [super initWithManager:manager]) {
		NSArray *tmpArray;
		[gOurBundle loadNibNamed:@"CIBump" owner:self topLevelObjects:&tmpArray];
		self.nibArray = tmpArray;
	}
	
	return self;
}

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
	return [gOurBundle localizedStringForKey:@"name" value:@"Bump" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Distort" table:NULL];
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
	PluginData *pluginData;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	if ([defaults objectForKey:@"CIBump.scale"])
		self.scale = [defaults integerForKey:@"CIBump.scale"];
	else
		self.scale = 0.5;
	refresh = YES;
	
	if (scale < -1.0 || scale > 1.0)
		self.scale = 0.5;
	
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
	if ([pluginData window])
		[NSApp endSheet:panel];
	[panel orderOut:self];
	success = YES;
	if (newdata) {
		free(newdata);
		newdata = NULL;
	}
		
	[defaults setFloat:scale forKey:@"CIBump.scale"];
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
	return NO;
}

- (IBAction)preview:(id)sender
{
	PluginData *pluginData = [self.seaPlugins data];
	
	if (refresh)
		[self execute];
	[pluginData preview];
	refresh = NO;
}

- (IBAction)cancel:(id)sender
{
	PluginData *pluginData = [self.seaPlugins data];
	
	[pluginData cancel];
	if (newdata) {
		free(newdata);
		newdata = NULL;
	}
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	[NSApp endSheet:panel];
	[panel orderOut:self];
	success = NO;
}

- (IBAction)update:(id)sender
{
	PluginData *pluginData;
	
	[panel setAlphaValue:1.0];
	
	refresh = YES;
	if ([[NSApp currentEvent] type] == NSLeftMouseUp) {
		[self preview:self];
		pluginData = [self.seaPlugins data];
		if ([pluginData window])
			[panel setAlphaValue:0.4];
	}
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
	IntPoint point, apoint;
	int radius;
	
	// Find core image context
	context = [CIContext contextWithCGContext:[[NSGraphicsContext currentContext] graphicsPort] options:@{kCIContextWorkingColorSpace: (id)[pluginData displayProf], kCIContextOutputColorSpace: (id)[pluginData displayProf]}];
	
	// Get plug-in data
	width = [pluginData width];
	height = [pluginData height];
	selection = [pluginData selection];
	point = [pluginData point:0];
	apoint = [pluginData point:1];
	radius = (apoint.x - point.x) * (apoint.x - point.x) + (apoint.y - point.y) * (apoint.y - point.y);
	radius = sqrt(radius);
	
	// Create core image with data
	size.width = width;
	size.height = height;
	input = [CIImage imageWithBitmapData:[NSData dataWithBytesNoCopy:data length:width * height * 4 freeWhenDone:NO] bytesPerRow:width * 4 size:size format:kCIFormatARGB8 colorSpace:[pluginData displayProf]];
	
	// Run filter
	filter = [CIFilter filterWithName:@"CIBumpDistortion"];
	if (filter == NULL) {
		@throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIBumpDistortion"] userInfo:NULL];
	}
	[filter setDefaults];
	[filter setValue:input forKey:@"inputImage"];
	[filter setValue:[CIVector vectorWithX:point.x Y:height - point.y] forKey:@"inputCenter"];
	[filter setValue:@(radius) forKey:@"inputRadius"];
	[filter setValue:@(scale) forKey:@"inputScale"];
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
