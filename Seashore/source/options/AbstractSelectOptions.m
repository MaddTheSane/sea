#import "AbstractSelectOptions.h"
#import "SeaSelection.h"
#import "SeaDocument.h"
#import "SeaView.h"

@implementation AbstractSelectOptions
@synthesize selectionMode = mode;

- (instancetype)init
{
	if (self = [super init]) {
		mode = SeaSelectDefault;
	}
	
	return self;
}

- (void)setSelectionMode:(SeaSelectMode)newMode
{
	mode = newMode;
	if (mode == SeaSelectDefault) {
		[self setIgnoresMove:NO];
	} else {
		[self setIgnoresMove:YES];
	}
}

- (void)setModeFromModifier:(AbstractModifiers)modifier
{
	switch (modifier) {
		case kNoModifier:
			[self setSelectionMode: SeaSelectDefault];
			break;
		case kControlModifier:
			[self setSelectionMode: SeaSelectForceNew];
			break;
		case kShiftModifier:
			[self setSelectionMode: SeaSelectDefault];
			break;
		case kShiftControlModifier:
			[self setSelectionMode: SeaSelectAdd];
			break;
		case kAltControlModifier:
			[self setSelectionMode: SeaSelectSubtract];
			break;
		case kReservedModifier1:
			[self setSelectionMode: SeaSelectMultiply];
			break;
		case kReservedModifier2:
			[self setSelectionMode: SeaSelectSubtractProduct];
			break;
		default:
			[self setSelectionMode: SeaSelectDefault];
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
