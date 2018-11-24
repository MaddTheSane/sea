#import "SeaApplication.h"

@implementation SeaApplication

- (NSFontPanelModeMask)validModesForFontPanel:(NSFontPanel *)fontPanel
{
	return NSFontPanelModeMaskFace | NSFontPanelModeMaskSize | NSFontPanelModeMaskCollection;
}

@end
