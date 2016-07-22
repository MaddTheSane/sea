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
- (void)shutdownFor:(id)doc;

/*!
	@method		activate
	@discussion	Activates all utilities with the given document.
	@param		sender
				The document to activate the utilities with.
*/
- (void)activate:(id)sender;

/*!
	@method		pegasusUtilityFor:
	@discussion	Returns the Pegasus utility.
	@param		doc
				The document that the utility is requested for.
	@result		Returns an instance of PegasusUtility.
*/
- (PegasusUtility*)pegasusUtilityFor:(id)doc;
- (void)setPegasusUtility:(PegasusUtility*)util for:(id)doc;

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
- (ToolboxUtility*)toolboxUtilityFor:(id)doc;
- (void)setToolboxUtility:(ToolboxUtility*)util for:(id)doc;

/*!
	@method		brushUtilityFor:
	@discussion	Returns the brush utility.
	@param		doc
				The document that the utility is requested for.
	@result		Returns an instance of BrushUtility.
*/
- (BrushUtility*)brushUtilityFor:(id)doc;
- (void)setBrushUtility:(BrushUtility*)util for:(id)doc;


/*!
	@method		textureUtilityFor:
	@discussion	Returns the texture utility.
	@param		doc
				The document that the utility is requested for.
	@result		Returns an instance of TextureUtility.
*/
- (TextureUtility*)textureUtilityFor:(id)doc;
- (void)setTextureUtility:(TextureUtility*)util for:(id)doc;

/*!
	@method		optionsUtilityFor:
	@discussion	Returns the options utility.
	@param		doc
				The document that the utility is requested for.
	@result		Returns an instance of OptionsUtility.
*/
- (OptionsUtility*)optionsUtilityFor:(id)doc;
- (void)setOptionsUtility:(OptionsUtility*)util for:(id)doc;

/*!
	@method		infoUtilityFor:
	@discussion	Returns the information utility.
	@param		doc
				The document that the utility is requested for.	
	@result		Returns an instance of InfoUtility.
*/
- (InfoUtility*)infoUtilityFor:(id)doc;
- (void)setInfoUtility:(InfoUtility*)util for:(id)doc;

/*!
	@method		statusUtilityFor:
	@discussion	Returns the status utility.
	@param		doc
				The document that the utility is requested for.	
	@result		Returns an instance of StatusUtility.
*/
- (StatusUtility*)statusUtilityFor:(id)doc;
- (void)setStatusUtility:(StatusUtility*)util for:(id)doc;


@end
