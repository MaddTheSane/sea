#import <Cocoa/Cocoa.h>
#import <SeashoreKit/SSKTerminatable.h>
#import <SeashoreKit/Globals.h>
#import "PegasusUtility.h"
#import "TransparentUtility.h"
#import "ToolboxUtility.h"
#import "BrushUtility.h"
#import "OptionsUtility.h"
#import "TextureUtility.h"
#import "InfoUtility.h"
#import "StatusUtility.h"

@class SeaDocument;
@class SeaController;

NS_ASSUME_NONNULL_BEGIN

/*!
	@class		UtilitiesManager
	@abstract	Acts as a gateway to all of Seashore's utilities.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/
@interface UtilitiesManager : NSObject <SSKTerminatable> {
	// The controller object
	IBOutlet SeaController *controller;
	
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
- (void)shutdownForDocument:(SeaDocument*)doc NS_SWIFT_NAME(shutdown(for:));

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
- (nullable PegasusUtility*)pegasusUtilityForDocument:(SeaDocument*)doc NS_SWIFT_NAME(pegasusUtility(for:));
- (void)setPegasusUtility:(PegasusUtility*)util forDocument:(SeaDocument*)doc;

/*!
	@property	transparentUtilityFor:
	@discussion	Returns the transparent colour utility.
	@result		Returns an instance of TransparentUtility.
*/
@property (readonly, weak) IBOutlet TransparentUtility *transparentUtility;

/*!
	@method		toolboxUtilityForDocument:
	@discussion	Returns the toolbox utility.
	@param		doc
				The document that the utility is requested for.
	@result		Returns an instance of ToolboxUtility.
*/
- (nullable ToolboxUtility*)toolboxUtilityForDocument:(SeaDocument*)doc NS_SWIFT_NAME(toolboxUtility(for:));
- (void)setToolboxUtility:(ToolboxUtility*)util forDocument:(SeaDocument*)doc;

/*!
	@method		brushUtilityForDocument:
	@discussion	Returns the brush utility.
	@param		doc
				The document that the utility is requested for.
	@result		Returns an instance of BrushUtility.
*/
- (nullable BrushUtility*)brushUtilityForDocument:(SeaDocument*)doc NS_SWIFT_NAME(brushUtility(for:));
- (void)setBrushUtility:(BrushUtility*)util forDocument:(SeaDocument*)doc;


/*!
	@method		textureUtilityForDocument:
	@discussion	Returns the texture utility.
	@param		doc
				The document that the utility is requested for.
	@result		Returns an instance of TextureUtility.
*/
- (nullable TextureUtility*)textureUtilityForDocument:(SeaDocument*)doc NS_SWIFT_NAME(textureUtility(for:));
- (void)setTextureUtility:(TextureUtility*)util forDocument:(SeaDocument*)doc;

/*!
	@method		optionsUtilityForDocument:
	@discussion	Returns the options utility.
	@param		doc
				The document that the utility is requested for.
	@result		Returns an instance of OptionsUtility.
*/
- (nullable OptionsUtility*)optionsUtilityForDocument:(SeaDocument*)doc NS_SWIFT_NAME(optionsUtility(for:));
- (void)setOptionsUtility:(OptionsUtility*)util forDocument:(SeaDocument*)doc;

/*!
	@method		infoUtilityForDocument:
	@discussion	Returns the information utility.
	@param		doc
				The document that the utility is requested for.	
	@result		Returns an instance of InfoUtility.
*/
- (nullable InfoUtility*)infoUtilityForDocument:(SeaDocument*)doc NS_SWIFT_NAME(infoUtility(for:));
- (void)setInfoUtility:(InfoUtility*)util forDocument:(SeaDocument*)doc;

/*!
	@method		statusUtilityFor:
	@discussion	Returns the status utility.
	@param		doc
				The document that the utility is requested for.	
	@result		Returns an instance of StatusUtility.
*/
- (nullable StatusUtility*)statusUtilityFor:(SeaDocument*)doc NS_SWIFT_NAME(statusUtility(for:));
- (void)setStatusUtility:(StatusUtility*)util forDocument:(SeaDocument*)doc;


@end

NS_ASSUME_NONNULL_END
