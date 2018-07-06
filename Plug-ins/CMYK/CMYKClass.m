#include <GIMPCore/GIMPCore.h>
#include <math.h>
#include <tgmath.h>
#include <ApplicationServices/ApplicationServices.h>
#import "CMYKClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

@implementation CMYKClass
- (int)type
{
	return kBasicPlugin;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Convert to CMYK" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Color Effect" table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

- (void)run
{
	PluginData *pluginData = [self.seaPlugins data];
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:SeaOverlayBehaviourReplacing];
	IntRect selection = [pluginData selection];
	int width = [pluginData width];
	unsigned char *data = [pluginData data];
	unsigned char *overlay = [pluginData overlay];
	unsigned char *replace = [pluginData replace];
	int channel = [pluginData channel];
	
	ColorSyncProfileRef srcProf = ColorSyncProfileCreateWithDisplayID(0);
	ColorSyncProfileRef destProf = ColorSyncProfileCreateWithName(kColorSyncGenericCMYKProfile);
	NSArray *profSeq = @[
				@{(__bridge NSString*)kColorSyncProfile: (__bridge id)srcProf,
				  (__bridge NSString*)kColorSyncRenderingIntent: (__bridge NSString*)kColorSyncRenderingIntentPerceptual,
				  (__bridge NSString*)kColorSyncTransformTag: (__bridge NSString*)kColorSyncTransformDeviceToPCS,
				  },
				
				@{(__bridge NSString*)kColorSyncProfile: (__bridge id)destProf,
				  (__bridge NSString*)kColorSyncRenderingIntent: (__bridge NSString*)kColorSyncRenderingIntentPerceptual,
				  (__bridge NSString*)kColorSyncTransformTag: (__bridge NSString*)kColorSyncTransformPCSToPCS,
				  },

				@{(__bridge NSString*)kColorSyncProfile: (__bridge id)srcProf,
				  (__bridge NSString*)kColorSyncRenderingIntent: (__bridge NSString*)kColorSyncRenderingIntentPerceptual,
				  (__bridge NSString*)kColorSyncTransformTag: (__bridge NSString*)kColorSyncTransformPCSToDevice,
				  },
				];
	
	ColorSyncTransformRef cw = ColorSyncTransformCreate((__bridge CFArrayRef)(profSeq), NULL);
	
	for (int j = selection.origin.y; j < selection.origin.y + selection.size.height; j++) {
		int pos = j * width + selection.origin.x;
		
		ColorSyncDataLayout srcLayout = kColorSyncByteOrderDefault;
		ColorSyncDataDepth srcDepth = kColorSync8BitInteger;
		size_t srcRowBytes;
		void *srcBytes;
		void *dstBytes = &(overlay[pos * 4]);
		
		if (channel == SeaSelectedChannelPrimary) {
			srcBytes = &(data[pos * 3]);
			srcRowBytes = selection.size.width * 3;
			srcLayout |= kColorSyncAlphaNone;
		} else {
			srcBytes = &(data[pos * 4]);
			srcRowBytes = selection.size.width * 4;
			srcLayout |= kColorSyncAlphaLast;
		}
		
		ColorSyncTransformConvert(cw, selection.size.width, 1, dstBytes, kColorSync8BitInteger, srcLayout, srcRowBytes, srcBytes, srcDepth, srcLayout, srcRowBytes, NULL);
		
		for (int i = selection.size.width; i >= 0; i--) {
			if (channel == SeaSelectedChannelPrimary)
				overlay[(pos + i) * 4 + 3] = 255;
			else
				overlay[(pos + i) * 4 + 3] = data[(pos + i) * 4 + 3];
			replace[pos + i] = 255;
		}
	}
	
	CFRelease(cw);
	CFRelease(srcProf);
	CFRelease(destProf);
	
	[pluginData apply];
}

- (void)reapply
{
	[self run];
}

- (BOOL)canReapply
{
	return YES;
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
