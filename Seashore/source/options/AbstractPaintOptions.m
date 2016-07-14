#import "AbstractPaintOptions.h"

#import "SeaController.h"
#import "UtilitiesManager.h"
#import "BrushUtility.h"
#import "TextureUtility.h"

@implementation AbstractPaintOptions
- (IBAction)toggleTextures:(id)sender
{
	NSWindow *w = [gCurrentDocument window];
	NSPoint p = [NSEvent mouseLocation];
	[(BrushUtility *)[[SeaController utilitiesManager] textureUtilityFor:gCurrentDocument] showPanelFrom: p onWindow: w];
}

- (IBAction)toggleBrushes:(id)sender
{
	NSWindow *w = [gCurrentDocument window];
	NSPoint p = [NSEvent mouseLocation];
	[(TextureUtility *)[[SeaController utilitiesManager] brushUtilityFor:gCurrentDocument] showPanelFrom: p onWindow: w];
}

@end
