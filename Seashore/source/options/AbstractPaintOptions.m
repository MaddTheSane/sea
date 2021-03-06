#import "AbstractPaintOptions.h"

#import "SeaController.h"
#import "UtilitiesManager.h"
#import "BrushUtility.h"
#import "TextureUtility.h"
#import "SeaDocument.h"

@implementation AbstractPaintOptions
- (IBAction)toggleTextures:(id)sender
{
	NSWindow *w = [gCurrentDocument window];
	NSPoint p = [NSEvent mouseLocation];
	[[[SeaController utilitiesManager] textureUtilityForDocument:gCurrentDocument] showPanelFrom: p onWindow: w];
}

- (IBAction)toggleBrushes:(id)sender
{
	NSWindow *w = [gCurrentDocument window];
	NSPoint p = [NSEvent mouseLocation];
	[[[SeaController utilitiesManager] brushUtilityForDocument:gCurrentDocument] showPanelFrom: p onWindow: w];
}

@end
