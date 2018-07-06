#include <GIMPCore/GIMPCore.h>
#import "RandomClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

@implementation RandomClass

- (SeaPluginType)type
{
	return SeaPluginBasic;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Random Generator" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Generate" table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

#define int_mult(a,b,t)  ((t) = (a) * (b) + 0x80, ((((t) >> 8) + (t)) >> 8))
#define alphaPos (spp - 1)
	
- (void)run
{
	PluginData *pluginData = [self.seaPlugins data];
	IntRect selection;
	unsigned char *data, *overlay, *replace;
	int pos, i, j, k, width, spp;
	unsigned char background[4], random[4];
	BOOL opaque;
	
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:SeaOverlayBehaviourReplacing];
	selection = [pluginData selection];
	spp = [pluginData spp];
	width = [pluginData width];
	data = [pluginData data];
	overlay = [pluginData overlay];
	replace = [pluginData replace];
	opaque = ![pluginData hasAlpha];
	if (opaque) {
		if (spp == 2) {
			background[0] = [[pluginData backColor:NO] whiteComponent] * 255;
			background[1] = 255;
		} else {
			background[0] = [[pluginData backColor:NO] redComponent] * 255;
			background[1] = [[pluginData backColor:NO] greenComponent] * 255;
			background[2] = [[pluginData backColor:NO] blueComponent] * 255;
			background[3] = 255;
		}
	}
	
	//srand(time(NULL) & 0xffffffff);
	for (j = selection.origin.y; j < selection.origin.y + selection.size.height; j++) {
		for (i = selection.origin.x; i < selection.origin.x + selection.size.width; i++) {
			
			pos = j * width + i;
			if (opaque) {
				memcpy(&overlay[pos * spp], background, spp);
				for (k = 0; k < spp; k++)
					random[k] = (rand() << 8) >> 20;
				SeaSpecialMerge(spp, overlay, pos * spp, random, 0, 255);
			}
			else {
				for (k = 0; k < spp; k++)
					overlay[pos * spp + k] = (rand() << 8) >> 20;
			}
			replace[pos] = 255;
		
		}
	}
	[pluginData apply];
}

- (IBAction)reapply
{
	[self run];
}

- (BOOL)canReapply
{
	return YES;
}

- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end
