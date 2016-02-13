#import "Bitmap.h"
#import "CIGlassDistortionClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]
#define make_128(x) (x + 16 - (x % 16))

@implementation CIGlassDistortionClass
@synthesize scale;

- (instancetype)initWithManager:(SeaPlugins *)manager
{
	if (self = [super initWithManager:manager]) {
		NSArray *tmpArray;
		[gOurBundle loadNibNamed:@"CIGlassDistortion" owner:self topLevelObjects:&tmpArray];
		self.nibArray = tmpArray;
	}
	
	return self;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Glass Distortion" table:NULL];
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
	
	if ([defaults objectForKey:@"CIGlassDistortion.scale"])
		self.scale = [defaults integerForKey:@"CIGlassDistortion.scale"];
	else
		self.scale = 200;
	refresh = YES;
	
	if (scale < 1 || scale > 500)
		self.scale = 200;
	
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
	
	[defaults setInteger:scale forKey:@"CICrystallize.scale"];
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

- (void)panelSelectionDidChange:(id)openPanel
{
	if ([[openPanel URLs] count] > 0) {
		texturePath = [[openPanel URLs][0] path];
		if (texturePath) {
			refresh = YES;
			[self preview:NULL];
		}
	}
}

- (IBAction)selectTexture:(id)sender
{
	PluginData *pluginData = [self.seaPlugins data];
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	NSURL *path = [[[NSBundle mainBundle] resourceURL] URLByAppendingPathComponent:@"textures"];
	
	if (texturePath) {
		texturePath = nil;
	}
	[openPanel setTreatsFilePackagesAsDirectories:YES];
	[openPanel setDelegate:self];
	if ([pluginData window])
		[panel setAlphaValue:0.4];
	
	[openPanel setDirectoryURL:path];
	[openPanel setAllowedFileTypes:[NSImage imageTypes]];
	[openPanel beginSheet:self.panel completionHandler:^(NSModalResponse returnCode) {
		NSString *localStr;
		if (returnCode == NSOKButton) {
			texturePath = [[openPanel URL] path];
			localStr = [gOurBundle localizedStringForKey:@"texture label" value:@"Texture: %@" table:nil];
			[textureLabel setStringValue:[NSString stringWithFormat:localStr, [[texturePath lastPathComponent] stringByDeletingPathExtension]]];
		}
		if (texturePath) {
			texturePath = NULL;
		}
		[panel setAlphaValue:1.0];
		refresh = YES;
		[self preview:NULL];
	}];
}

- (unsigned char *)coreImageEffect:(PluginData *)pluginData withBitmap:(unsigned char *)data
{
	CIContext *context;
	CIImage *input, *imm_output, *crop_output, *output, *background;
	CIFilter *filter;
	CGImageRef temp_image;
	CGSize size;
	CGRect rect;
	int width, height;
	unsigned char *resdata;
	BOOL opaque = ![pluginData hasAlpha];
	CIColor *backColor;
	IntRect selection;
	NSString *defaultPath = [[NSBundle bundleForClass:[self class]] pathForImageResource:@"default-distort"];
	
	if (opaque)
		backColor = [[CIColor alloc] initWithColor:[pluginData backColor:YES]];
		
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
	filter = [CIFilter filterWithName:@"CIGlassDistortion"];
	if (filter == NULL) {
		@throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIGlassDistortion"] userInfo:NULL];
	}
	[filter setDefaults];
	[filter setValue:input forKey:@"inputImage"];
	if (texturePath)
		[filter setValue:[CIImage imageWithContentsOfURL:[NSURL fileURLWithPath:texturePath]] forKey:@"inputTexture"];
	else
		[filter setValue:[CIImage imageWithContentsOfURL:[NSURL fileURLWithPath:defaultPath]] forKey:@"inputTexture"];
	[filter setValue:[CIVector vectorWithX:width / 2 Y:height / 2] forKey:@"inputCenter"];
	[filter setValue:@(scale) forKey:@"inputScale"];
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
