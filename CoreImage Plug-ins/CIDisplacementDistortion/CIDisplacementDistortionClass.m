#import "Bitmap.h"
#import "CIDisplacementDistortionClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]
#define make_128(x) (x + 16 - (x % 16))

@implementation CIDisplacementDistortionClass
@synthesize panel;
@synthesize seaPlugins;
@synthesize nibArray;
@synthesize scale;
@synthesize textureLabel;

- (id)initWithManager:(SeaPlugins *)manager
{
	if (self = [super init]) {
		self.seaPlugins = manager;
		NSArray *tmpArray;
		[gOurBundle loadNibNamed:@"CIDisplacementDistortion" owner:self topLevelObjects:&tmpArray];
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
	return [gOurBundle localizedStringForKey:@"name" value:@"Displacement Distortion" table:NULL];
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
	
	if ([defaults objectForKey:@"CIDisplacementDistortion.scale"])
		self.scale = [defaults integerForKey:@"CIDisplacementDistortion.scale"];
	else
		self.scale = 50;
	refresh = YES;
	
	if (scale < 1 || scale > 350)
		self.scale = 50;
	
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
	
	if (refresh)
		[self execute];
	[pluginData apply];
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	if ([pluginData window]) [NSApp endSheet:panel];
	[panel orderOut:self];
	success = YES;
	if (newdata) {
		free(newdata);
		newdata = NULL;
	}
	
	[defaults setInteger:scale forKey:@"CICrystallize.scale"];
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
	return success;
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
	PluginData *pluginData = [seaPlugins data];
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	
	if (texturePath) {
		texturePath = nil;
	}
	
	[openPanel setTreatsFilePackagesAsDirectories:YES];
	[openPanel setDelegate:self];
	openPanel.allowedFileTypes = [NSImage imageTypes];
	openPanel.directoryURL = [[[NSBundle mainBundle] resourceURL] URLByAppendingPathComponent:@"textures"];
	if ([pluginData window])
		[panel setAlphaValue:0.4];
	
	if (texturePath) {
		texturePath = nil;
	}
	
	[openPanel beginSheetModalForWindow:[pluginData window] ? [pluginData window] : self.panel completionHandler:^(NSInteger result) {
		[panel setAlphaValue:1.0];
		if (result == NSOKButton) {
			NSURL *fileURL = [openPanel URL];
			texturePath = [fileURL path];
			NSString *localStr = [gOurBundle localizedStringForKey:@"texture label" value:@"Texture: %@" table:NULL];
			[textureLabel setStringValue:[NSString stringWithFormat:localStr, [[texturePath lastPathComponent] stringByDeletingPathExtension]]];
		}
		refresh = YES;
		[self preview:nil];
	}];
}

#define CLASSMETHOD displace
#include "CICommon.mi"

- (unsigned char *)displace:(PluginData *)pluginData withBitmap:(unsigned char *)data
{
	CIContext *context;
	CIImage *input, *imm_output, *crop_output, *output, *background, *texture_output;
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
	
	// Run tile filter
	filter = [CIFilter filterWithName:@"CIAffineTile"];
	[filter setDefaults];
	if (texturePath)
		[filter setValue:[CIImage imageWithContentsOfURL:[NSURL fileURLWithPath:texturePath]] forKey:@"inputImage"];
	else
		[filter setValue:[CIImage imageWithContentsOfURL:[NSURL fileURLWithPath:defaultPath]] forKey:@"inputImage"];
	[filter setValue:[NSAffineTransform transform] forKey:@"inputTransform"];
	texture_output = [filter valueForKey: @"outputImage"];
	
	// Run filter
	filter = [CIFilter filterWithName:@"CIDisplacementDistortion"];
	if (filter == NULL) {
		@throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIDisplacementDistortion"] userInfo:NULL];
	}
	[filter setDefaults];
	[filter setValue:input forKey:@"inputImage"];
	[filter setValue:texture_output forKey:@"inputDisplacementImage"];
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
