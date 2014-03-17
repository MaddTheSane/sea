#import "CloneOptions.h"
#import "ToolboxUtility.h"
#import "SeaController.h"
#import "SeaHelp.h"
#import "SeaTools.h"
#import "CloneTool.h"
#import "SeaDocument.h"
#import "SeaTools.h"

@implementation CloneOptions

- (void)awakeFromNib
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[mergedCheckbox setState:[defaults boolForKey:@"clone merged"]];
}

- (BOOL)mergedSample
{
	return [mergedCheckbox state];
}

- (IBAction)mergedChanged:(id)sender
{
	id cloneTool = [[document tools] getTool:kCloneTool];

	[cloneTool unset];
}

- (void)update
{
	id cloneTool = [[document tools] getTool:kCloneTool];
	IntPoint sourcePoint;
	
	if ([cloneTool sourceSet]) {
		sourcePoint = [cloneTool sourcePoint:YES];
		if ([cloneTool sourceName] != NULL)
			[sourceLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"source set", @"Source: (%d, %d) from \"%@\""), sourcePoint.x, sourcePoint.y, [cloneTool sourceName]]];
		else
			[sourceLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"source set document", @"Source: (%d, %d) from whole document"), sourcePoint.x, sourcePoint.y]];
	} else {
		[sourceLabel setStringValue:LOCALSTR(@"source unset", @"Source: Unset")];
	}
}

- (void)shutdown
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:[self mergedSample] forKey:@"clone merged"];
}

@end
