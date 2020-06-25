#import "ThresholdView.h"
#import "ThresholdClass.h"

@implementation ThresholdView

- (void)calculateHistogram:(PluginData *)pluginData
{
	unsigned char *data = [pluginData data];
	int spp = [pluginData spp];
	int width = [pluginData width];
	int height = [pluginData height];
	int channel = [pluginData channel];
	int i, j, mid = 0;
	__block int max = 1;
	
	memset(histogram, 0, sizeof(histogram));
	
	if (channel == SeaSelectedChannelAll || channel == SeaSelectedChannelPrimary) {
		for (i = 0; i < width * height; i++) {
			for (j = 0; j < spp - 1; j++)
				mid += data[i * spp + j];
			mid /= (spp - 1);
			histogram[mid]++; 
		}
	} else if (channel == SeaSelectedChannelAlpha) {
		for (i = 0; i < width * height; i++) {
			mid = data[(i + 1) * spp - 1];
			histogram[mid]++; 
		}
	}
	
	dispatch_apply(256, dispatch_get_global_queue(0, 0), ^(size_t i) {
		max = (self->histogram[i] > max) ? self->histogram[i] : max;
	});

	dispatch_apply(256, dispatch_get_global_queue(0, 0), ^(size_t i) {
		self->histogram[i] = (int)(((float)self->histogram[i] / (float)max) * 120.0);
	});
}

- (void)drawRect:(NSRect)rect
{
	int i;
	
	[[NSColor blackColor] set];
	for (i = 0; i < 256; i++) {
		[NSBezierPath fillRect:NSMakeRect(i, 0, 1, histogram[i])];
	}
	
	[[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:1.0 alpha:0.4] set];
	[NSBezierPath fillRect:NSMakeRect(MIN([thresholdClass topValue], [thresholdClass bottomValue]), 0, labs([thresholdClass topValue] - [thresholdClass bottomValue]) + 1, 120)];
}

@end
