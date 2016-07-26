#import <Cocoa/Cocoa.h>
#import "Globals.h"

typedef NS_ENUM(int, SeaWindowRegion) {
	kOptionsBar,
	kSidebar,
	kPointInformation,
	kStatusBar,
	kWarningsBar
};

@class SeaDocument;
@class SeaOptionsView;
@class LayerControlView;
@class BannerView;

/*!
	@class		SeaWindowContent
	@abstract	Provides a view manages all of the various subviews in the document window.
	@discussion	Ideally this is the only class that sets the frames, sizes and locations of
				each of the views in the main document view. The major caveat is that this 
				relies strongly on the window being configured properly in the IB NIB file.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/
@interface SeaWindowContent : NSView {
	IBOutlet SeaDocument *document;

	IBOutlet SeaOptionsView* optionsBar;
	IBOutlet NSView *nonOptionsBar;
	
	IBOutlet NSView* sidebar;
	IBOutlet NSScrollView* layers;
	IBOutlet NSView* pointInformation;
	IBOutlet LayerControlView* sidebarStatusbar;
	
	IBOutlet NSView *nonSidebar;
	IBOutlet BannerView *warningsBar;
	IBOutlet NSView *mainDocumentView;
	IBOutlet LayerControlView *statusBar;
	
	// Dictionary for all properties
	NSDictionary<NSNumber*,NSMutableDictionary<NSString*,id>*> *dict;
}

- (BOOL)visibilityForRegion:(SeaWindowRegion)region;
- (void)setVisibility:(BOOL)visibility forRegion:(SeaWindowRegion)region;
- (CGFloat)sizeForRegion:(SeaWindowRegion)region;
@end
