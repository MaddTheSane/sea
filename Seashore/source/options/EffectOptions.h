#import "Globals.h"
#import "AbstractOptions.h"

/*!
	@class		EffectOptions
	@abstract	Handles the options pane for the effects tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2007 Mark Pazolli
*/

@interface EffectOptions : AbstractOptions <NSTableViewDataSource> {
	// The table listing all effects
	IBOutlet NSTableView *effectTable;
	
	// The instruction for those effects
	IBOutlet NSTextField *effectTableInstruction;
	
	// The label showing the number of clicks remaining
	IBOutlet NSTextField *clickCountLabel;
	
	// The panel of the effect options
	IBOutlet id panel;

	// The parent window for the effects options
	__weak id parentWin;
}

/*!
	@method		tableViewSelectionDidChange:
	@discussion	Called when the effect table's selection changes.
	@param		notification
				Ignored.
*/
- (void)tableViewSelectionDidChange:(NSNotification *)notification;

/*!
	@method		selectedRow
	@discussion	The row currently selected by the options.
	@result		An integer.
*/
- (NSInteger)selectedRow;

/*!
	@method		updateClickCount:
	@discussion	Updates the number of clicks remiaing for the current effect.
	@param		sender
				Ignored.
*/
- (IBAction)updateClickCount:(id)sender;


/*!
	@method		showEffects:
	@discussion	Brings the effects panel to the front (it's modal).
	@param		sender
				Ignored.
*/
- (IBAction)showEffects:(id)sender;


/*!
	@method		closeEffects:
	@discussion	Closes the effects panel.
	@param		sender
				Ignored.
*/
- (IBAction)closeEffects:(id)sender;

@end
