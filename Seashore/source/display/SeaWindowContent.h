#import <Cocoa/Cocoa.h>
#ifdef SEASYSPLUGIN
#import "Globals.h"
#else
#import <SeashoreKit/Globals.h>
#endif

typedef NS_ENUM(int, SeaWindowRegion) {
	SeaWindowRegionOptionsBar,
	SeaWindowRegionSidebar,
	SeaWindowRegionPointInformation,
	SeaWindowRegionStatusBar,
	SeaWindowRegionWarningsBar,
	
	kOptionsBar DEPRECATED_MSG_ATTRIBUTE("Use SeaWindowRegionOptionsBar instead") NS_SWIFT_UNAVAILABLE("Use .OptionsBar instead") = SeaWindowRegionOptionsBar,
	kSidebar DEPRECATED_MSG_ATTRIBUTE("Use SeaWindowRegionSidebar instead") NS_SWIFT_UNAVAILABLE("Use .Sidebar instead") = SeaWindowRegionSidebar,
	kPointInformation DEPRECATED_MSG_ATTRIBUTE("Use SeaWindowRegionPointInformation instead") NS_SWIFT_UNAVAILABLE("Use .PointInformation instead") = SeaWindowRegionPointInformation,
	kStatusBar DEPRECATED_MSG_ATTRIBUTE("Use SeaWindowRegionStatusBar instead") NS_SWIFT_UNAVAILABLE("Use .StatusBar instead") = SeaWindowRegionStatusBar,
	kWarningsBar DEPRECATED_MSG_ATTRIBUTE("Use SeaWindowRegionWarningsBar instead") NS_SWIFT_UNAVAILABLE("Use .WarningsBar instead") = SeaWindowRegionWarningsBar,
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
