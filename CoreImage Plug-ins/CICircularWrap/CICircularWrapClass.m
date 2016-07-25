#import "CICircularWrapClass.h"
#include <math.h>

#define gOurBundle [NSBundle bundleForClass:[self class]]
#define make_128(x) (x + 16 - (x % 16))

@implementation CICircularWrapClass
@synthesize angle;

- (instancetype)initWithManager:(SeaPlugins *)manager
{
	if (self = [super initWithManager:manager]) {
		NSArray *tmpArray;
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
	
	pluginData = [self.seaPlugins data];
	
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
	if (newdata) {
		free(newdata);
		newdata = NULL;
	}
		
	[defaults setFloat:angle forKey:@"CICircularWrap.angle"];
}

- (void)reapply
{
	PluginData *pluginData = [self.seaPlugins data];
	
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

- (IBAction)update:(id)sender
{
	if (angle > 0.0 && angle < 0.02)
		self.angle = 0.0; /* Force a zero point */
	
	[super update:sender];
}

- (void)executeColor:(PluginData *)pluginData
{
	__m128i *vdata;
	IntRect selection;
	int width, height;
	unsigned char *data, *resdata, *overlay, *replace;
	size_t vec_len;
	
	// Set-up plug-in
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:SeaOverlayBehaviourReplacing];
	selection = [pluginData selection];
	
	// Get plug-in data
	width = [pluginData width];
	height = [pluginData height];
	vec_len = width * height * 4;
	if (vec_len % 16 == 0) {
		vec_len /= 16;
	} else {
		vec_len /= 16;
		vec_len++;
	}
	data = [pluginData data];
	overlay = [pluginData overlay];
	replace = [pluginData replace];
	vdata = (__m128i *)data;
	dispatch_apply(vec_len, dispatch_get_global_queue(0, 0), ^(size_t i) {
		__m128i vstore = _mm_srli_epi32(vdata[i], 24);
		vdata[i] = _mm_slli_epi32(vdata[i], 8);
		vdata[i] = _mm_add_epi32(vdata[i], vstore);
	});
	
	// Run CoreImage effect (exception handling is essential because we've altered the image data)
	@try {
		resdata = [self executeChannel:pluginData withBitmap:data];
	}
	@catch (NSException *exception) {
		dispatch_apply(vec_len, dispatch_get_global_queue(0, 0), ^(size_t i) {
			__m128i vstore = _mm_slli_epi32(vdata[i], 24);
			vdata[i] = _mm_srli_epi32(vdata[i], 8);
			vdata[i] = _mm_add_epi32(vdata[i], vstore);
		});
		NSLog(@"%@", [exception reason]);
		return;
	}

	// Convert from ARGB to RGBA
	dispatch_apply(vec_len, dispatch_get_global_queue(0, 0), ^(size_t i) {
		__m128i vstore = _mm_slli_epi32(vdata[i], 24);
		vdata[i] = _mm_srli_epi32(vdata[i], 8);
		vdata[i] = _mm_add_epi32(vdata[i], vstore);
	});
	
	// Copy to destination
	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height)) {
		dispatch_apply(selection.size.height, dispatch_get_global_queue(0, 0), ^(size_t i) {
			memset(&(replace[width * (selection.origin.y + i) + selection.origin.x]), 0xFF, selection.size.width);
			memcpy(&(overlay[(width * (selection.origin.y + i) + selection.origin.x) * 4]), &(resdata[selection.size.width * 4 * i]), selection.size.width * 4);
		});
	} else {
		memset(replace, 0xFF, width * height);
		memcpy(overlay, resdata, width * height * 4);
	}
}

- (unsigned char *)coreImageEffect:(PluginData *)pluginData withBitmap:(unsigned char *)data
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
