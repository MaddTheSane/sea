#include <GIMPCore/GIMPCore.h>
#include <math.h>
#include <tgmath.h>
#import "CIBrightnessClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]
#define make_128(x) (x + 16 - (x % 16))

@implementation CIBrightnessClass
@synthesize brightness;
@synthesize contrast;
@synthesize saturation;

- (instancetype)initWithManager:(SeaPlugins *)manager
{
	if (self = [super initWithManager:manager]) {
		NSArray *tmpArray;
		[gOurBundle loadNibNamed:@"CIBrightness" owner:self topLevelObjects:&tmpArray];
		self.nibArray = tmpArray;
		[self addObserver:self forKeyPath:@"brightness" options:NSKeyValueObservingOptionNew context:NULL];
        [self addObserver:self forKeyPath:@"contrast" options:NSKeyValueObservingOptionNew context:NULL];
        [self addObserver:self forKeyPath:@"saturation" options:NSKeyValueObservingOptionNew context:NULL];
	}
	return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"brightness"];
    [self removeObserver:self forKeyPath:@"contrast"];
    [self removeObserver:self forKeyPath:@"saturation"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self) {
        [self update:nil];
    }
}

- (BOOL)restoreAlpha
{
	return YES;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Brightness and Contrast" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Color Adjust" table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

- (void)run
{
	PluginData *pluginData;
	
	self.brightness = 0.0;
	self.contrast = 10.0;
	self.saturation = 1.0;
	
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
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[super apply:sender];
	
	[defaults setDouble:brightness forKey:@"CIBrightness.brightness"];
	[defaults setDouble:contrast / 10 forKey:@"CIBrightness.contrast"];
	[defaults setDouble:saturation forKey:@"CIBrightness.saturation"];
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
	filter = [CIFilter filterWithName:@"CIColorControls"];
	if (filter == NULL) {
		@throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIColorControls"] userInfo:NULL];
	}
	[filter setDefaults];
	[filter setValue:input forKey:@"inputImage"];
	[filter setValue:@(brightness) forKey:@"inputBrightness"];
	[filter setValue:@(contrast / 10) forKey:@"inputContrast"];
	[filter setValue:@(saturation) forKey:@"inputSaturation"];
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
