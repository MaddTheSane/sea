#include <math.h>
#include <tgmath.h>
#import "TexturizeClass.h"
#import "render.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation TexturizeClass
@synthesize overlap;
@synthesize width;
@synthesize height;
@synthesize tileable;

#if 0
- (void)setOverlap:(CGFloat)newOverlap
{
	overlap = round(newOverlap);
}

- (void)setWidth:(CGFloat)newWidth
{
	width = round(newWidth);
}

- (void)setHeight:(CGFloat)newHeight
{
	height = round(newHeight);
}
#endif

- (id)initWithManager:(SeaPlugins *)manager
{
	if (self = [super init]) {
		seaPlugins = manager;
		[NSBundle loadNibNamed:@"Texturize" owner:self];
	}
	
	return self;
}

- (int)type
{
	return kBasicPlugin;
}

-(int)points
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Texturize" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Document" table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

- (void)run
{
	PluginData *pluginData;
	NSString *smallTitle, *smallBody;
	int iwidth, iheight;
	
	pluginData = [seaPlugins data];
	
	iwidth = [pluginData width];
	iheight = [pluginData height];
	
	if (iwidth < 64 || iheight < 64) {
		NSAlert *alert = [[NSAlert alloc] init];
		smallTitle = [gOurBundle localizedStringForKey:@"small title" value:@"Image too small" table:NULL];
		smallBody = [gOurBundle localizedStringForKey:@"small body" value:@"The texturize plug-in can only be used with images that are larger than 64 pixels in both width and height." table:NULL];
		alert.messageText = smallTitle;
		alert.informativeText = smallBody;
		
		[alert runModal];
		return;
	}
	
	if ([gUserDefaults objectForKey:@"Texturize.overlap"])
		overlap = [gUserDefaults integerForKey:@"Texturize.overlap"];
	else
		overlap = 50.0;
	
	if (overlap < 5.0 || overlap > 100.0)
		overlap = 50.0;
	
	self.overlap = overlap;
	
	if ([gUserDefaults objectForKey:@"Texturize.width"])
		width = [gUserDefaults integerForKey:@"Texturize.width"];
	else
		width = 200.0;
	
	if (width < 120.0 || width > 500.0)
		width = 200.0;
	
	self.width = width;
	
	if ([gUserDefaults objectForKey:@"Texturize.height"])
		height = [gUserDefaults integerForKey:@"Texturize.height"];
	else
		height = 200.0;
	
	if (height < 120.0 || height > 500.0)
		height = 200.0;
	
	self.height = height;
	
	if ([gUserDefaults objectForKey:@"Texturize.tileable"])
		self.tileable = [gUserDefaults boolForKey:@"Texturize.tileable"];
	else
		self.tileable = YES;
	
	[progressBar setIndeterminate:YES];
	[progressBar setDoubleValue:0.0];
	
	success = NO;
	if ([pluginData window])
		[NSApp beginSheet:panel modalForWindow:[pluginData window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
	else
		[NSApp runModalForWindow:panel];
}

- (IBAction)apply:(id)sender
{
	PluginData *pluginData = [seaPlugins data];
	[self texturize];
	[pluginData apply];
	
	[NSApp stopModal];
	if ([pluginData window]) [NSApp endSheet:panel];
	[panel orderOut:self];
	success = YES;
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	[defaults setFloat:overlap forKey:@"Texturize.overlap"];
	[defaults setFloat:width forKey:@"Texturize.width"];
	[defaults setFloat:height forKey:@"Texturize.height"];
	[defaults setBool:tileable forKey:@"Texturize.tileable"];
}

- (void)reapply
{
	PluginData *pluginData = [seaPlugins data];
	[self texturize];
	[pluginData apply];
}

- (BOOL)canReapply
{
	return success;
}

- (IBAction)cancel:(id)sender
{
	PluginData *pluginData = [seaPlugins data];
	[pluginData cancel];
	
	[NSApp stopModal];
	[NSApp endSheet:panel];
	[panel orderOut:self];
	success = NO;
}

- (IBAction)update:(id)sender
{
	/*
	overlap = round([overlapSlider doubleValue]);
	width = round([widthSlider doubleValue]);
	height = round([heightSlider doubleValue]);
	
	[overlapLabel setStringValue:[NSString stringWithFormat:@"%.0f%%", overlap]];
	[widthLabel setStringValue:[NSString stringWithFormat:@"%.0f%%", width]];
	[heightLabel setStringValue:[NSString stringWithFormat:@"%.0f%%", height]];
	 */
}

#define make_128(x) (x + 16 - (x % 16))

- (void)texturize
{
	int i, k, spp, iwidth, iheight;
	int foverlap, owidth, oheight;
	unsigned char *tdata, *idata, *odata;
	
	PluginData *pluginData = [seaPlugins data];
	spp = [pluginData spp];
	iwidth = [pluginData width];
	iheight = [pluginData height];
	tdata = [pluginData whiteboardData];
	idata = (unsigned char *)malloc(make_128(iwidth * iheight * (spp - 1)));
	for (i = 0; i < iwidth * iheight; i++) {
		for (k = 0; k < spp - 1; k++) idata[i * (spp - 1) + k] = tdata[i * spp + k];
	}
	owidth = (int)floor(iwidth * (width / 100.0f));
	oheight = (int)floor(iheight * (height / 100.0f));
	odata = (unsigned char *)malloc(make_128(owidth * oheight * spp));
	for (i = 0; i < iheight; i++) {
		memcpy(&(odata[owidth * i * (spp - 1)]), &(idata[iwidth * i * (spp - 1)]), iwidth * (spp - 1));
	}
	foverlap = (int)floor((overlap / 100.0f) * MIN(iwidth, iheight));
	[progressBar setIndeterminate:NO];
	[progressBar display];
	render(idata, iwidth, iheight, odata, owidth, oheight, foverlap, spp - 1, tileable, progressBar);
	free(idata);
	for (i = owidth * oheight - 1; i >= 0; i--) {
		for (k = 0; k < spp - 1; k++) odata[i * spp + k] = odata[i * (spp - 1) + k];
		odata[(i + 1) * spp - 1] = 0xFF;
	}
	[pluginData applyWithNewDocumentData:odata spp:spp width:owidth height:oheight];
}

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
	return YES;
}

@end
