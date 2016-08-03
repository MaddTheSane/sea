#import <Cocoa/Cocoa.h>
#ifdef SEASYSPLUGIN
#import "Globals.h"
#else
#import <SeashoreKit/Globals.h>
#endif

/*!
	@class		SeaShadowView
	@abstract	Provides a view that will draw a shadow for the image to differentiate it from the background.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface SeaShadowView : NSView {
	IBOutlet NSScrollView *scrollView;
	BOOL areRulersVisible;
}

//! The visibility of the rulers.
@property (nonatomic, getter=areRulersVisible) BOOL rulersVisible;

/*!
	@method		setRulersVisible:
	@discussion	The shadow will have to be offset if there are rulers.
	@param		isVisible
				Whether or not they now are visible.
*/
- (void)setRulersVisible:(BOOL)isVisible;

@end
