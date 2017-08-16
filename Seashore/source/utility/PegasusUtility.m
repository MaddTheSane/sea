#import "PegasusUtility.h"
#import "SeaLayer.h"
#import "SeaContent.h"
#import "SeaDocument.h"
#import "SeaWhiteboard.h"
#import "LayerSettings.h"
#import "SeaHelpers.h"
#import "SeaController.h"
#import "SeaPrefs.h"
#import "UtilitiesManager.h"
#import "SeaProxy.h"
#import "SeaWindowContent.h"
#import "LayerDataSource.h"

@implementation PegasusUtility
@synthesize layerSettings;
@synthesize enabled;

- (void)awakeFromNib
{
	// Enable the utility
	enabled = YES;
	
	[[SeaController utilitiesManager] setPegasusUtility: self for:document];
}

- (void)activate
{
	// Get the LayersView and LayerSettings to activate
	[layerSettings activate];
	[self update:kPegasusUpdateAll];
}

- (void)deactivate
{
	// Get the LayersView and LayerSettings to deactivate
	[layerSettings deactivate];
	[self update:kPegasusUpdateAll];
}

- (void)update:(int)updateCode
{
	SeaLayer *layer = [[document contents] activeLayer];
	
	switch (updateCode) {
		case kPegasusUpdateAll:
			if (document && layer && enabled) {
				// Enable the layer buttons
				[newButton setEnabled:YES];
				[duplicateButton setEnabled:YES];
				[upButton setEnabled:YES];
				[downButton setEnabled:YES];
				[deleteButton setEnabled:YES];
			}
			else {
				// Disable the layer buttons
				[newButton setEnabled:NO];
				[duplicateButton setEnabled:NO];
				[upButton setEnabled:NO];
				[downButton setEnabled:NO];
				[deleteButton setEnabled:NO];
			}
		break;
	}
	[dataSource update];
}

- (IBAction)show:(id)sender
{
	[[[document window] contentView] setVisibility: YES forRegion: SeaWindowRegionSidebar];
}

- (IBAction)hide:(id)sender
{
	[[[document window] contentView] setVisibility: NO forRegion: SeaWindowRegionSidebar];
}

- (void)setEnabled:(BOOL)value
{
	enabled = value;
	[self update:kPegasusUpdateAll];
}

- (IBAction)toggleLayers:(id)sender
{
	if ([self visible])
		[self hide:sender];
	else
		[self show:sender];
}

- (BOOL)validateMenuItem:(id)menuItem
{
	id layer = [[document contents] activeLayer];
	
	// Switch to the appropriate code block given menu item
	switch ([menuItem tag]) {
		case 1002:
			if (![layer hasAlpha])
				return NO;
		break;
	}
	
	return YES;
}

- (BOOL)visible
{
	return [[[document window] contentView] visibilityForRegion: SeaWindowRegionSidebar];
}

- (IBAction)addLayer:(id)sender
{
	[(SeaContent*)[document contents] addLayer:kActiveLayer];
}

- (IBAction)duplicateLayer:(id)sender
{
	id selection = [document selection];
	
	if (![selection isFloating]) {
		[[document contents] duplicateLayer:kActiveLayer];
	}
}

- (IBAction)deleteLayer:(id)sender
{
	if ([[document contents] layerCount] > 1) {
		[[document contents] deleteLayer:kActiveLayer];
	} else {
		NSBeep();
	}
}

- (IBAction)forward:(id)sender
{
	//TODO: implement?
}

- (IBAction)backward:(id)sender
{
	//TODO: implement?
}


@end
