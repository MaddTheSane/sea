#import "Bitmap.h"
#import "CISpotLightClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]
#define make_128(x) (x + 16 - (x % 16))

@implementation CISpotLightClass
@synthesize seaPlugins;
@synthesize panel;
@synthesize nibArray;
@synthesize mainColor = mainNSColor;
@synthesize brightness;
@synthesize concentration;
@synthesize destHeight;
@synthesize srcHeight;

- (id)initWithManager:(SeaPlugins *)manager
{
	if (self = [super init]) {
		NSArray *tmpArray;
		self.seaPlugins = manager;
		[gOurBundle loadNibNamed:@"CISpotLight" owner:self topLevelObjects:&tmpArray];
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
	return [gOurBundle localizedStringForKey:@"name" value:@"Spotlight" table:NULL];
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
	
	if ([defaults objectForKey:@"CISpotLight.brightness"])
		self.brightness = [defaults floatForKey:@"CISpotLight.brightness"];
	else
		self.brightness = 3.0;
	
	if (brightness < 0.0 || brightness > 10.0)
		self.brightness = 3.0;
	
	if ([defaults objectForKey:@"CISpotLight.concentration"])
		self.concentration = [defaults floatForKey:@"CISpotLight.concentration"];
	else
		self.concentration = 0.4;
	
	if (concentration < 0.0 || concentration > 2.0)
		self.concentration = 0.4;
	
	if ([defaults objectForKey:@"CISpotLight.srcHeight"])
		self.srcHeight = [defaults floatForKey:@"CISpotLight.srcHeight"];
	else
		self.srcHeight = 150;
	
	if (srcHeight < 50 || srcHeight > 500)
		srcHeight = 150;
	
	if ([defaults objectForKey:@"CISpotLight.destHeight"])
		self.destHeight = [defaults floatForKey:@"CISpotLight.destHeight"];
	else
		self.destHeight = 0;
	
	if (destHeight < -100 || destHeight > 400)
		self.destHeight = 0;
	
	self.mainColor = [NSColor colorWithCalibratedWhite:1.0 alpha:1.0];
	
	refresh = YES;
	success = NO;
	running = YES;
	pluginData = [seaPlugins data];
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
	PluginData *pluginData = [seaPlugins data];
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
	running = NO;
	if (newdata) {
		free(newdata);
		newdata = NULL;
	}
	
	[defaults setFloat:brightness forKey:@"CISpotLight.brightness"];
	[defaults setFloat:concentration forKey:@"CISpotLight.concentration"];
	[defaults setInteger:srcHeight forKey:@"CISpotLight.srcHeight"];
	[defaults setInteger:destHeight forKey:@"CISpotLight.destHeight"];
	
	[gColorPanel orderOut:self];
}

- (void)reapply
{
	PluginData *pluginData = [seaPlugins data];
	
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
		if ([pluginData window]) [panel setAlphaValue:0.4];
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

#define CLASSMETHOD pinch
#include "CICommon.mi"

- (unsigned char *)pinch:(PluginData *)pluginData withBitmap:(unsigned char *)data
{
	CIContext *context;
	CIImage *input, *imm_output, *crop_output, *output, *background;
	CIFilter *filter;
	CGImageRef temp_image;
	CGSize size;
	CGRect rect;
	int width, height;
	unsigned char *resdata;
	IntRect selection;
	IntPoint point, apoint;
	CIColor *mainColor = [[CIColor alloc] initWithColor:mainNSColor];
	CIColor *backColor = [CIColor colorWithRed:0 green:0 blue:0];
	
	// Find core image context
	context = [CIContext contextWithCGContext:[[NSGraphicsContext currentContext] graphicsPort] options:@{kCIContextWorkingColorSpace: (id)[pluginData displayProf], kCIContextOutputColorSpace: (id)[pluginData displayProf]}];
	
	// Get plug-in data
	width = [pluginData width];
	height = [pluginData height];
	selection = [pluginData selection];
	point = [pluginData point:0];
	apoint = [pluginData point:1];
	
	// Create core image with data
	size.width = width;
	size.height = height;
	input = [CIImage imageWithBitmapData:[NSData dataWithBytesNoCopy:data length:width * height * 4 freeWhenDone:NO] bytesPerRow:width * 4 size:size format:kCIFormatARGB8 colorSpace:[pluginData displayProf]];
	
	// Run filter
	filter = [CIFilter filterWithName:@"CISpotLight"];
	if (filter == NULL) {
		@throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CISpotLight"] userInfo:NULL];
	}
	[filter setDefaults];
	[filter setValue:input forKey:@"inputImage"];
	[filter setValue:mainColor forKey:@"inputColor"];
	[filter setValue:[CIVector vectorWithX:point.x Y:height - point.y Z:srcHeight] forKey:@"inputLightPosition"];
	[filter setValue:[CIVector vectorWithX:apoint.x Y:height - apoint.y Z:destHeight] forKey:@"inputLightPointsAt"];
	[filter setValue:@(concentration) forKey:@"inputConcentration"];
	[filter setValue:@(brightness) forKey:@"inputBrightness"];
	imm_output = [filter valueForKey: @"outputImage"];
	
	// Add opaque background (if required)
	filter = [CIFilter filterWithName:@"CIConstantColorGenerator"];
	[filter setDefaults];
	[filter setValue:backColor forKey:@"inputColor"];
	background = [filter valueForKey: @"outputImage"]; 
	filter = [CIFilter filterWithName:@"CISourceOverCompositing"];
	[filter setDefaults];
	[filter setValue:background forKey:@"inputBackgroundImage"];
	[filter setValue:imm_output forKey:@"inputImage"];
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
