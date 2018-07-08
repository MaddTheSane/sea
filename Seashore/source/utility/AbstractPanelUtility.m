#import "AbstractPanelUtility.h"

#import "InfoPanel.h"

@implementation AbstractPanelUtility
- (void)awakeFromNib
{
	// Set up the window's properties
	[window setPanelStyle:SeaPanelStyleVertical];
	parentWin = NULL;
}	

- (void)showPanelFrom:(NSPoint)p onWindow: (NSWindow *)parent
{
	parentWin = parent;
	[window orderFrontToGoal: p onWindow: parentWin];
	[NSApp runModalForWindow:window];
}

- (IBAction)closePanel:(id)sender
{
	[NSApp stopModal];
	if (parentWin){
		[parentWin removeChildWindow:window];
		parentWin = NULL;
	}
	[window orderOut:self];	
}

@end
