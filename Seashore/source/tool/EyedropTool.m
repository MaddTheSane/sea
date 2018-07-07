#import "EyedropTool.h"
#import "SeaLayer.h"
#import "SeaContent.h"
#import "SeaDocument.h"
#import "SeaController.h"
#import "UtilitiesManager.h"
#import "ToolboxUtility.h"
#import "OptionsUtility.h"
#import "EyedropOptions.h"
#import "SeaWhiteboard.h"
#import "SeaView.h"
#import "SeaTools.h"
#import "Bitmap.h"
#import "SeaHelpers.h"

@implementation EyedropTool

- (SeaToolsDefines)toolId
{
	return kEyedropTool;
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
	ToolboxUtility *toolboxUtility = [[SeaController utilitiesManager] toolboxUtilityFor:document];
	NSColor *color = [self getColor];
	
	if (color != NULL) {
		if ([(EyedropOptions*)options modifier] == AbstractModifierAlt)
			[toolboxUtility setBackground:[self getColor]];
		else
			[toolboxUtility setForeground:[self getColor]];
		[toolboxUtility update:NO];
	}
}

- (int)sampleSize
{
	return [(EyedropOptions*)options sampleSize];
}

- (NSColor *)getColor
{
	SeaLayer *layer = [[document contents] activeLayer];
	unsigned char *data;
	int spp = [[document contents] spp];
	int lwidth, lheight, width, height;
	IntPoint newPos, pos;
	unsigned char t[4];
	int radius = [options sampleSize] - 1;
	int channel = [[document contents] selectedChannel];
	
	lwidth = [layer width];
	lheight = [layer height];
	width = [[document contents] width];
	height = [[document contents] height];
	
	pos = [[document docView] getMousePosition:NO];
	if ([(EyedropOptions*)options mergedSample]) {
		data = [[document whiteboard] data];
		newPos = pos;
		if (newPos.x < 0 || newPos.x >= width || newPos.y < 0 || newPos.y >= height)
			return NULL;
		if (spp == 2) {
			t[0] = SeaAveragedComponentValue(2, data, width, height, 0, radius, newPos);
			t[1] = SeaAveragedComponentValue(2, data, width, height, 1, radius, newPos);
			SeaUnpremultiplyBitmap(2, t, t, 1);
			return [NSColor colorWithDeviceWhite:(float)t[0] / 255.0 alpha:(float)t[1] / 255.0];
		} else {
			t[0] = SeaAveragedComponentValue(4, data, width, height, 0, radius, newPos);
			t[1] = SeaAveragedComponentValue(4, data, width, height, 1, radius, newPos);
			t[2] = SeaAveragedComponentValue(4, data, width, height, 2, radius, newPos);
			t[3] = SeaAveragedComponentValue(4, data, width, height, 3, radius, newPos);
			SeaUnpremultiplyBitmap(4, t, t, 1);
			return [NSColor colorWithDeviceRed:(float)t[0] / 255.0 green:(float)t[1] / 255.0 blue:(float)t[2] / 255.0 alpha:(float)t[3] / 255.0];
		}
	} else {
		data = [layer data];
		newPos.x = pos.x - [layer xoff];
		newPos.y = pos.y - [layer yoff];
		if (newPos.x < 0 || newPos.x >= lwidth || newPos.y < 0 || newPos.y >= lheight)
			return NULL;
		if (spp == 2) {
			if (channel != SeaSelectedChannelAlpha) {
				t[0] = SeaAveragedComponentValue(2, data, lwidth, lheight, 0, radius, newPos);
			}
			if (channel == SeaSelectedChannelPrimary) {
				t[1] = 255;
			} else {
				t[1] = SeaAveragedComponentValue(2, data, lwidth, lheight, 1, radius, newPos);
			}
			if (channel == SeaSelectedChannelAlpha) {
				t[0] = t[1]; t[1] = 255;
			}
			return [NSColor colorWithDeviceWhite:(CGFloat)t[0] / 255.0 alpha:(CGFloat)t[1] / 255.0];
		} else {
			if (channel != SeaSelectedChannelAlpha) {
				t[0] = SeaAveragedComponentValue(4, data, lwidth, lheight, 0, radius, newPos);
				t[1] = SeaAveragedComponentValue(4, data, lwidth, lheight, 1, radius, newPos);
				t[2] = SeaAveragedComponentValue(4, data, lwidth, lheight, 2, radius, newPos);
			}
			if (channel == SeaSelectedChannelPrimary) {
				t[3] = 255;
			} else {
				t[3] = SeaAveragedComponentValue(4, data, lwidth, lheight, 3, radius, newPos);
			}
			if (channel == SeaSelectedChannelAlpha) {
				t[0] = t[1] = t[2] = t[3]; t[3] = 255;
			}
			return [NSColor colorWithDeviceRed:(CGFloat)t[0] / 255.0 green:(CGFloat)t[1] / 255.0 blue:(CGFloat)t[2] / 255.0 alpha:(CGFloat)t[3] / 255.0];
		}
	}
}

@end
