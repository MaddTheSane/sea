#import "Globals.h"
#import "AbstractPanelUtility.h"


@class SeaDocument;
@class SeaBrush;

/*!
	@class		BrushUtility
	@abstract	Loads and manages all brushes for the user.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli	
*/
@interface BrushUtility : AbstractPanelUtility {

	// The brush grouping pop-up
	IBOutlet NSPopUpButton *brushGroupPopUp;

	// The label that presents the user with the brushes name
	IBOutlet NSTextField *brushNameLabel;
	
	// The label and slider that present spacing to the user
    IBOutlet NSTextField *spacingLabel;
    IBOutlet NSSlider *spacingSlider;
	
	// The view that displays the brushes
    IBOutlet NSScrollView *view;
		
	// The document which is the focus of this utility
	IBOutlet SeaDocument *document;
	
	// An dictionary of all brushes known to Seashore
	NSDictionary<NSString*, SeaBrush*> *brushes;
	
	// An array of all groups (an array of an array SeaBrush's) and group names (an array of NSString's)
	NSArray<NSArray<SeaBrush*>*> *groups;
	NSArray<NSString*> *groupNames;
	
	// The index of the currently active group
	NSInteger activeGroupIndex;
	
	// The index of the currently active brush
	NSInteger activeBrushIndex;
	
	// The number of custom groups
	NSInteger customGroups;
}

/*!
	@method		init
	@discussion	Initializes an instance of this class.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (instancetype)init;

/*!
	@method		shutdown
	@discussion	Saves currently selected brush upon shutdown.
*/
- (void)shutdown;

/*!
	@method		loadBrushes:
	@discussion	Frees (if necessary) and then reloads all the brushes from
				Seashore's brushes directory.
	@param		update
				\c YES if the brush utility should be updated after reloading all
				the brushes (typical case), \c NO otherwise.
*/
- (void)loadBrushes:(BOOL)update;

/*!
	@method		changeSpacing:
	@discussion	Called when the brush spacing is changed.
	@param		sender
				Ignored.
*/
- (IBAction)changeSpacing:(id)sender;

/*!
	@method		changeGroup:
	@discussion	Called when the brush group is changed.
	@param		sender
				Ignored.
*/
- (IBAction)changeGroup:(id)sender;

/*!
	@property	spacing
	@discussion	Returns the spacing associated with the current brush.
	@result		Returns an integer indicating the spacing associated with the
				current brush.
*/
@property (readonly) int spacing;

/*!
	@property	activeBrush
	@discussion	Returns the currently active brush.
	@result		Returns an instance of SeaBrush representing the currently
				active brush.
*/
@property (readonly, retain) SeaBrush *activeBrush;

/*!
	@property	activeBrushIndex
	@discussion	The index of the currently active brush.
	@result		Returns an integer representing the index of the currently
				active brush.
*/
@property (nonatomic) NSInteger activeBrushIndex;

/*!
	@method		setActiveBrushIndex:
	@discussion	Sets the active brush to that specified by the given index.
	@param		index
				The index of the brush to activate.
*/
- (void)setActiveBrushIndex:(NSInteger)index;

/*!
	@method		brushes
	@discussion	Returns all the brushes in the currently active group.
	@result		Returns an array with all the brushes in the currently active
				group. 
*/
- (NSArray<SeaBrush*> *)brushes;

@end
