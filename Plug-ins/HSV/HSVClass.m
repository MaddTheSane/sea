#include <GIMPCore/GIMPCore.h>
#import "HSVClass.h"
#import "PluginData.h"
#import "SeaWhiteboard.h"
#import <SeashoreKit/ColorConversion.h>

#define gOurBundle [NSBundle bundleForClass:[self class]]

@implementation HSVClass
@synthesize hue;
@synthesize saturation;
@synthesize value;

- (instancetype)initWithManager:(SeaPlugins *)manager
{
	if (self = [super initWithManager:manager]) {
		NSArray *tmpArray;
		[gOurBundle loadNibNamed:@"HSV" owner:self topLevelObjects:&tmpArray];
		self.nibArray = tmpArray;
	}
	
	return self;
}

- (SeaPluginType)type
{
	return SeaPluginBasic;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Hue, Saturation and Value" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Color Adjust" table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

- (void)run
{
	PluginData *pluginData;

	refresh = NO;
	
	self.hue = self.saturation = self.value = 0.0;
	
	success = NO;
	pluginData = [self.seaPlugins data];
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
	
	if (refresh)
		[self adjust];
	[pluginData apply];
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	if ([pluginData window])
		[pluginData.window endSheet:panel];
	[panel orderOut:self];
	success = YES;
}

- (void)reapply
{
	PluginData *pluginData = [self.seaPlugins data];
	
	[self adjust];
	[pluginData apply];
}

- (BOOL)canReapply
{
	return success;
}

- (IBAction)preview:(id)sender
{
	PluginData *pluginData = [self.seaPlugins data];
	
	if (refresh)
		[self adjust];
	[pluginData preview];
	refresh = NO;
}

- (IBAction)update:(id)sender
{
	PluginData *pluginData;
	
	[panel setAlphaValue:1.0];
	refresh = YES;
	if ([[NSApp currentEvent] type] == NSLeftMouseUp) {
		[self preview:self];
		pluginData = [self.seaPlugins data];
		if ([pluginData window])
			[panel setAlphaValue:0.4];
	}
}

static inline unsigned char CLAMP(int x) { return (x < 0) ? 0 : ((x > 255) ? 255 : x); }
static inline unsigned char WRAPAROUND(int x) { return (x < 0) ? (255 + ((x + 1) % 255)) : ((x > 255) ? (x % 255) : x); }

- (void)adjust
{
	PluginData *pluginData = [self.seaPlugins data];
	int r, g, b;
	
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:SeaOverlayBehaviourReplacing];
	IntRect selection = [pluginData selection];
	//channel = [pluginData channel];
	int spp = [pluginData spp];
	int width = [pluginData width];
	unsigned char *data = [pluginData data];
	unsigned char *overlay = [pluginData overlay];
	unsigned char *replace = [pluginData replace];
	
	for (int j = selection.origin.y; j < selection.origin.y + selection.size.height; j++) {
		for (int i = selection.origin.x; i < selection.origin.x + selection.size.width; i++) {
			int pos = (j * width + i) * spp;
			r = data[pos];
			g = data[pos + 1];
			b = data[pos + 2];
			overlay[pos + 3] = data[pos + 3];
			SeaRGBtoHSV(&r, &g, &b);
			r = WRAPAROUND(r + (int)(hue * 255.0));
			g = CLAMP(g + (int)(saturation * 255.0));
			b = CLAMP(b + (int)(value * 255.0));
			SeaHSVtoRGB(&r, &g, &b);
			overlay[pos] = (unsigned char)r;
			overlay[pos + 1] = (unsigned char)g;
			overlay[pos + 2] = (unsigned char)b;
			replace[j * width + i] = 255;
		}
	}
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
