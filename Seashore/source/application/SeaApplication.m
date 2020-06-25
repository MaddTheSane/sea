#import "SeaApplication.h"
#import "SeaDocumentController.h"

@implementation SeaApplication

- (NSFontPanelModeMask)validModesForFontPanel:(NSFontPanel *)fontPanel
{
	return NSFontPanelModeMaskFace | NSFontPanelModeMaskSize | NSFontPanelModeMaskCollection;
}

@end
