#import "SeaContent.h"
#import "SeaLayer.h"
#import "SeaWhiteboard.h"
#import "Bitmap.h"
#import "SeaCompositor.h"

@implementation SeaContent

- (id)initWithDocument:(id)doc
{
	// Set the data members to reasonable values
	xres = yres = 72;
	height = width = type = 0;
	lostprops = NULL; lostprops_len = 0;
	parasites = NULL; parasites_count = 0;
	exifData = NULL;
	layers = NULL; activeLayerIndex = 0;
    layersToUndo = [NSMutableArray array];
    layersToRedo = [NSMutableArray array];
    orderings = [NSMutableArray array];
	deletedLayers = [[NSArray alloc] init];
	selectedChannel = kAllChannels; trueView = NO;
	gScreenResolution = IntMakePoint(1024, 768);

	return self;
}

- (void)dealloc
{
	int i;
	
	if (parasites) {
		for (i = 0; i < parasites_count; i++) {
            free(parasites[i].name);
			free(parasites[i].data);
		}
		free(parasites);
	}
	if (lostprops) free(lostprops);
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

- (ParasiteData *)parasiteWithName:(char *)name
{
    int i;
    
    for (i = 0; i < parasites_count; i++) {
        if (strcmp(name,parasites[i].name)==0)
            return &(parasites[i]);
    }
    
    return NULL;
}

- (void)deleteParasiteWithName:(char *)name
{
    int i, x;
    
    // Find the parasite to delete
    x = -1;
    for (i = 0; i < parasites_count && x == -1; i++) {
        if (strcmp(name,parasites[i].name)==0)
            x = i;
    }
    
    if (x != -1) {
        
        // Destroy it
        free(parasites[x].name);
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
	[self deleteParasiteWithName:parasite.name];
	
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

- (NSDictionary *)exifData
{
	return exifData;
}

- (SeaLayer*)layer:(int)index
{
	return [layers objectAtIndex:index];
}

- (int)layerCount
{
	return [layers count];
}

- (SeaLayer*)activeLayer
{
	return (activeLayerIndex < 0 || layers == NULL) ? NULL : [layers objectAtIndex:activeLayerIndex];
}

- (int)activeLayerIndex
{
	return activeLayerIndex;
}

@end
