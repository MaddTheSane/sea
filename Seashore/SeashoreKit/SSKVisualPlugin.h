//
//  SSKVisualPlugin.h
//  Seashore
//
//  Created by C.W. Betts on 4/8/14.
//
//

#import "SSKPlugin.h"

@interface SSKVisualPlugin : SSKPlugin
{
	__weak NSPanel *panel;
	@protected
	// YES if the effect must be refreshed
	BOOL refresh;
}
@property (strong) NSArray *nibArray;
@property (weak) IBOutlet NSPanel *panel;

/*!
 @method		update:
 @discussion	Updates the panel's labels.
 @param		sender
 Ignored.
 */
- (IBAction)update:(id)sender;

/*!
 @method		preview:
 @discussion	Previews the plug-in's changes.
 @param		sender
 Ignored.
 */
- (IBAction)preview:(id)sender;

/*!
	@method		cancel:
	@discussion	Cancels the plug-in's changes.
	@param		sender
				Ignored.
*/
- (IBAction)cancel:(id)sender;

@end
