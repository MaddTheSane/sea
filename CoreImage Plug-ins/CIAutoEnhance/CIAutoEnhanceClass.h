/*!
	@header		CIMedianClass
	@abstract	Adjusts the selection so that all pixels are the median value of them
				and their neighbours using CoreImage.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain 2007<br>
				<b>Copyright:</b> N/A
*/

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import <SeashoreKit/PluginClass.h>

@interface CIAutoEnhanceClass : NSObject <SeaPluginClass> {

	// The plug-in's manager
	__weak SeaPlugins *seaPlugins;

	// YES if the application succeeded
	BOOL success;
}
@end
