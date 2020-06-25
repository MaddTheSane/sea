#include <GIMPCore/GIMPCore.h>
#import "HorizStripesClass.h"
#import "PluginData.h"
#import "SeaWhiteboard.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]
#define make_128(x) (x + 16 - (x % 16))

@implementation HorizStripesClass

- (SeaPluginType)type
{
	return SeaPluginPoint;
}

- (int)points
{
	return 2;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"HorizStripes" table:NULL];
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

static inline int specmod(int a, int b)
{
	if (a < 0)
		return b + a % b;
	else
		return a % b;
}

- (void)run
{
	int width;
	unsigned char *overlay;
	IntRect selection;
	IntPoint point, apoint;
	unsigned char backColorAlpha[4], foreColorAlpha[4];
	int amount;
	int spp, pos;
	int i, j, k;
	BOOL black;
	PluginData *pluginData = [self.seaPlugins data];
	
	// Get plug-in data
	width = [pluginData width];
	spp = [pluginData spp];
	selection = [pluginData selection];
	point = [pluginData point:0];
	apoint = [pluginData point:1];
	amount = abs(apoint.y - point.y);
	overlay = [pluginData overlay];
	
	// Prepare for drawing
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:SeaOverlayBehaviourNormal];
	
	// Get colors
	if (spp == 4) {
		foreColorAlpha[0] = [[pluginData foreColor:YES] redComponent] * 255;
		foreColorAlpha[1] = [[pluginData foreColor:YES] greenComponent] * 255;
		foreColorAlpha[2] = [[pluginData foreColor:YES] blueComponent] * 255;
		foreColorAlpha[3] = [[pluginData foreColor:YES] alphaComponent] * 255;
		backColorAlpha[0] = [[pluginData backColor:YES] redComponent] * 255;
		backColorAlpha[1] = [[pluginData backColor:YES] greenComponent] * 255;
		backColorAlpha[2] = [[pluginData backColor:YES] blueComponent] * 255;
		backColorAlpha[3] = [[pluginData backColor:YES] alphaComponent] * 255;

	}
	else {
		foreColorAlpha[0] = [[pluginData foreColor:YES] whiteComponent] * 255;
		foreColorAlpha[1] = [[pluginData foreColor:YES] alphaComponent] * 255;
		backColorAlpha[0] = [[pluginData backColor:YES] whiteComponent] * 255;
		backColorAlpha[1] = [[pluginData backColor:YES] alphaComponent] * 255;
	}
	
	// Run checkboard
	for (j = selection.origin.y; j < selection.origin.y + selection.size.height; j++) {
		for (i = selection.origin.x; i < selection.origin.x + selection.size.width; i++) {
			
			pos = j * width + i;
			
			black = (specmod(j - point.y, amount * 2) < amount);
			for (k = 0; k < spp; k++) {
				if (black) {
					memcpy(&(overlay[pos * spp]), foreColorAlpha, spp);
				} else {
					memcpy(&(overlay[pos * spp]), backColorAlpha, spp);
				}
			}
			
		}
	}

	// Apply the change and record success
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

- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end
