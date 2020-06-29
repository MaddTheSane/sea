#import "ImageToolbarItem.h"

@implementation ImageToolbarItem

-(ImageToolbarItem *)initWithItemIdentifier:  (NSString*) itemIdent label:(NSString *) label image:(NSImage *) image toolTip: (NSString *) toolTip target: (id) target selector: (SEL) selector
{
	if (self = [super initWithItemIdentifier: itemIdent]) {
	
	// Set the text label to be displayed in the toolbar and customization palette
	[self setLabel: label];
	[self setPaletteLabel: label];
	
	// Set up a reasonable tooltip, and image
	// Note, these aren't localized, but you will likely want to localize many of the item's properties
	[self setToolTip: toolTip];
	[self setImage: image];
	
	// Tell the item what message to send when it is clicked
	[self setTarget: target];
	[self setAction: selector];
	}
	
	return self;
}

-(ImageToolbarItem *)initWithItemIdentifier:  (NSString*) itemIdent label:(NSString *) label imageNamed:(NSString *) image toolTip: (NSString *) toolTip target: (id) target selector: (SEL) selector
{
	return [self initWithItemIdentifier:itemIdent label:label image:[NSImage imageNamed:image] toolTip:toolTip target:target selector:selector];
}

@end
