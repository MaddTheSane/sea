#include <GIMPCore/GIMPCore.h>
#include <math.h>
#include <tgmath.h>
#import "Bitmap.h"
#import "CIOpTileClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]
#define make_128(x) (x + 16 - (x % 16))

@implementation CIOpTileClass
@synthesize angle;
@synthesize scale;
@synthesize squareWidth;

- (instancetype)initWithManager:(SeaPlugins *)manager
{
	if (self = [super initWithManager:manager]) {
		NSArray *tmpArray;
		[gOurBundle loadNibNamed:@"CIOpTile" owner:self topLevelObjects:&tmpArray];
		self.nibArray = tmpArray;
	}
	
	return self;
}

- (SeaPluginType)type
{
	return SeaPluginPoint;
}

- (int)points
{
	return 1;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Circular Screen" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Halftone" table:NULL];
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

	if ([defaults objectForKey:@"CIOpTile.width"])
		self.squareWidth = [defaults integerForKey:@"CIOpTile.width"];
	else
		self.squareWidth = 65;
	
	self.angle = 0.0;
	
	if ([defaults objectForKey:@"CIOpTile.scale"])
		self.scale = [defaults floatForKey:@"CIOpTile.scale"];
	else
		self.scale = 2.8;
			
	if (squareWidth < 10 || squareWidth > 400)
		self.squareWidth = 65;
	if (scale < 0.1 || scale > 10.0)
		self.scale = 2.8;
			
	refresh = YES;
	success = NO;
	pluginData = [self.seaPlugins data];
	newdata = malloc(make_128([pluginData width] * [pluginData height] * 4));
	[self preview:self];
	if ([pluginData window]) {
		[[pluginData window] beginSheet:panel completionHandler:^(NSModalResponse returnCode) {
			
		}];
	} else
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
		[pluginData.window endSheet:panel];
	[panel orderOut:self];
	success = YES;
	if (newdata) {
		free(newdata);
		newdata = NULL;
	}
	
	[defaults setInteger:squareWidth forKey:@"CIOpTile.width"];
	[defaults setFloat:scale forKey:@"CIOpTile.scale"];
}

- (void)reapply
{
	PluginData *pluginData = [self.seaPlugins data];
	
	if ([pluginData spp] == 2 || [pluginData channel] != SeaSelectedChannelAll)
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

- (IBAction)update:(id)sender
{
	if (angle > -0.035 && angle < 0.00)
		self.angle = 0.00; /* Force a zero point */
	
	[super update:sender];
}

- (unsigned char *)coreImageEffect:(PluginData *)pluginData withBitmap:(unsigned char *)data
{
	CIContext *context;
	CIImage *input, *crop_output, *imm_output, *output, *background;
	CIFilter *filter;
	CGImageRef temp_image;
	CGSize size;
	CGRect rect;
	int width, height;
	unsigned char *resdata;
	IntRect selection;
	IntPoint point;
	BOOL opaque = ![pluginData hasAlpha];
	CIColor *backColor;
	
	if (opaque)
		backColor = [[CIColor alloc] initWithColor:[pluginData backColor:YES]];
	
	// Find core image context
	context = [CIContext contextWithCGContext:[[NSGraphicsContext currentContext] graphicsPort] options:@{kCIContextWorkingColorSpace: (id)[pluginData displayProf], kCIContextOutputColorSpace: (id)[pluginData displayProf]}];
	
	// Get plug-in data
	width = [pluginData width];
	height = [pluginData height];
	selection = [pluginData selection];
	point = [pluginData point:0];
	
	// Create core image with data
	size.width = width;
	size.height = height;
	input = [CIImage imageWithBitmapData:[NSData dataWithBytesNoCopy:data length:width * height * 4 freeWhenDone:NO] bytesPerRow:width * 4 size:size format:kCIFormatARGB8 colorSpace:[pluginData displayProf]];
	
	// Run filter
	filter = [CIFilter filterWithName:@"CIOpTile"];
	if (filter == NULL) {
		@throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIOpTile"] userInfo:NULL];
	}
	[filter setDefaults];
	[filter setValue:input forKey:kCIInputImageKey];
	[filter setValue:[CIVector vectorWithX:point.x Y:height - point.y] forKey:@"inputCenter"];
	[filter setValue:@(squareWidth) forKey:@"inputWidth"];
	[filter setValue:@(angle) forKey:@"inputAngle"];
	[filter setValue:@(scale) forKey:@"inputScale"];
	imm_output = [filter valueForKey:kCIOutputImageKey];
	
	// Add opaque background (if required)
	if (opaque) {
		filter = [CIFilter filterWithName:@"CIConstantColorGenerator"];
		[filter setDefaults];
		[filter setValue:backColor forKey:@"inputColor"];
		background = [filter valueForKey: kCIOutputImageKey]; 
		filter = [CIFilter filterWithName:@"CISourceOverCompositing"];
		[filter setDefaults];
		[filter setValue:background forKey:@"inputBackgroundImage"];
		[filter setValue:imm_output forKey:kCIInputImageKey];
		output = [filter valueForKey:kCIOutputImageKey];
	} else {
		output = imm_output;
	}
	
	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height)) {
		// Crop to selection
		filter = [CIFilter filterWithName:@"CICrop"];
		[filter setDefaults];
		[filter setValue:output forKey:kCIInputImageKey];
		[filter setValue:[CIVector vectorWithX:selection.origin.x Y:height - selection.size.height - selection.origin.y Z:selection.size.width W:selection.size.height] forKey:@"inputRectangle"];
		crop_output = [filter valueForKey:kCIOutputImageKey];
		
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
