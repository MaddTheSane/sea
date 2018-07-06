#import "WarningsUtility.h"
#import "SeaWindowContent.h"
#import "BannerView.h"
#import "SeaWarning.h"
#import "SeaContent.h"
#import "SeaController.h"
#import "SeaDocument.h"

@implementation WarningsUtility
@synthesize activeWarningImportance = mostRecentImportance;

- (instancetype)init
{
	if (self = [super init]) {
		mostRecentImportance = -1;
	}
	return self;	
}

- (void)setWarning:(NSString *)message ofImportance:(SeaWarningImportance)importance
{
	[view setBannerText:message defaultButtonText:@"OK" alternateButtonText:NULL andImportance:importance];
	mostRecentImportance = importance;
	[windowContent setVisibility:YES forRegion:SeaWindowRegionWarningsBar];
}


- (void)showFloatBanner
{
	[view setBannerText:@"Drag the floating layer to position it, then click Anchor to merge it into the layer below." defaultButtonText:@"Anchor" alternateButtonText:@"New Layer" andImportance:SeaWarningImportanceUI];
	mostRecentImportance = SeaWarningImportanceUI;
	[windowContent setVisibility:YES forRegion:SeaWindowRegionWarningsBar];
}

- (void)hideFloatBanner
{
	mostRecentImportance = -1;
	[windowContent setVisibility:NO forRegion:SeaWindowRegionWarningsBar];	
}

- (void)keyTriggered
{
	if (mostRecentImportance != -1) {
		[self defaultAction: self];
	}
}

- (IBAction)defaultAction:(id)sender
{
	if (mostRecentImportance == SeaWarningImportanceUI) {
		mostRecentImportance = -1;
		[windowContent setVisibility:NO forRegion:SeaWindowRegionWarningsBar];
		[[document contents] toggleFloatingSelection];
	} else {
		mostRecentImportance = -1;
		[windowContent setVisibility:NO forRegion:SeaWindowRegionWarningsBar];
		[[SeaController seaWarning] triggerQueue: document];
	}
}


- (IBAction)alternateAction:(id)sender
{
	if (mostRecentImportance == SeaWarningImportanceUI) {
		mostRecentImportance = -1;
		[windowContent setVisibility:NO forRegion:SeaWindowRegionWarningsBar];	
		[[document contents] addLayer:kActiveLayer];
	}
}

@end
