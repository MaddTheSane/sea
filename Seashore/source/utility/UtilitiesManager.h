#import <Cocoa/Cocoa.h>
#import "Globals.h"
#import "PegasusUtility.h"
#import "TransparentUtility.h"
#import "ToolboxUtility.h"
#import "BrushUtility.h"
#import "OptionsUtility.h"
#import "TextureUtility.h"
#import "InfoUtility.h"
#import "StatusUtility.h"

@class SeaDocument;

/*!
	@class		UtilitiesManager
	@abstract	Acts as a gateway to all of Seashore's utilities.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/
@interface UtilitiesManager : NSObject {
	
	// The controller object
	IBOutlet id controller;
	IBOutlet TransparentUtility *transparentUtility;
	
	// Outlets to the various utilities of Seashore
    NSMutableDictionary<NSNumber*,PegasusUtility*> *pegasusUtilities;
	NSMutableDictionary<NSNumber*,TransparentUtility*> *transparentUtilities;
	NSMutableDictionary<NSNumber*,ToolboxUtility*> *toolboxUtilities;
	NSMutableDictionary<NSNumber*,BrushUtility*> *brushUtilities;
	NSMutableDictionary<NSNumber*,OptionsUtility*> *optionsUtilities;
	NSMutableDictionary<NSNumber*,TextureUtility*> *textureUtilities;
	NSMutableDictionary<NSNumber*,InfoUtility*> *infoUtilities;
	NSMutableDictionary<NSNumber*,StatusUtility*> *statusUtilities;
	
	// Various choices
	int optionsChoice;
	BOOL infoChoice;
	BOOL colorChoice;
	
}

/*!
	@method		awakeFromNib
	@discussion	Shows or hides the utilities as required.
*/
- (void)awakeFromNib;

/*!
	@method		terminate
	@discussion	Remembers the visibilities of the utilities (if required) and
				shuts them down.
*/
- (void)terminate;

/*!
	@method		shutdownFor:
	@discussion	Shuts down the appropriate utilites for the given document
	@param		doc
				The document that is now closing.
*/
- (void)shutdownFor:(SeaDocument*)doc;

/*!
	@method		activate
	@discussion	Activates all utilities with the given document.
	@param		sender
				The document to activate the utilities with.
*/
- (void)activate:(SeaDocument*)sender;

/*!
	@method		pegasusUtilityFor:
	@discussion	Returns the Pegasus utility.
	@param		doc
				The document that the utility is requested for.
	@result		Returns an instance of PegasusUtility.
*/
- (PegasusUtility*)pegasusUtilityFor:(SeaDocument*)doc;
- (void)setPegasusUtility:(PegasusUtility*)util for:(SeaDocument*)doc;

/*!
	@method		transparentUtilityFor:
	@discussion	Returns the transparent colour utility.
	@result		Returns an instance of TransparentUtility.
*/
- (TransparentUtility*)transparentUtility;

/*!
	@method		toolboxUtilityFor:
	@discussion	Returns the toolbox utility.
	@param		doc
				The document that the utility is requested for.
	@result		Returns an instance of ToolboxUtility.
*/
- (ToolboxUtility*)toolboxUtilityFor:(SeaDocument*)doc;
- (void)setToolboxUtility:(ToolboxUtility*)util for:(SeaDocument*)doc;

/*!
	@method		brushUtilityFor:
	@discussion	Returns the brush utility.
	@param		doc
				The document that the utility is requested for.
	@result		Returns an instance of BrushUtility.
*/
- (BrushUtility*)brushUtilityFor:(SeaDocument*)doc;
- (void)setBrushUtility:(BrushUtility*)util for:(SeaDocument*)doc;


/*!
	@method		textureUtilityFor:
	@discussion	Returns the texture utility.
	@param		doc
				The document that the utility is requested for.
	@result		Returns an instance of TextureUtility.
*/
- (TextureUtility*)textureUtilityFor:(SeaDocument*)doc;
- (void)setTextureUtility:(TextureUtility*)util for:(SeaDocument*)doc;

/*!
	@method		optionsUtilityFor:
	@discussion	Returns the options utility.
	@param		doc
				The document that the utility is requested for.
	@result		Returns an instance of OptionsUtility.
*/
- (OptionsUtility*)optionsUtilityFor:(SeaDocument*)doc;
- (void)setOptionsUtility:(OptionsUtility*)util for:(SeaDocument*)doc;

/*!
	@method		infoUtilityFor:
	@discussion	Returns the information utility.
	@param		doc
				The document that the utility is requested for.	
	@result		Returns an instance of InfoUtility.
*/
- (InfoUtility*)infoUtilityFor:(SeaDocument*)doc;
- (void)setInfoUtility:(InfoUtility*)util for:(SeaDocument*)doc;

/*!
	@method		statusUtilityFor:
	@discussion	Returns the status utility.
	@param		doc
				The document that the utility is requested for.	
	@result		Returns an instance of StatusUtility.
*/
- (StatusUtility*)statusUtilityFor:(SeaDocument*)doc NS_SWIFT_NAME(statusUtility(for:));
- (void)setStatusUtility:(StatusUtility*)util for:(SeaDocument*)doc;


@end
