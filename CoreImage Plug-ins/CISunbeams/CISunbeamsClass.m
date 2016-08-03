#include <GIMPCore/GIMPCore.h>
#include <math.h>
#include <tgmath.h>
#import "Bitmap.h"
#import "CISunbeamsClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]
#define make_128(x) (x + 16 - (x % 16))

@implementation CISunbeamsClass
@synthesize mainColor = mainNSColor;
@synthesize contrast;
@synthesize strength;

- (instancetype)initWithManager:(SeaPlugins *)manager
{
	if (self = [super initWithManager:manager]) {
		NSArray *tmp;
		[gOurBundle loadNibNamed:@"CISunbeams" owner:self topLevelObjects:&tmp];
		self.nibArray = tmp;
	}
	
	return self;
}

- (int)type
{
	return kPointPlugin;
}

- (int)points
{
	return 3;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Sunbeams" table:NULL];
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
	PluginData *pluginData;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if ([defaults objectForKey:@"CISunbeams.strength"])
		self.strength = [defaults floatForKey:@"CISunbeams.strength"];
	else
		self.strength = 0.5;
	
	if ([defaults objectForKey:@"CISunbeams.contrast"])
		self.contrast = [defaults floatForKey:@"CISunbeams.contrast"];
	else
		self.contrast = 1.0;
	
	if (strength < 0.0 || strength > 3.0)
		self.strength = 0.5;
	if (contrast < 0.0 || contrast > 5.0)
		self.contrast = 1.0;
	
	self.mainColor = [NSColor colorWithCalibratedRed:1.0 green:247.0/255.0 blue:188.0 / 255.0 alpha:1];
	
	refresh = YES;
	success = NO;
	running = YES;
	pluginData = [self.seaPlugins data];
	if ([pluginData spp] == 2 || [pluginData channel] != kAllChannels) newdata = malloc(make_128([pluginData width] * [pluginData height] * 4));
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
	[panel orderOut:sender];
	success = YES;
	running = NO;
	if (newdata) {
		free(newdata);
		newdata = NULL;
	}
	
	[defaults setFloat:strength forKey:@"CISunbeams.strength"];
	[defaults setFloat:contrast forKey:@"CISunbeams.contrast"];
	
	[gColorPanel orderOut:self];
}

- (void)reapply
{
	PluginData *pluginData = [self.seaPlugins data];
	
	if ([pluginData spp] == 2 || [pluginData channel] != kAllChannels)
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
	running = NO;
	[gColorPanel orderOut:self];
}

- (unsigned char *)coreImageEffect:(PluginData *)pluginData withBitmap:(unsigned char *)data
{
	CIContext *context;
	CIImage *input, *crop_output, *halo, *output;
	CIFilter *filter;
	CGImageRef temp_image;
	CGSize size;
	CGRect rect;
	int width, height;
	unsigned char *resdata;
	IntRect selection;
	CIColor *mainColor = [[CIColor alloc] initWithColor:mainNSColor];
	IntPoint point1, point2, point3;
	CGFloat halo_width, halo_radius;
	
	// Find core image context
	context = [CIContext contextWithCGContext:[[NSGraphicsContext currentContext] graphicsPort] options:@{kCIContextWorkingColorSpace: (id)[pluginData displayProf], kCIContextOutputColorSpace: (id)[pluginData displayProf]}];
	
	// Get plug-in data
	width = [pluginData width];
	height = [pluginData height];
	selection = [pluginData selection];
	point1 = [pluginData point:0];
	point2 = [pluginData point:1];
	point3 = [pluginData point:2];
	halo_radius = abs(point2.x - point1.x) * abs(point2.x - point1.x) + abs(point2.y - point1.y) * abs(point2.y - point1.y);
	halo_radius = sqrt(halo_radius);
	halo_width = abs(point3.x - point1.x) * abs(point3.x - point1.x) + abs(point3.y - point1.y) * abs(point3.y - point1.y);
	halo_width = sqrt(halo_width);
	halo_width = fabs(halo_width - halo_radius);
	
	// Create core image with data
	size.width = width;
	size.height = height;
	input = [CIImage imageWithBitmapData:[NSData dataWithBytesNoCopy:data length:width * height * 4 freeWhenDone:NO] bytesPerRow:width * 4 size:size format:kCIFormatARGB8 colorSpace:[pluginData displayProf]];
	
	// Run filter
	filter = [CIFilter filterWithName:@"CISunbeamsGenerator"];
	if (filter == NULL) {
		@throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CISunbeamsGenerator"] userInfo:NULL];
	}
	[filter setDefaults];
	[filter setValue:[CIVector vectorWithX:point1.x Y:height - point1.y] forKey:@"inputCenter"];
	[filter setValue:mainColor forKey:@"inputColor"];
	[filter setValue:@(halo_radius) forKey:@"inputSunRadius"];
	[filter setValue:@(halo_width) forKey:@"inputMaxStriationRadius"];
	[filter setValue:@(strength) forKey:@"inputStriationStrength"];
	[filter setValue:@(contrast) forKey:@"inputStriationContrast"];
	[filter setValue:@0 forKey:@"inputTime"];
	halo = [filter valueForKey: @"outputImage"];
	
	// Run filter
	filter = [CIFilter filterWithName:@"CISourceOverCompositing"];
	[filter setDefaults];
	[filter setValue:halo forKey:@"inputImage"];
	[filter setValue:input forKey:@"inputBackgroundImage"];
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
	PluginData *pluginData = [self.seaPlugins data];
	
	if (pluginData != NULL) {
		if ([pluginData channel] == kAlphaChannel)
			return NO;
		
		if ([pluginData spp] == 2)
			return NO;
	}
	
	return YES;
}

@end
