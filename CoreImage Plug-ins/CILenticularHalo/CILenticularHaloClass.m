#include <GIMPCore/GIMPCore.h>
#include <math.h>
#include <tgmath.h>
#import <SeashoreKit/Bitmap.h>
#import "CILenticularHaloClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]
#define make_128(x) (x + 16 - (x % 16))

@implementation CILenticularHaloClass
@synthesize mainColor = mainNSColor;
@synthesize contrast;
@synthesize overlap;
@synthesize strength;

- (instancetype)initWithManager:(SeaPlugins *)manager
{
	if (self = [super initWithManager:manager]) {
		NSArray *tmpArray;
		[gOurBundle loadNibNamed:@"CILenticularHalo" owner:self topLevelObjects:&tmpArray];
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
	return 3;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Halo" table:NULL];
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
	
	if ([defaults objectForKey:@"CILenticularHalo.overlap"])
		self.overlap = [defaults doubleForKey:@"CILenticularHalo.overlap"];
	else
		self.overlap = 0.77;
	
	if ([defaults objectForKey:@"CILenticularHalo.strength"])
		self.strength = [defaults doubleForKey:@"CILenticularHalo.strength"];
	else
		self.strength = 0.5;
	
	if ([defaults objectForKey:@"CILenticularHalo.contrast"])
		self.contrast = [defaults floatForKey:@"CILenticularHalo.contrast"];
	else
		self.contrast = 1.0;
	
	if (overlap < 0.0 || overlap > 1.0)
		self.overlap = 0.77;
	if (strength < 0.0 || strength > 3.0)
		self.strength = 0.5;
	if (contrast < 0.0 || contrast > 5.0)
		self.contrast = 1.0;
	
	self.mainColor = [NSColor colorWithCalibratedRed:1.0 green:247.0/255.0 blue:188.0 / 255.0 alpha:1];
	
	refresh = YES;
	success = NO;
	running = YES;
	pluginData = [self.seaPlugins data];
	newdata = malloc(make_128([pluginData width] * [pluginData height] * 4));
	[self preview:self];
	if ([pluginData window])
		[NSApp beginSheet:panel modalForWindow:[pluginData window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
	else
		[NSApp runModalForWindow:panel];
	// Nothing to go here
}

- (void)savePluginPreferences
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	[defaults setDouble:overlap forKey:@"CILenticularHalo.overlap"];
	[defaults setDouble:strength forKey:@"CILenticularHalo.strength"];
	[defaults setDouble:contrast forKey:@"CILenticularHalo.contrast"];
}

- (IBAction)apply:(id)sender
{
	[super apply:sender];
	
	running = NO;
	[gColorPanel orderOut:self];
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
	[super cancel:sender];
	
	running = NO;
	[gColorPanel orderOut:sender];
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
	filter = [CIFilter filterWithName:@"CILenticularHaloGenerator"];
	if (filter == NULL) {
		@throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CILenticularHaloGenerator"] userInfo:NULL];
	}
	[filter setDefaults];
	[filter setValue:[CIVector vectorWithX:point1.x Y:height - point1.y] forKey:@"inputCenter"];
	[filter setValue:mainColor forKey:@"inputColor"];
	[filter setValue:@(halo_radius) forKey:@"inputHaloRadius"];
	[filter setValue:@(halo_width) forKey:@"inputHaloWidth"];
	[filter setValue:@(overlap) forKey:@"inputHaloOverlap"];
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
		if ([pluginData channel] == SeaSelectedChannelAlpha)
			return NO;
		
		if ([pluginData spp] == 2)
			return NO;
	}
	
	return YES;
}

@end
