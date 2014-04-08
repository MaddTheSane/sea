#import "CICheckerboardClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]
#define make_128(x) (x + 16 - (x % 16))

@implementation CICheckerboardClass
@synthesize seaPlugins;

- (id)initWithManager:(SeaPlugins *)manager
{
	if (self = [super init]) {
		self.seaPlugins = manager;
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
	return [gOurBundle localizedStringForKey:@"name" value:@"Checkerboard" table:NULL];
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
	PluginData *pluginData = [seaPlugins data];
	
	[self execute];
	[pluginData apply];
	success = YES;
}

- (void)reapply
{
	[self run];
}

- (BOOL)canReapply
{
	return NO;
}

- (void)execute
{
	PluginData *pluginData = [seaPlugins data];
	
	if ([pluginData spp] == 2) {
		[self executeGrey:pluginData];
	} else {
		[self executeColor:pluginData];
	}
}

- (void)executeGrey:(PluginData *)pluginData
{
	IntRect selection;
	int i, j, width, height;
	unsigned char *overlay, *resdata;
	
	// Set-up plug-in
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:kNormalBehaviour];
	selection = [pluginData selection];
	
	// Get plug-in data
	width = [pluginData width];
	height = [pluginData height];
	overlay = [pluginData overlay];
	
	// Run CoreImage effect
	resdata = [self checkerboard:pluginData];
	
	// Copy to destination
	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height)) {
		for (j = 0; j < selection.size.height; j++) {
			for (i = 0; i < selection.size.width; i++) {
				overlay[(width * (selection.origin.y + j) + selection.origin.x + i) * 2] = resdata[i * 4];
				overlay[(width * (selection.origin.y + j) + selection.origin.x + i) * 2 + 1] = resdata[i * 4 + 3];
			}
		}
	} else {
		for (i = 0; i < width * height; i++) {
			overlay[i * 2] = resdata[i * 4];
			overlay[i * 2 + 1] = resdata[i * 4 + 3];
		}
	}
}

- (void)executeColor:(PluginData *)pluginData
{
	IntRect selection;
	int i, width, height;
	unsigned char *resdata, *overlay;
	
	// Set-up plug-in
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:kNormalBehaviour];
	selection = [pluginData selection];
	
	// Get plug-in data
	width = [pluginData width];
	height = [pluginData height];
	overlay = [pluginData overlay];
	
	// Run CoreImage effect (exception handling is essential because we've altered the image data)
	resdata = [self checkerboard:pluginData];

	// Copy to destination
	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height)) {
		for (i = 0; i < selection.size.height; i++) {
			memcpy(&(overlay[(width * (selection.origin.y + i) + selection.origin.x) * 4]), &(resdata[selection.size.width * 4 * i]), selection.size.width * 4);
		}
	} else {
		memcpy(overlay, resdata, width * height * 4);
	}
}

- (unsigned char *)checkerboard:(PluginData *)pluginData
{
	CIContext *context;
	CIImage *crop_output, *output;
	CIFilter *filter;
	CGImageRef temp_image;
	CGSize size;
	CGRect rect;
	int width, height;
	unsigned char *resdata;
	IntRect selection;
	IntPoint point, apoint;
	CIColor *backColorAlpha, *foreColorAlpha;
	int amount;
	
	// Get colors
	foreColorAlpha = [[CIColor alloc] initWithColor:[pluginData foreColor:YES]];
	backColorAlpha = [[CIColor alloc] initWithColor:[pluginData backColor:YES]];
	
	// Find core image context
	context = [CIContext contextWithCGContext:[[NSGraphicsContext currentContext] graphicsPort] options:@{kCIContextWorkingColorSpace: (id)[pluginData displayProf], kCIContextOutputColorSpace: (id)[pluginData displayProf]}];
	
	// Get plug-in data
	width = [pluginData width];
	height = [pluginData height];
	selection = [pluginData selection];
	point = [pluginData point:0];
	apoint = [pluginData point:1];
	amount = MAX(abs(apoint.x - point.x), abs(apoint.y - point.y));
	
	// Create core image with data
	size.width = width;
	size.height = height;
	
	// Run filter
	filter = [CIFilter filterWithName:@"CICheckerboardGenerator"];
	if (filter == NULL) {
		@throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CICircleSplash"] userInfo:NULL];
	}
	[filter setDefaults];
	[filter setValue:[CIVector vectorWithX:point.x Y:height - point.y] forKey:@"inputCenter"];
	[filter setValue:backColorAlpha forKey:@"inputColor0"];
	[filter setValue:foreColorAlpha forKey:@"inputColor1"];
	[filter setValue:@(amount) forKey:@"inputWidth"];
	[filter setValue:@1.0f forKey:@"inputSharpness"];
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
