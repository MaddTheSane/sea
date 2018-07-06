#include <GIMPCore/GIMPCore.h>
#include <math.h>
#include <tgmath.h>
#import "Bitmap.h"
#import "CIParallelogramTileClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]
#define make_128(x) (x + 16 - (x % 16))

@implementation CIParallelogramTileClass
@synthesize acute;

- (instancetype)initWithManager:(SeaPlugins *)manager
{
	if (self = [super initWithManager:manager]) {
		NSArray *tmp;
		[gOurBundle loadNibNamed:@"CIParallelogramTile" owner:self topLevelObjects:&tmp];
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
	return 2;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Parallelogram" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Tile" table:NULL];
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
	
	if ([defaults objectForKey:@"CIParallelogramTile.acute"])
		self.acute = [defaults floatForKey:@"CIParallelogramTile.acute"];
	else
		self.acute = 0.78;
	
	if (acute < -1.57 || acute > 1.57)
		self.acute = 0.78;
	
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
	if ([pluginData window])
		[NSApp endSheet:panel];
	[panel orderOut:self];
	success = YES;
	if (newdata) {
		free(newdata);
		newdata = NULL;
	}
	
	[defaults setFloat:acute forKey:@"CILineScreen.acute"];
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

- (IBAction)update:(id)sender
{
	PluginData *pluginData;
	
	if (acute > -0.015 && acute < 0.00)
		self.acute = 0.00; /* Force a zero point */
	
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
	CIImage *input, *crop_output, *imm_output, *output, *background;
	CIFilter *filter;
	CGImageRef temp_image;
	CGSize size;
	CGRect rect;
	int width, height;
	unsigned char *resdata;
	IntRect selection;
	IntPoint point, apoint, yapoint;
	BOOL opaque = ![pluginData hasAlpha];
	CIColor *backColor;
	CGFloat angle;
	int radius;
	
	if (opaque)
		backColor = [[CIColor alloc] initWithColor:[pluginData backColor:YES]];
	
	// Find core image context
	context = [CIContext contextWithCGContext:[[NSGraphicsContext currentContext] graphicsPort] options:@{kCIContextWorkingColorSpace: (id)[pluginData displayProf], kCIContextOutputColorSpace: (id)[pluginData displayProf]}];
	
	// Get plug-in data
	width = [pluginData width];
	height = [pluginData height];
	selection = [pluginData selection];
	point = [pluginData point:0];
	apoint = [pluginData point:1];
	yapoint = [pluginData point:2];
	if (apoint.x - point.x == 0)
		angle = M_PI / 2.0;
	else if (apoint.x - point.x > 0)
		angle = atan((double)(point.y - apoint.y) / fabs((double)(apoint.x - point.x)));
	else if (apoint.x - point.x < 0 && point.y - apoint.y > 0)
		angle = M_PI - atan((double)(point.y - apoint.y) / fabs((double)(apoint.x - point.x)));
	else
		angle = -M_PI - atan((double)(point.y - apoint.y) / fabs((double)(apoint.x - point.x)));
	radius = (apoint.x - point.x) * 2 + (apoint.y - point.y) * 2;
	radius = sqrt(radius);

	// Create core image with data
	size.width = width;
	size.height = height;
	input = [CIImage imageWithBitmapData:[NSData dataWithBytesNoCopy:data length:width * height * 4 freeWhenDone:NO] bytesPerRow:width * 4 size:size format:kCIFormatARGB8 colorSpace:[pluginData displayProf]];
	
	// Run filter
	filter = [CIFilter filterWithName:@"CIParallelogramTile"];
	if (filter == NULL) {
		@throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIParallelogramTile"] userInfo:NULL];
	}
	[filter setDefaults];
	[filter setValue:input forKey:@"inputImage"];
	[filter setValue:@(angle) forKey:@"inputAngle"];
	[filter setValue:@(acute) forKey:@"inputAcuteAngle"];
	[filter setValue:[CIVector vectorWithX:point.x Y:height - point.y] forKey:@"inputCenter"];
	[filter setValue:@(radius) forKey:@"inputWidth"];
	imm_output = [filter valueForKey: @"outputImage"];
	
	// Add opaque background (if required)
	if (opaque) {
		filter = [CIFilter filterWithName:@"CIConstantColorGenerator"];
		[filter setDefaults];
		[filter setValue:backColor forKey:@"inputColor"];
		background = [filter valueForKey: @"outputImage"]; 
		filter = [CIFilter filterWithName:@"CISourceOverCompositing"];
		[filter setDefaults];
		[filter setValue:background forKey:@"inputBackgroundImage"];
		[filter setValue:imm_output forKey:@"inputImage"];
		output = [filter valueForKey:@"outputImage"];
	} else {
		output = imm_output;
	}
	
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
