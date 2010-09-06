#import "SeaApplication.h"

@implementation SeaApplication

- (unsigned int)validModesForFontPanel:(NSFontPanel *)fontPanel
{
	return NSFontPanelFaceModeMask | NSFontPanelSizeModeMask | NSFontPanelCollectionModeMask;
}

@end
