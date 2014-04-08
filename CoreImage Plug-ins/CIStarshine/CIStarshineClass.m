#import "Bitmap.h"
#import "CIStarshineClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]
#define make_128(x) (x + 16 - (x % 16))

@implementation CIStarshineClass
@synthesize seaPlugins;
@synthesize panel;
@synthesize nibArray;
@synthesize mainColor = mainNSColor;
@synthesize opacity;
@synthesize scale;
@synthesize starWidth = star_width;

- (id)initWithManager:(SeaPlugins *)manager
{
	if (self = [super init]) {
		NSArray *tmpArray;
		self.seaPlugins = manager;
		[gOurBundle loadNibNamed:@"CIStarshine" owner:self topLevelObjects:&tmpArray];
		self.nibArray = tmpArray;
	}
	
	return self;
}

- (int)type
{
	return 1;
}

- (int)points
{
	return 2;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Starshine" table:NULL];
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
	
	if ([defaults objectForKey:@"CIStarshine.scale"])
		self.scale = [defaults floatForKey:@"CIStarshine.scale"];
	else
		self.scale = 15;
	
	if ([defaults objectForKey:@"CIStarshine.opacity"])
		self.opacity = [defaults floatForKey:@"CIStarshine.opacity"];
	else
		self.opacity = -2.0;
	if ([defaults objectForKey:@"CIStarshine.width"])
		self.starWidth = [defaults floatForKey:@"CIStarshine.width"];
	else
		self.starWidth = 2.5;
	
	if (scale < 0 || scale > 100)
		self.scale = 15;
	if (opacity < -8.0 || opacity > 0.0)
		self.opacity = -2.0;
	if (star_width < 0.0 || star_width > 10.0)
		self.starWidth = 2.5;
	
	self.mainColor = [NSColor colorWithCalibratedRed:1.0 green:247.0/255.0 blue:188.0 / 255.0 alpha:1];
	
	refresh = YES;
	success = NO;
	running = YES;
	pluginData = [seaPlugins data];
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
	PluginData *pluginData = [seaPlugins data];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if (refresh)
		[self execute];
	[pluginData apply];
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	if ([pluginData window]) [NSApp endSheet:panel];
	[panel orderOut:self];
	success = YES;
	running = NO;
	if (newdata) {
		free(newdata);
		newdata = NULL;
	}
	
	[defaults setInteger:scale forKey:@"CIStarshine.scale"];
	[defaults setFloat:opacity forKey:@"CIStarshine.opacity"];
	[defaults setFloat:star_width forKey:@"CIStarshine.width"];
	
	[gColorPanel orderOut:self];
}

- (void)reapply
{
	PluginData *pluginData = [seaPlugins data];
	
	//if ([pluginData spp] == 2 || [pluginData channel] != kAllChannels){
	newdata = malloc(make_128([pluginData width] * [pluginData height] * 4));
	//}
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
	PluginData *pluginData = [seaPlugins data];
	
	if (refresh)
		[self execute];
	[pluginData preview];
	refresh = NO;
}

- (IBAction)cancel:(id)sender
{
	PluginData *pluginData = [seaPlugins data];
	
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

- (void)setColor:(NSColor *)color
{
	PluginData *pluginData;
	
	mainNSColor = [color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	if (running) {
		refresh = YES;
		[self preview:self];
		pluginData = [seaPlugins data];
		if ([pluginData window])
			[panel setAlphaValue:0.4];
	}
}

- (IBAction)update:(id)sender
{
	PluginData *pluginData;
	
	[panel setAlphaValue:1.0];
	
	refresh = YES;
	if ([[NSApp currentEvent] type] == NSLeftMouseUp) { 
		[self preview:self];
		pluginData = [seaPlugins data];
		if ([pluginData window])
			[panel setAlphaValue:0.4];
	}
}

#define CLASSMETHOD starshine
#include "CICommon.mi"

- (unsigned char *)starshine:(PluginData *)pluginData withBitmap:(unsigned char *)data
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
	CIColor *mainColor;
	IntPoint point1, point2;
	double radius;
	double angle;
	
	// Get foreground color
	mainColor = [[CIColor alloc] initWithColor:mainNSColor];
	
	// Find core image context
	context = [CIContext contextWithCGContext:[[NSGraphicsContext currentContext] graphicsPort] options:@{kCIContextWorkingColorSpace: (id)[pluginData displayProf], kCIContextOutputColorSpace: (id)[pluginData displayProf]}];
	
	// Get plug-in data
	width = [pluginData width];
	height = [pluginData height];
	selection = [pluginData selection];
	point1 = [pluginData point:0];
	point2 = [pluginData point:1];
	if (point2.x - point1.x == 0)
		angle = M_PI / 2.0;
	else if (point2.x - point1.x > 0)
		angle = atanf((float)(point1.y - point2.y) / fabsf((float)(point2.x - point1.x)));
	else if (point2.x - point1.x < 0 && point1.y - point2.y > 0)
		angle = M_PI - atanf((float)(point1.y - point2.y) / fabsf((float)(point2.x - point1.x)));
	else
		angle = -M_PI - atanf((float)(point1.y - point2.y) / fabsf((float)(point2.x - point1.x)));
	if (angle < 0)
		angle = 2 * M_PI + angle;
	radius = abs(point2.x - point1.x) * abs(point2.x - point1.x) + abs(point2.y - point1.y) * abs(point2.y - point1.y);
	radius = sqrt(radius);
	// radius /= 4.0;
	
	// Create core image with data
	size.width = width;
	size.height = height;
	input = [CIImage imageWithBitmapData:[NSData dataWithBytesNoCopy:data length:width * height * 4 freeWhenDone:NO] bytesPerRow:width * 4 size:size format:kCIFormatARGB8 colorSpace:[pluginData displayProf]];
	
	// Run filter
	filter = [CIFilter filterWithName:@"CIStarShineGenerator"];
	if (filter == NULL) {
		@throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIStarshineGenerator"] userInfo:NULL];
	}
	[filter setDefaults];
	[filter setValue:[CIVector vectorWithX:point1.x Y:height - point1.y] forKey:@"inputCenter"];
	[filter setValue:mainColor forKey:@"inputColor"];
	[filter setValue:@(radius) forKey:@"inputRadius"];
	[filter setValue:@(scale) forKey:@"inputCrossScale"];
	[filter setValue:@(angle) forKey:@"inputCrossAngle"];
	[filter setValue:@(opacity) forKey:@"inputCrossOpacity"];
	[filter setValue:@(star_width) forKey:@"inputCrossWidth"];
	[filter setValue:@-2 forKey:@"inputEpsilon"];
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
	PluginData *pluginData = [seaPlugins data];
	
	if (pluginData != NULL) {
		if ([pluginData channel] == kAlphaChannel)
			return NO;
		
		if ([pluginData spp] == 2)
			return NO;
	}
	
	return YES;
}

@end
