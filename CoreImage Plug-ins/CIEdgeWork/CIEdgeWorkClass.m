#import "Bitmap.h"
#import "CIEdgeWorkClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]



#define make_128(x) (x + 16 - (x % 16))

@implementation CIEdgeWorkClass
@synthesize panel;
@synthesize seaPlugins;
@synthesize radius;

- (id)initWithManager:(SeaPlugins *)manager
{
	if (self = [super init]) {
		seaPlugins = manager;
		[NSBundle loadNibNamed:@"CIEdgeWork" owner:self];
	}
	return self;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Edges" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Stylize" table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

- (void)run
{
	PluginData *pluginData;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	if ([defaults objectForKey:@"CIEdgeWork.radius"])
		self.radius = [defaults floatForKey:@"CIEdgeWork.radius"];
	else
		self.radius = 3.0;
	refresh = YES;
	
	if (radius < 0.1 || radius > 20.0)
		self.radius = 3.0;
	
	[radiusLabel setStringValue:[NSString stringWithFormat:@"%.1f", radius]];
	
	[radiusSlider setDoubleValue:radius];
	
	success = NO;
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
	
	if (refresh) [self execute];
	[pluginData apply];
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	if ([pluginData window]) [NSApp endSheet:panel];
	[panel orderOut:self];
	success = YES;
	if (newdata) { free(newdata); newdata = NULL; }
		
	[defaults setFloat:radius forKey:@"CIEdgeWork.radius"];
}

- (void)reapply
{
	PluginData *pluginData;
	
	pluginData = [seaPlugins data];
	//if ([pluginData spp] == 2 || [pluginData channel] != kAllChannels){
	newdata = malloc(make_128([pluginData width] * [pluginData height] * 4));
	//}
	[self execute];
	[pluginData apply];
	if (newdata) { free(newdata); newdata = NULL; }
}

- (BOOL)canReapply
{
	return success;
}

- (IBAction)preview:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [seaPlugins data];
	if (refresh) [self execute];
	[pluginData preview];
	refresh = NO;
}

- (IBAction)cancel:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [seaPlugins data];
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
	
	radius = roundf([radiusSlider floatValue] * 10.0) / 10.0;
	
	[panel setAlphaValue:1.0];
	
	[radiusLabel setStringValue:[NSString stringWithFormat:@"%.1f", radius]];
	
	refresh = YES;
	if ([[NSApp currentEvent] type] == NSLeftMouseUp) { 
		[self preview:self];
		pluginData = [seaPlugins data];
		if ([pluginData window]) [panel setAlphaValue:0.4];
	}
}

- (void)execute
{
	PluginData *pluginData;

	pluginData = [seaPlugins data];
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
	vec_len = width * height * spp;
	vec_len = width * height * spp;
	if (vec_len % 16 == 0) {
		vec_len /= 16;
	} else {
		vec_len /= 16;
		vec_len++;
	}
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
	} else {
		memset(replace, 0xFF, width * height);
		memcpy(overlay, newdata, width * height * 2);
	}
}

- (void)executeColor:(PluginData *)pluginData
{
	__m128i *vdata;
	__m128i vstore;
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
	if (vec_len % 16 == 0) {
		vec_len /= 16;
	} else {
		vec_len /= 16;
		vec_len++;
	}
	data = [pluginData data];
	overlay = [pluginData overlay];
	replace = [pluginData replace];
	premultiplyBitmap(4, newdata, data, width * height);
	
	// Convert from RGBA to ARGB
	vdata = (__m128i *)newdata;
	for (i = 0; i < vec_len; i++) {
		vstore = _mm_srli_epi32(vdata[i], 24);
		vdata[i] = _mm_slli_epi32(vdata[i], 8);
		vdata[i] = _mm_add_epi32(vdata[i], vstore);
	}
	
	// Run CoreImage effect (exception handling is essential because we've altered the image data)
	@try {
		resdata = [self executeChannel:pluginData withBitmap:newdata];
	}
	@catch (NSException *exception) {
		for (i = 0; i < vec_len; i++) {
			vstore = _mm_slli_epi32(vdata[i], 24);
			vdata[i] = _mm_srli_epi32(vdata[i], 8);
			vdata[i] = _mm_add_epi32(vdata[i], vstore);
		}
		NSLog(@"%@", [exception reason]);
		return;
	}
	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height)) {
		unpremultiplyBitmap(4, resdata, resdata, selection.size.width * selection.size.height);
	}else {
		unpremultiplyBitmap(4, resdata, resdata, width * height);
	}
	// Convert from ARGB to RGBA
	for (i = 0; i < vec_len; i++) {
		vstore = _mm_slli_epi32(vdata[i], 24);
		vdata[i] = _mm_srli_epi32(vdata[i], 8);
		vdata[i] = _mm_add_epi32(vdata[i], vstore);
	}
	
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
	__m128i *vdata, *rvdata, orvmask;
	
	// Make adjustments for the channel
	channel = [pluginData channel];
	datatouse = data;
	if (channel == kPrimaryChannels || channel == kAlphaChannel) {
		width = [pluginData width];
		height = [pluginData height];
		vec_len = width * height * 4;
		if (vec_len % 16 == 0) { vec_len /= 16; }
		else { vec_len /= 16; vec_len++; }
		vdata = (__m128i *)data;
		rvdata = (__m128i *)newdata;
		datatouse = newdata;
		if (channel == kPrimaryChannels) {
			for (i = 0; i < 16; i++) {
				ormask[i] = (i % 4 == 0) ? 0xFF : 0x00;
			}
			memcpy(&orvmask, ormask, 16);
			for (i = 0; i < vec_len; i++) {
				rvdata[i] = _mm_or_si128(vdata[i], orvmask);
			}
		}
		else if (channel == kAlphaChannel) {
			for (i = 0; i < width * height; i++) {
				newdata[i * 4 + 1] = newdata[i * 4 + 2] = newdata[i * 4 + 3] = data[i * 4];
				newdata[i * 4] = 255;
			}
		}
	}
	
	// Run CoreImage effect
	resdata = [self edges:pluginData withBitmap:datatouse];
	
	return resdata;
}

- (unsigned char *)edges:(PluginData *)pluginData withBitmap:(unsigned char *)data
{
	CIContext *context;
	CIImage *input, *crop_output, *imm_output, *imm_output2, *output, *background;
	CIFilter *filter;
	CGImageRef temp_image;
	NSBitmapImageRep *temp_rep;
	CGSize size;
	CGRect rect;
	int width, height;
	unsigned char *resdata;
	BOOL opaque;
	CIColor *backColor, *foreColor;
	IntRect selection;
	
	// Check if image is opaque
	opaque = ![pluginData hasAlpha];
	if (opaque && [pluginData spp] == 4) backColor = [CIColor colorWithRed:[[pluginData backColor:YES] redComponent] green:[[pluginData backColor:YES] greenComponent] blue:[[pluginData backColor:YES] blueComponent]];
	else if (opaque) backColor = [CIColor colorWithRed:[[pluginData backColor:YES] whiteComponent] green:[[pluginData backColor:YES] whiteComponent] blue:[[pluginData backColor:YES] whiteComponent]];
	
	// Get foreground color
	if ([pluginData spp] == 4) foreColor = [CIColor colorWithRed:[[pluginData foreColor:YES] redComponent] green:[[pluginData foreColor:YES] greenComponent] blue:[[pluginData foreColor:YES] blueComponent] alpha:[[pluginData foreColor:YES] alphaComponent]];
	else foreColor = [CIColor colorWithRed:[[pluginData foreColor:YES] whiteComponent] green:[[pluginData foreColor:YES] whiteComponent] blue:[[pluginData foreColor:YES] whiteComponent] alpha:[[pluginData foreColor:YES] alphaComponent]];
	
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
	filter = [CIFilter filterWithName:@"CIEdgeWork"];
	if (filter == NULL) {
		@throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIEdgeWork"] userInfo:NULL];
	}
	[filter setDefaults];
	[filter setValue:input forKey:@"inputImage"];
	[filter setValue:@(radius) forKey:@"inputRadius"];
	imm_output = [filter valueForKey: @"outputImage"];

	// Add foreground
	filter = [CIFilter filterWithName:@"CIConstantColorGenerator"];
	[filter setDefaults];
	[filter setValue:foreColor forKey:@"inputColor"];
	background = [filter valueForKey: @"outputImage"];
	filter = [CIFilter filterWithName:@"CISourceInCompositing"];
	[filter setDefaults];
	[filter setValue:imm_output forKey:@"inputBackgroundImage"];
	[filter setValue:background forKey:@"inputImage"];
	imm_output2 = [filter valueForKey:@"outputImage"];
	
	// Add opaque background (if required)
	if (opaque) {
		filter = [CIFilter filterWithName:@"CIConstantColorGenerator"];
		[filter setDefaults];
		[filter setValue:backColor forKey:@"inputColor"];
		background = [filter valueForKey: @"outputImage"]; 
		filter = [CIFilter filterWithName:@"CISourceOverCompositing"];
		[filter setDefaults];
		[filter setValue:background forKey:@"inputBackgroundImage"];
		[filter setValue:imm_output2 forKey:@"inputImage"];
		output = [filter valueForKey:@"outputImage"];
	}
	else {
		output = imm_output2;
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
