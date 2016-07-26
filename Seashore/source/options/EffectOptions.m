#import "EffectOptions.h"
#import "SeaController.h"
#import "SeaPlugins.h"
#import "SeaTools.h"
#import "PluginClass.h"
#import "InfoPanel.h"

@implementation EffectOptions

- (void)awakeFromNib
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSInteger effectIndex;
	parentWin = nil;
	NSArray *pointPlugins = [[SeaController seaPlugins] pointPlugins];
	if ([pointPlugins count]) {
		if ([defaults objectForKey:@"effectIndex"])
			effectIndex = [defaults integerForKey:@"effectIndex"];
		else
			effectIndex = 0;
		if (effectIndex < 0 || effectIndex >= [pointPlugins count])
			effectIndex = 0;

		[effectTable noteNumberOfRowsChanged];
		[effectTable selectRowIndexes:[NSIndexSet indexSetWithIndex:effectIndex] byExtendingSelection:NO];
		[effectTable scrollRowToVisible:effectIndex];
		[effectTableInstruction setStringValue:[pointPlugins[effectIndex] instruction]];
		[clickCountLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"click count", @"Clicks remaining: %d"), [pointPlugins[effectIndex] points]]];
		[(InfoPanel *)panel setPanelStyle:kVerticalPanelStyle];
    }	
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
	return [[SeaController seaPlugins] pointPluginsNames][rowIndex];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [[[SeaController seaPlugins] pointPluginsNames] count];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	NSArray *pointPlugins = [[SeaController seaPlugins] pointPlugins];
	[effectTableInstruction setStringValue:[pointPlugins[[effectTable selectedRow]] instruction]];
	[[[gCurrentDocument tools] getTool:kEffectTool] reset];
}

- (NSInteger)selectedRow
{
	return [effectTable selectedRow];
}

- (IBAction)updateClickCount:(id)sender
{
	[clickCountLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"click count", @"Clicks remaining: %d"), [[[SeaController seaPlugins] pointPlugins][[effectTable selectedRow]] points] - [[[gCurrentDocument tools] getTool:kEffectTool] clickCount]]];
}

- (IBAction)showEffects:(id)sender
{
	NSWindow *w = [gCurrentDocument window];
	NSPoint p = [NSEvent mouseLocation];
	[panel orderFrontToGoal:p onWindow: w];
	parentWin = w;
	
	[NSApp runModalForWindow:panel];
}

- (IBAction)closeEffects:(id)sender
{
	[NSApp stopModal];
	if (parentWin) {
		[parentWin removeChildWindow:panel];
		parentWin = NULL;
	}
	[panel orderOut:self];	
}

@end
