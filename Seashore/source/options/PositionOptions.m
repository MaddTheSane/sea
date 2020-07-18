#import "PositionOptions.h"
#import "ToolboxUtility.h"
#import "SeaController.h"
#import "SeaHelp.h"
#import "SeaTools.h"
#import "SeaDocument.h"
#import "SeaSelection.h"
#import "AspectRatio.h"
#import "SeaView.h"

@implementation PositionOptions
@synthesize toolFunction = function;

- (void)awakeFromNib
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	if ([defaults objectForKey:@"position anchor"] == NULL) {
		[canAnchorCheckbox setState:NSControlStateValueOff];
	} else {
		[canAnchorCheckbox setState:[defaults boolForKey:@"position anchor"]];
	}
	function = SeaPositionOptionMoving;
}

- (BOOL)canAnchor
{
	return [canAnchorCheckbox state] == NSOnState;
}

- (void)setFunctionFromIndex:(AbstractModifiers)index
{
	switch (index) {
		case AbstractModifierShift:
			function = SeaPositionOptionScaling;
			break;
		case AbstractModifierControl:
			function = SeaPositionOptionRotating;
			break;
		default:
			function = SeaPositionOptionMoving;
			break;
	}
	// Let's not check for floating, maybe we can do it all
	/*if(function == kRotatingLayer){
		if(!document.selection.floating)
			function = kMovingLayer;
	}else if(function == kScalingLayer){
		if(document.selection.floating)
			function = kMovingLayer;
	}*/
}

- (void)updateModifiers:(NSEventModifierFlags)modifiers
{
	[super updateModifiers:modifiers];
	AbstractModifiers modifier = [super modifier];
	[self setFunctionFromIndex: modifier];
}

- (IBAction)modifierPopupChanged:(id)sender
{
	[self setFunctionFromIndex: [[sender selectedItem] tag]];	
	
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	for (SeaDocument *doc in documents) {
		[doc docView].needsDisplay = YES;
	}
}

- (void)shutdown
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:[canAnchorCheckbox state] == NSControlStateValueOn forKey:@"position anchor"];
}

@end
