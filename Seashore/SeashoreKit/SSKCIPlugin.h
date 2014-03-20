//
//  SSKCIPlugin.h
//  Seashore
//
//  Created by C.W. Betts on 3/20/14.
//
//

#import <QuartzCore/QuartzCore.h>
#import <SeashoreKit/SSKPlugin.h>

@interface SSKCIPlugin : SSKPlugin
{
	@protected
	// Some temporary space we need preallocated for greyscale data
	unsigned char *newdata;
	
	// Determines the boundaries of the layer
	CGRect bounds;
	
	// Signals whether the bounds rectangle is valid
	BOOL boundsValid;
	
	NSBitmapImageRep *temp_rep;
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

- (unsigned char *)tile:(PluginData *)pluginData withBitmap:(unsigned char *)data;


@end
