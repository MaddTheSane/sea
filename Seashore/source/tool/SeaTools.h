#import <Cocoa/Cocoa.h>
#import <SeashoreKit/Globals.h>

/*
	@enum		k...Tool
	@constant	SeaToolsSelectRect
				The rectangular selection tool.
	@constant	SeaToolsSelectEllipse
				The elliptical selection tool.
	@constant	SeaToolsLasso
				The lasso tool.
	@constant	SeaToolsPolygonLasso
				The polygon lasso tool.
	@constant   SeaToolsWand
				The wand selection tool.
	@constant	SeaToolsPencil
				The pencil tool.
	@constant	SeaToolsBrush
				The paintbrush tool.
	@constant	SeaToolsEyedrop
				The colour sampling tool.
	@constant	SeaToolsText
				The text tool.
	@constant	SeaToolsEraser
				The eraser tool.
	@constant	SeaToolsBucket
				The paint bucket tool.
	@constant	SeaToolsGradient
				The gradient tool.
	@constant	SeaToolsCrop
				The crop tool.
	@constant	SeaToolsClone
				The clone tool.
	@constant	SeaToolsSmudge
				The smudging tool.
	@constant	SeaToolsEffect
				The effect tool.
	@constant	SeaToolsZoom
				The zoom tool.
	@constant	SeaToolsPosition
				The layer positioning tool.
	@constant	SeaToolsFirstSelection
				The first selection tool.
	@constant	SeaToolsLastSelection
				The last selection tool.
*/
typedef NS_ENUM(NSInteger, SeaToolsDefines) {
	//! An invalid value.
	SeaToolsInvalid = -1,
	//! The rectangular selection tool.
	SeaToolsSelectRect = 0,
	//! The elliptical selection tool.
	SeaToolsSelectEllipse = 1,
	//! The lasso tool.
	SeaToolsLasso = 2,
	//! The polygon lasso tool.
	SeaToolsPolygonLasso = 3,
	//! The wand selection tool.
	SeaToolsWand = 4,
	//! The pencil tool.
	SeaToolsPencil = 5,
	//! The paintbrush tool.
	SeaToolsBrush = 6,
	//! The colour sampling tool.
	SeaToolsEyedrop = 7,
	//! The text tool.
	SeaToolsText = 8,
	//! The eraser tool.
	SeaToolsEraser = 9,
	//! The paint bucket tool.
	SeaToolsBucket = 10,
	//! The gradient tool.
	SeaToolsGradient = 11,
	//! The crop tool.
	SeaToolsCrop = 12,
	//! The clone tool.
	SeaToolsClone = 13,
	//! The smudging tool.
	SeaToolsSmudge = 14,
	//! The effect tool.
	SeaToolsEffect = 15,
	//! The zoom tool.
	SeaToolsZoom = 16,
	//! The layer positioning tool.
	SeaToolsPosition = 17,
	//! The first selection tool.
	SeaToolsFirstSelection = 0,
	//! The last selection tool.
	SeaToolsLastSelection = 4,
	//! The last tool.
	SeaToolsLast = 17
};

@class AbstractTool;
@class RectSelectTool;
@class EllipseSelectTool;
@class LassoTool;
@class PolygonLassoTool;
@class WandTool;
@class PencilTool;
@class BrushTool;
@class BucketTool;
@class TextTool;
@class EyedropTool;
@class EraserTool;
@class PositionTool;
@class GradientTool;
@class SmudgeTool;
@class CloneTool;
@class CropTool;
@class EffectTool;

/*!
	@class		SeaTools
	@abstract	Acts as a gateway to all the tools of Seashore.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface SeaTools : NSObject {
	// Various objects representing various tools
	IBOutlet RectSelectTool *rectSelectTool;
	IBOutlet EllipseSelectTool *ellipseSelectTool;
	IBOutlet LassoTool *lassoTool;
	IBOutlet PolygonLassoTool *polygonLassoTool;
	IBOutlet WandTool *wandTool;
	IBOutlet PencilTool *pencilTool;
	IBOutlet BrushTool *brushTool;
	IBOutlet BucketTool *bucketTool;
	IBOutlet TextTool *textTool;
	IBOutlet EyedropTool *eyedropTool;
	IBOutlet EraserTool *eraserTool;
    IBOutlet PositionTool *positionTool;
	IBOutlet GradientTool *gradientTool;
	IBOutlet SmudgeTool *smudgeTool;
	IBOutlet CloneTool *cloneTool;
	IBOutlet CropTool *cropTool;
	IBOutlet EffectTool *effectTool;
	//IBOutlet AbstractTool *zoomTool;
}

/*!
	@method		currentTool
	@discussion	Returns the currently active tool according to the toolbox
				utility.
	@result		Returns an object that is a subclass of AbstractTool.
*/
- (nullable __kindof AbstractTool*)currentTool;

/*!
	@method		getTool:
	@discussion	Given a tool type returns the corresponding tool.
	@param		whichOne
				The tool type for the tool you are seeking.
	@result		Returns an object that is a subclass of <code>AbstractTool</code>.
*/
- (nullable __kindof AbstractTool*)getTool:(SeaToolsDefines)whichOne;

/*!
	@property	allTools
	@discussion	This is purely for initialization to connect the options to the tools.
	@result		Returns an array of AbstractTools.
*/
@property (readonly, copy, nonnull) NSArray<__kindof AbstractTool*> *allTools;

@end
