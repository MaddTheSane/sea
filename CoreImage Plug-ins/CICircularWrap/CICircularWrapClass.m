#import "CICircularWrapClass.h"
#include <math.h>

#define gOurBundle [NSBundle bundleForClass:[self class]]
#define make_128(x) (x + 16 - (x % 16))

@implementation CICircularWrapClass
@synthesize seaPlugins;
@synthesize panel;
@synthesize nibArray;
@synthesize angle;

- (id)initWithManager:(SeaPlugins *)manager
{
	if (self = [super init]) {
		NSArray *tmpArray;
		self.seaPlugins = manager;
		[gOurBundle loadNibNamed:@"CICircularWrap" owner:self topLevelObjects:&tmpArray];
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
	return [gOurBundle localizedStringForKey:@"name" value:@"Circular Wrap" table:NULL];
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
	IntPoint point, apoint;
	int radius;
	
	pluginData = [seaPlugins data];
	
	[self determineContentBorders:pluginData];

	point = [pluginData point:0];
	apoint = [pluginData point:1];
	radius = (apoint.x - point.x) * 2 + (apoint.y - point.y) * 2;
	radius = sqrt(radius);

	self.angle = 0.0;
	if (bounds.size.width < M_PI * radius)
		self.angle = M_PI / 2.0 + bounds.size.width / (2.0 * radius);
	else if (bounds.size.width < 2.0 * M_PI * radius)
		self.angle = (- 3 * M_PI + bounds.size.width / radius) / 2.0;
	
	refresh = YES;
	success = NO;
	if ([pluginData spp] == 2 || [pluginData channel] != kAllChannels)
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
	[panel orderOut:sender];
	success = YES;
	if (newdata) {
		free(newdata);
		newdata = NULL;
	}
		
	[defaults setFloat:angle forKey:@"CICircularWrap.angle"];
}

- (void)reapply
{
	PluginData *pluginData = [seaPlugins data];
	
	if ([pluginData spp] == 2 || [pluginData channel] != kAllChannels) newdata = malloc(make_128([pluginData width] * [pluginData height] * 4));
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
	[panel orderOut:sender];
	success = NO;
}

- (IBAction)update:(id)sender
{
	PluginData *pluginData;
	
	if (angle > 0.0 && angle < 0.02)
		self.angle = 0.0; /* Force a zero point */
	
	[panel setAlphaValue:1.0];
	
	refresh = YES;
	if ([[NSApp currentEvent] type] == NSLeftMouseUp) {
		[self preview:sender];
		pluginData = [seaPlugins data];
		if ([pluginData window])
			[panel setAlphaValue:0.4];
	}
}
#define NO_PREMULTIPLY
#define CLASSMETHOD wrap
#include "CICommon.mi"

- (void)determineContentBorders:(PluginData *)pluginData
{
	int contentLeft, contentRight, contentTop, contentBottom;
	int width, height;
	int spp;
	unsigned char *data;
	int i, j, k;
	IntRect selection;
	
	// Start out with invalid content borders
	contentLeft = contentRight = contentTop = contentBottom =  -1;
	
	// Select the appropriate data for working out the content borders
	data = [pluginData data];
	width = [pluginData width];
	height = [pluginData height];
	selection = [pluginData selection];
	spp = [pluginData spp];
	
	// Determine left content margin
	for (i = 0; i < width && contentLeft == -1; i++) {
		for (j = 0; j < height && contentLeft == -1; j++) {
			if (data[j * width * spp + i * spp + (spp - 1)] != 0) {
				for (k = 0; k < spp; k++) {
					if (data[j * width * spp + i * spp + k] != data[k])
						contentLeft = i;
				}
			}
		}
	}
	
	// Determine right content margin
	for (i = width - 1; i >= 0 && contentRight == -1; i--) {
		for (j = 0; j < height && contentRight == -1; j++) {
			if (data[j * width * spp + i * spp + (spp - 1)] != 0) {
				for (k = 0; k < spp; k++) {
					if (data[j * width * spp + i * spp + k] != data[k])
						contentRight = i;
				}
			}
		}
	}
	
	// Determine top content margin
	for (j = 0; j < height && contentTop == -1; j++) {
		for (i = 0; i < width && contentTop == -1; i++) {
			if (data[j * width * spp + i * spp + (spp - 1)] != 0) {
				for (k = 0; k < spp; k++) {
					if (data[j * width * spp + i * spp + k] != data[k])
						contentTop = j;
				}
			}
		}
	}
	
	// Determine bottom content margin
	for (j = height - 1; j >= 0 && contentBottom == -1; j--) {
		for (i = 0; i < width && contentBottom == -1; i++) {
			if (data[j * width * spp + i * spp + (spp - 1)] != 0) {
				for (k = 0; k < spp; k++) {
					if (data[j * width * spp + i * spp + k] != data[k])
						contentBottom = j;
				}
			}
		}
	}
	
	// Put into bounds
	if (contentLeft != -1 && contentTop != -1 && contentRight != -1 && contentBottom != -1) {
		bounds.origin.x = contentLeft;
		bounds.origin.y = contentTop;
		bounds.size.width = contentRight - contentLeft + 1;
		bounds.size.height = contentBottom - contentTop + 1;
		boundsValid = YES;
	} else {
		boundsValid = NO;
	}
}

- (unsigned char *)wrap:(PluginData *)pluginData withBitmap:(unsigned char *)data
{
	CIContext *context;
	CIImage *input, *crop_output, *imm_output_1, *imm_output_2, *imm_output_3, *output, *background;
	CIFilter *filter;
	CGImageRef temp_image;
	CGSize size;
	CGRect rect;
	int width, height;
	unsigned char *resdata;
	IntRect selection;
	IntPoint point, apoint;
	BOOL opaque = ![pluginData hasAlpha];
	CIColor *backColor;
	int radius;
	NSAffineTransform *offsetTransform;
	
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
	radius = (apoint.x - point.x) * (apoint.x - point.x) + (apoint.y - point.y) * (apoint.y - point.y);
	radius = sqrt(radius);
	
	// Create core image with data
	size.width = width;
	size.height = height;
	input = [CIImage imageWithBitmapData:[NSData dataWithBytesNoCopy:data length:width * height * 4 freeWhenDone:NO] bytesPerRow:width * 4 size:size format:kCIFormatARGB8 colorSpace:[pluginData displayProf]];
	
	// Position correctly
	if (boundsValid) {
		// Crop to selection
		filter = [CIFilter filterWithName:@"CICrop"];
		[filter setDefaults];
		[filter setValue:input forKey:@"inputImage"];
		[filter setValue:[CIVector vectorWithX:bounds.origin.x Y:height - bounds.size.height - bounds.origin.y Z:bounds.size.width W:bounds.size.height] forKey:@"inputRectangle"];
		imm_output_1 = [filter valueForKey:@"outputImage"];
		
		// Offset properly
		filter = [CIFilter filterWithName:@"CIAffineTransform"];
		[filter setDefaults];
		[filter setValue:imm_output_1 forKey:@"inputImage"];
		offsetTransform = [NSAffineTransform transform];
		[offsetTransform translateXBy:-bounds.origin.x yBy:-height + bounds.origin.y + bounds.size.height];
		[filter setValue:offsetTransform forKey:@"inputTransform"];
		imm_output_2 = [filter valueForKey:@"outputImage"];
	} else {
		imm_output_2 = input;
	}
	
	// Run filter
	filter = [CIFilter filterWithName:@"CICircularWrap"];
	if (filter == NULL) {
		@throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CICircularWrap"] userInfo:NULL];
	}
	[filter setDefaults];
	[filter setValue:imm_output_2 forKey:@"inputImage"];
	[filter setValue:[CIVector vectorWithX:point.x Y:height - point.y] forKey:@"inputCenter"];
	[filter setValue:@(radius) forKey:@"inputRadius"];
	[filter setValue:@(-angle) forKey:@"inputAngle"];
	imm_output_3 = [filter valueForKey: @"outputImage"];
	
	// Add opaque background (if required)
	if (opaque) {
		filter = [CIFilter filterWithName:@"CIConstantColorGenerator"];
		[filter setDefaults];
		[filter setValue:backColor forKey:@"inputColor"];
		background = [filter valueForKey: @"outputImage"]; 
		filter = [CIFilter filterWithName:@"CISourceOverCompositing"];
		[filter setDefaults];
		[filter setValue:background forKey:@"inputBackgroundImage"];
		[filter setValue:imm_output_3 forKey:@"inputImage"];
		output = [filter valueForKey:@"outputImage"];
	} else {
		output = imm_output_3;
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
