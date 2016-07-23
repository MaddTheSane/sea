#import "AbstractSelectOptions.h"
#import "SeaSelection.h"
#import "SeaDocument.h"
#import "SeaView.h"

@implementation AbstractSelectOptions
@synthesize selectionMode = mode;

- (instancetype)init
{
	if (self = [super init]) {
		mode = kDefaultMode;
	}
	
	return self;
}

- (void)setSelectionMode:(SeaSelectMode)newMode
{
	mode = newMode;
	if(mode == kDefaultMode){
		[self setIgnoresMove:NO];
	}else {
		[self setIgnoresMove:YES];
	}

}

- (void)setModeFromModifier:(AbstractModifiers)modifier
{
	switch (modifier) {
		case kNoModifier:
			[self setSelectionMode: kDefaultMode];
			break;
		case kControlModifier:
			[self setSelectionMode: kForceNewMode];
			break;
		case kShiftModifier:
			[self setSelectionMode: kDefaultMode];
			break;
		case kShiftControlModifier:
			[self setSelectionMode: kAddMode];
			break;
		case kAltControlModifier:
			[self setSelectionMode: kSubtractMode];
			break;
		case kReservedModifier1:
			[self setSelectionMode: kMultiplyMode];
			break;
		case kReservedModifier2:
			[self setSelectionMode: kSubtractProductMode];
			break;
		default:
			[self setSelectionMode: kDefaultMode];
			break;
	}
}

- (void)updateModifiers:(NSEventModifierFlags)modifiers
{
	[super updateModifiers:modifiers];
	AbstractModifiers modifier = [super modifier];
	[self setModeFromModifier: modifier];
}

- (IBAction)modifierPopupChanged:(id)sender
{
	[self setModeFromModifier: [[sender selectedItem] tag]];
	// Since the selection method changed via the popup menu, we need to update all of the docs
	// This is not nessisary in the above method because that case is already handled
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	for (SeaDocument *doc in documents) {
		[doc docView].needsDisplay = YES;
	}
}
@end
