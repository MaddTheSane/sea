#import "Bitmap.h"
#import "CITorusLensClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

#define make_128(x) (x + 16 - (x % 16))

@implementation CITorusLensClass
@synthesize seaPlugins;
@synthesize panel;

- (id)initWithManager:(SeaPlugins *)manager
{
	if (self = [super init]) {
		seaPlugins = manager;
		[NSBundle loadNibNamed:@"CITorusLens" owner:self];
		newdata = NULL;
	}
	
	return self;
}

- (int)type
{
	return 1;
}

- (int)points
{
	return 3;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Torus Lens" table:NULL];
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
	
	if ([gUserDefaults objectForKey:@"CITorusLens.refraction"])
		refraction = [gUserDefaults floatForKey:@"CITorusLens.refraction"];
	else
		refraction = 1.7;
	
	if (refraction < -5.0 || refraction > 5.0)
		refraction = 1.7;
		
	[refractionLabel setStringValue:[NSString stringWithFormat:@"%.1f", refraction]];
	[refractionSlider setFloatValue:refraction];
	
	refresh = YES;
	success = NO;
	pluginData = [(SeaPlugins *)seaPlugins data];
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
	PluginData *pluginData;
	
	pluginData = [(SeaPlugins *)seaPlugins data];
	if (refresh) [self execute];
	[pluginData apply];
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	if ([pluginData window]) [NSApp endSheet:panel];
	[panel orderOut:self];
	success = YES;
	if (newdata) { free(newdata); newdata = NULL; }
		
	[gUserDefaults setFloat:refraction forKey:@"CITorusLens.refraction"];
}

- (void)reapply
{
	PluginData *pluginData;
	
	pluginData = [(SeaPlugins *)seaPlugins data];
	//if ([pluginData spp] == 2 || [pluginData channel] != kAllChannels){
	newdata = malloc(make_128([pluginData width] * [pluginData height] * 4));
	//}
	[self execute];
	[pluginData apply];
	if (newdata) { free(newdata); newdata = NULL; }
}

- (BOOL)canReapply
{
	return NO;
}

- (IBAction)preview:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [(SeaPlugins *)seaPlugins data];
	if (refresh) [self execute];
	[pluginData preview];
	refresh = NO;
}

- (IBAction)cancel:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [(SeaPlugins *)seaPlugins data];
	[pluginData cancel];
	if (newdata) { free(newdata); newdata = NULL; }
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	[NSApp endSheet:panel];
	[panel orderOut:self];
	success = NO;
}

- (IBAction)update:(id)sender
{
	PluginData *pluginData;
	
	refraction = [refractionSlider floatValue];
	
	[panel setAlphaValue:1.0];
	
	[refractionLabel setStringValue:[NSString stringWithFormat:@"%.1f", refraction]];
	
	refresh = YES;
	if ([[NSApp currentEvent] type] == NSLeftMouseUp || [sender tag] == 99) {
		[self preview:self];
		pluginData = [(SeaPlugins *)seaPlugins data];
		if ([pluginData window]) [panel setAlphaValue:0.4];
	}
}

- (void)execute
{
	PluginData *pluginData;

	pluginData = [(SeaPlugins *)seaPlugins data];
	if ([pluginData spp] == 2) {
		[self executeGrey:pluginData];
	}
	else {
		[self executeColor:pluginData];
	}
}

- (void)executeGrey:(PluginData *)pluginData
{
	IntRect selection;
	int i, spp, width, height;
	unsigned char *data, *resdata, *overlay, *replace;
	int vec_len, max;
	
	// Set-up plug-in
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:kReplacingBehaviour];
	selection = [pluginData selection];
	
	// Get plug-in data
	width = [pluginData width];
	height = [pluginData height];
	spp = [pluginData spp];
	vec_len = width * height * spp;
	if (vec_len % 16 == 0) { vec_len /= 16; }
	else { vec_len /= 16; vec_len++; }
	data = [pluginData data];
	overlay = [pluginData overlay];
	replace = [pluginData replace];
	
	// Convert from GA to ARGB
	for (i = 0; i < width * height; i++) {
		newdata[i * 4] = data[i * 2 + 1];
		newdata[i * 4 + 1] = data[i * 2];
		newdata[i * 4 + 2] = data[i * 2];
		newdata[i * 4 + 3] = data[i * 2];
	}
	
	// Run CoreImage effect
	resdata = [self executeChannel:pluginData withBitmap:newdata];
	
	// Convert from output to GA
	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height))
		max = selection.size.width * selection.size.height;
	else
		max = width * height;
	for (i = 0; i < max; i++) {
		newdata[i * 2] = resdata[i * 4];
		newdata[i * 2 + 1] = resdata[i * 4 + 3];
	}
	
	// Copy to destination
	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height)) {
		for (i = 0; i < selection.size.height; i++) {
			memset(&(replace[width * (selection.origin.y + i) + selection.origin.x]), 0xFF, selection.size.width);
			memcpy(&(overlay[(width * (selection.origin.y + i) + selection.origin.x) * 2]), &(newdata[selection.size.width * 2 * i]), selection.size.width * 2);
		}
	}
	else {
		memset(replace, 0xFF, width * height);
		memcpy(overlay, newdata, width * height * 2);
	}
}

- (void)executeColor:(PluginData *)pluginData
{
#ifdef __ppc__
	vector unsigned char TOGGLERGBF = (vector unsigned char)(0x03, 0x00, 0x01, 0x02, 0x07, 0x04, 0x05, 0x06, 0x0B, 0x08, 0x09, 0x0A, 0x0F, 0x0C, 0x0D, 0x0E);
	vector unsigned char TOGGLERGBR = (vector unsigned char)(0x01, 0x02, 0x03, 0x00, 0x05, 0x06, 0x07, 0x04, 0x09, 0x0A, 0x0B, 0x08, 0x0D, 0x0E, 0x0F, 0x0C);
	vector unsigned char *vdata, *voverlay, *vresdata;
#else
	__m128i opaquea = _mm_set1_epi32(0x000000FF);
	__m128i *vdata, *voverlay, *vresdata;
	__m128i vstore;
#endif
	IntRect selection;
	int i, width, height;
	unsigned char *data, *resdata, *overlay, *replace;
	int vec_len;
	
	// Set-up plug-in
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:kReplacingBehaviour];
	selection = [pluginData selection];
	
	// Get plug-in data
	width = [pluginData width];
	height = [pluginData height];
	vec_len = width * height * 4;
	if (vec_len % 16 == 0) { vec_len /= 16; }
	else { vec_len /= 16; vec_len++; }
	data = [pluginData data];
	overlay = [pluginData overlay];
	replace = [pluginData replace];
	premultiplyBitmap(4, newdata, data, width * height);
	// Convert from RGBA to ARGB
#ifdef __ppc__
	vdata = (vector unsigned char *)newdata;
	for (i = 0; i < vec_len; i++) {
		vdata[i] = vec_perm(vdata[i], vdata[i], TOGGLERGBF);
	}
#else
	vdata = (__m128i *)newdata;
	for (i = 0; i < vec_len; i++) {
		vstore = _mm_srli_epi32(vdata[i], 24);
		vdata[i] = _mm_slli_epi32(vdata[i], 8);
		vdata[i] = _mm_add_epi32(vdata[i], vstore);
	}
#endif
	
	// Run CoreImage effect (exception handling is essential because we've altered the image data)
@try {
	resdata = [self executeChannel:pluginData withBitmap:newdata];
}
@catch (NSException *exception) {
#ifdef __ppc__
	for (i = 0; i < vec_len; i++) {
		vdata[i] = vec_perm(vdata[i], vdata[i], TOGGLERGBR);
	}
#else
	for (i = 0; i < vec_len; i++) {
		vstore = _mm_slli_epi32(vdata[i], 24);
		vdata[i] = _mm_srli_epi32(vdata[i], 8);
		vdata[i] = _mm_add_epi32(vdata[i], vstore);
	}
#endif
	NSLog(@"%@", [exception reason]);
	return;
}
	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height)) {
		unpremultiplyBitmap(4, resdata, resdata, selection.size.width * selection.size.height);
	}else {
		unpremultiplyBitmap(4, resdata, resdata, width * height);
	}
	// Convert from ARGB to RGBA
#ifdef __ppc__
	for (i = 0; i < vec_len; i++) {
		vdata[i] = vec_perm(vdata[i], vdata[i], TOGGLERGBR);
	}
#else
	for (i = 0; i < vec_len; i++) {
		vstore = _mm_slli_epi32(vdata[i], 24);
		vdata[i] = _mm_srli_epi32(vdata[i], 8);
		vdata[i] = _mm_add_epi32(vdata[i], vstore);
	}
#endif
	
	// Copy to destination
	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height)) {
		for (i = 0; i < selection.size.height; i++) {
			memset(&(replace[width * (selection.origin.y + i) + selection.origin.x]), 0xFF, selection.size.width);
			memcpy(&(overlay[(width * (selection.origin.y + i) + selection.origin.x) * 4]), &(resdata[selection.size.width * 4 * i]), selection.size.width * 4);
		}
	}
	else {
		memset(replace, 0xFF, width * height);
		memcpy(overlay, resdata, width * height * 4);
	}
}

- (unsigned char *)executeChannel:(PluginData *)pluginData withBitmap:(unsigned char *)data
{
	int i, vec_len, width, height, channel;
	unsigned char ormask[16], *resdata, *datatouse;
	#ifdef __ppc__
	vector unsigned char TOALPHA = (vector unsigned char)(0x10, 0x00, 0x00, 0x00, 0x10, 0x04, 0x04, 0x04, 0x10, 0x08, 0x08, 0x08, 0x10, 0x0C, 0x0C, 0x0C);
	vector unsigned char HIGHVEC = (vector unsigned char)(0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF);
	vector unsigned char *vdata, *rvdata, orvmask;
	#else
	__m128i *vdata, *rvdata, orvmask;
	#endif
	
	// Make adjustments for the channel
	channel = [pluginData channel];
	datatouse = data;
	if (channel == kPrimaryChannels || channel == kAlphaChannel) {
		width = [pluginData width];
		height = [pluginData height];
		vec_len = width * height * 4;
		if (vec_len % 16 == 0) { vec_len /= 16; }
		else { vec_len /= 16; vec_len++; }
		#ifdef __ppc__
		vdata = (vector unsigned char *)data; // NB: data may equal newdata
		rvdata = (vector unsigned char *)newdata;
		#else
		vdata = (__m128i *)data;
		rvdata = (__m128i *)newdata;
		#endif
		datatouse = newdata;
		if (channel == kPrimaryChannels) {
			for (i = 0; i < 16; i++) {
				ormask[i] = (i % 4 == 0) ? 0xFF : 0x00;
			}
			memcpy(&orvmask, ormask, 16);
			#ifdef __ppc__
			for (i = 0; i < vec_len; i++) {
				rvdata[i] = vec_or(vdata[i], orvmask);
			}
			#else
			for (i = 0; i < vec_len; i++) {
				rvdata[i] = _mm_or_si128(vdata[i], orvmask);
			}
			#endif
		}
		else if (channel == kAlphaChannel) {
			#ifdef __ppc__
			for (i = 0; i < vec_len; i++) {
				rvdata[i] = vec_perm(vdata[i], HIGHVEC, TOALPHA);
			}
			#else
			for (i = 0; i < width * height; i++) {
				newdata[i * 4 + 1] = newdata[i * 4 + 2] = newdata[i * 4 + 3] = data[i * 4];
				newdata[i * 4] = 255;
			}
			#endif
		}
	}
	
	// Run CoreImage effect
	resdata = [self torus:pluginData withBitmap:datatouse];
	
	return resdata;
}

- (unsigned char *)torus:(PluginData *)pluginData withBitmap:(unsigned char *)data
{
	CIContext *context;
	CIImage *input, *imm_output, *crop_output, *output, *background;
	CIFilter *filter;
	CGImageRef temp_image;
	NSBitmapImageRep *temp_rep;
	CGSize size;
	CGRect rect;
	int width, height;
	unsigned char *resdata;
	IntRect selection;
	IntPoint point, apoint;
	BOOL opaque;
	CIColor *backColor;
	IntPoint point1, point2, point3;
	float lens_width, lens_radius;
	
	// Check if image is opaque
	opaque = ![pluginData hasAlpha];
	if (opaque && [pluginData spp] == 4) backColor = [CIColor colorWithRed:[[pluginData backColor:YES] redComponent] green:[[pluginData backColor:YES] greenComponent] blue:[[pluginData backColor:YES] blueComponent]];
	else if (opaque) backColor = [CIColor colorWithRed:[[pluginData backColor:YES] whiteComponent] green:[[pluginData backColor:YES] whiteComponent] blue:[[pluginData backColor:YES] whiteComponent]];
	
	// Find core image context
	context = [CIContext contextWithCGContext:[[NSGraphicsContext currentContext] graphicsPort] options:@{kCIContextWorkingColorSpace: (id)[pluginData displayProf], kCIContextOutputColorSpace: (id)[pluginData displayProf]}];
	
	// Get plug-in data
	width = [pluginData width];
	height = [pluginData height];
	selection = [pluginData selection];
	point1 = [pluginData point:0];
	point2 = [pluginData point:1];
	point3 = [pluginData point:2];
	lens_radius = abs(point2.x - point1.x) * abs(point2.x - point1.x) + abs(point2.y - point1.y) * abs(point2.y - point1.y);
	lens_radius = sqrt(lens_radius);
	lens_width = abs(point3.x - point1.x) * abs(point3.x - point1.x) + abs(point3.y - point1.y) * abs(point3.y - point1.y);
	lens_width = sqrt(lens_width);
	lens_width = abs(lens_width - lens_radius);
	lens_radius += lens_width;
	
	// Create core image with data
	size.width = width;
	size.height = height;
	input = [CIImage imageWithBitmapData:[NSData dataWithBytesNoCopy:data length:width * height * 4 freeWhenDone:NO] bytesPerRow:width * 4 size:size format:kCIFormatARGB8 colorSpace:[pluginData displayProf]];
	
	// Run filter
	filter = [CIFilter filterWithName:@"CITorusLensDistortion"];
	if (filter == NULL) {
		@throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CITorusLensDistortion"] userInfo:NULL];
	}
	[filter setDefaults];
	[filter setValue:input forKey:@"inputImage"];
	[filter setValue:[CIVector vectorWithX:point1.x Y:height - point1.y] forKey:@"inputCenter"];
	[filter setValue:@(lens_radius) forKey:@"inputRadius"];
	[filter setValue:@(lens_width) forKey:@"inputWidth"];
	[filter setValue:@(refraction) forKey:@"inputRefraction"];
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
	}
	else {
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
		
	}
	else {
	
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
