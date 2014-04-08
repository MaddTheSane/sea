//
//  SSKCIPlugin.h
//  Seashore
//
//  Created by C.W. Betts on 3/20/14.
//
//

#import <QuartzCore/QuartzCore.h>
#import <SeashoreKit/SSKVisualPlugin.h>

@interface SSKCIPlugin : SSKVisualPlugin
{
	@protected
	// Some temporary space we need preallocated for greyscale data
	unsigned char *newdata;
	
	NSBitmapImageRep *temp_rep;
	
	// YES if the effect must be refreshed
	BOOL refresh;
}

/*!
 @method		execute
 @discussion	Executes the effect.
 */
- (void)execute;

/*!
 @method		executeGrey
 @discussion	Executes the effect for greyscale images.
 @param		pluginData
 The PluginData object.
 */
- (void)executeGrey:(PluginData *)pluginData;

/*!
 @method		executeGrey
 @discussion	Executes the effect for colour images.
 @param		pluginData
 The PluginData object.
 */
- (void)executeColor:(PluginData *)pluginData;

/*!
 @method		executeChannel:withBitmap:
 @discussion	Executes the effect with any necessary changes depending on channel selection
 (called by either executeGrey or executeColor).
 @param		pluginData
 The PluginData object.
 @param		data
 The bitmap data to work with (must be 8-bit ARGB).
 @result		Returns the resulting bitmap.
 */
- (unsigned char *)executeChannel:(PluginData *)pluginData withBitmap:(unsigned char *)data;

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

/*!
 @method		update:
 @discussion	Updates the panel's labels.
 @param		sender
 Ignored.
 */
- (IBAction)update:(id)sender;

/*!
 * @method		apply:
 * @discussion	Applies the plug-in's changes.
 * @param		sender
 *					Ignored.
 */
- (IBAction)apply:(id)sender;

- (unsigned char *)coreImageEffect:(PluginData *)pluginData withBitmap:(unsigned char *)data;

- (BOOL)restoreAlpha;

@end
