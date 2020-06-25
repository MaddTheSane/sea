#import <Cocoa/Cocoa.h>
#import "AbstractScaleTool.h"
/*!
 @class		AbstractSelectTool
 @abstract	Acts as a base class for all tools that use selection.
 @discussion	This tool has some additional functionality to handle masks and such.
 <br><br>
 <b>License:</b> GNU General Public License<br>
 <b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/
@interface AbstractSelectTool : AbstractScaleTool

/*!
	@method		cancelSelection
	@discussion	Stops making the selection
*/
- (void)cancelSelection;

@end
