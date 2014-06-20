#import "SeaContent.h"
#import "SeaLayer.h"
#import "SeaWhiteboard.h"
#import "Bitmap.h"
#import "SeaCompositor.h"

@implementation SeaContent

- (instancetype)init
{
	if (self = [super init]) {
		// Set the data members to reasonable values
		xres = yres = 72;
		layersToUndo = [NSMutableArray array];
		layersToRedo = [NSMutableArray array];
		orderings = [NSMutableArray array];
		deletedLayers = [[NSArray alloc] init];
		selectedChannel = kAllChannels;
		gScreenResolution = IntMakePoint(1024, 768);
	}
	
	return self;
}

- (void)dealloc
{
	int i;
	
	if (parasites) {
		for (i = 0; i < parasites_count; i++) {
			CFRelease(parasites[i].name);
			free(parasites[i].data);
		}
		free(parasites);
	}
	if (lostprops)
		free(lostprops);
}

- (int)type
{
	return type;
}

- (int)spp
{
	int result = 0;
	
	switch (type) {
		case XCF_RGB_IMAGE:
			result = 4;
			break;
		case XCF_GRAY_IMAGE:
			result = 2;
			break;
		default:
			NSLog(@"Document type not recognised by spp");
			break;
	}
	
	return result;
}

- (int)xres
{
	return xres;
}

- (int)yres
{
	return yres;
}

- (float)xscale
{
	float xscale = 1.0;
	
	if (gScreenResolution.x != 0 && xres != gScreenResolution.x)
		xscale /= ((float)xres / (float)gScreenResolution.x);
	
	return xscale;
}

- (float)yscale
{
	float yscale = 1.0;
	
	if (gScreenResolution.y != 0 && yres != gScreenResolution.y)
		yscale /= ((float)yres / (float)gScreenResolution.y);
	
	return yscale;
}

- (int)height
{
	return height;
}

- (int)width
{
	return width;
}

- (int)selectedChannel
{
	return selectedChannel;
}

- (char *)lostprops
{
	return lostprops;
}

- (int)lostprops_len
{
	return lostprops_len;
}

- (ParasiteData *)parasites
{
	return parasites;
}

- (int)parasites_count
{
	return parasites_count;
}

- (ParasiteData *)parasiteWithName:(NSString *)name
{
	int i;
	
	for (i = 0; i < parasites_count; i++) {
		if ([name isEqualToString:(__bridge NSString*)parasites[i].name])
			return &(parasites[i]);
	}
	
	return NULL;
}

- (void)deleteParasiteWithName:(NSString *)name
{
	int i, x;
	
	// Find the parasite to delete
	x = -1;
	for (i = 0; i < parasites_count && x == -1; i++) {
		if ([name isEqualToString:(__bridge NSString*)parasites[i].name]) {
			x = i;
			break;
		}
	}
	
	if (x != -1) {
		
		// Destroy it
		CFRelease(parasites[x].name);
		free(parasites[x].data);
	
		// Update the parasites list
		parasites_count--;
		if (parasites_count > 0) {
			for (i = x; i < parasites_count; i++) {
				parasites[i] = parasites[i + 1];
			}
			parasites = realloc(parasites, sizeof(ParasiteData) * parasites_count);
		}
		else {
			free(parasites);
			parasites = NULL;
		}
	
	}
}

- (void)addParasite:(ParasiteData)parasite
{
	// Delete existing parasite with the same name (if any)
	[self deleteParasiteWithName:(__bridge NSString*)parasite.name];
	
	// Add parasite
	parasites_count++;
	if (parasites_count == 1) parasites = malloc(sizeof(ParasiteData) * parasites_count);
	else parasites = realloc(parasites, sizeof(ParasiteData) * parasites_count);
	parasites[parasites_count - 1] = parasite;
}

- (BOOL)trueView
{
	return trueView;
}

- (void)setTrueView:(BOOL)value
{
	trueView = value;
}

- (void)setCMYKSave:(BOOL)value
{
	cmykSave = value;
}

- (BOOL)cmykSave
{
	return cmykSave;
}

- (NSDictionary *)exifData
{
	return exifData;
}

- (id)layer:(NSInteger)index
{
	return layers[index];
}

- (NSInteger)layerCount
{
	return [layers count];
}

- (SeaLayer*)activeLayer
{
	return (activeLayerIndex < 0) ? NULL : layers[activeLayerIndex];
}

- (NSInteger)activeLayerIndex
{
	return activeLayerIndex;
}

- (unsigned char *)bitmapUnderneath:(IntRect)rect forWhiteboard:(SeaWhiteboard *)whiteboard
{
	CompositorOptions options;
	unsigned char *data;
	SeaLayer *layer;
	int i, spp = [self spp];
	
	// Create the replacement flat layer
	data = malloc(make_128(rect.size.width * rect.size.height * spp));
	memset(data, 0, rect.size.width * rect.size.height * spp);

	// Set the composting options
	options.forceNormal = 0;
	options.rect = rect;
	options.destRect = rect;
	options.insertOverlay = NO;
	options.useSelection = NO;
	options.overlayOpacity = 255;
	options.overlayBehaviour = kNormalBehaviour;
	options.spp = spp;

	// Composite the layers underneath
	for (i = [layers count] - 1; i >= activeLayerIndex; i--) {
		layer = layers[i];
		if ([layer visible]) {
			[[whiteboard compositor] compositeLayer:layer withOptions:options andData:data];
		}
	}
	
	return data;
}


@end
