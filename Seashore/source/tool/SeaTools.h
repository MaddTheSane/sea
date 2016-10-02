#import <Cocoa/Cocoa.h>
#import <SeashoreKit/Globals.h>

/*
	@enum		k...Tool
	@constant	kRectSelectTool
				The rectangular selection tool.
	@constant	kEllipseSelectTool
				The elliptical selection tool.
	@constant	kLassoTool
				The lasso tool.
	@constant	kPolygonLassoTool
				The polygon lasso tool.
	@constant   kWandTool
				The wand selection tool.
	@constant	kPencilTool
				The pencil tool.
	@constant	kBrushTool
				The paintbrush tool.
	@constant	kEyedropTool
				The colour sampling tool.
	@constant	kTextTool
				The text tool.
	@constant	kEraserTool
				The eraser tool.
	@constant	kBucketTool
				The paint bucket tool.
	@constant	kGradientTool
				The gradient tool.
	@constant	kCropTool
				The crop tool.
	@constant	kCloneTool
				The clone tool.
	@constant	kSmudgeTool
				The smudging tool.
	@constant	kEffectTool
				The effect tool.
	@constant	kZoomTool
				The zoom tool.
	@constant	kPositionTool
				The layer positioning tool.
	@constant	kFirstSelectionTool
				The first selection tool.
	@constant	kLastSelectionTool
				The last selection tool.
*/
typedef NS_ENUM(int, SeaToolsDefines) {
	//! An invalid value.
	SeaToolsInvalid = -1,
	//! The rectangular selection tool.
	kRectSelectTool = 0,
	//! The elliptical selection tool.
	kEllipseSelectTool = 1,
	//! The lasso tool.
	kLassoTool = 2,
	//! The polygon lasso tool.
	kPolygonLassoTool = 3,
	//! The wand selection tool.
	kWandTool = 4,
	//! The pencil tool.
	kPencilTool = 5,
	//! The paintbrush tool.
	kBrushTool = 6,
	//! The colour sampling tool.
	kEyedropTool = 7,
	//! The text tool.
	kTextTool = 8,
	//! The eraser tool.
	kEraserTool = 9,
	//! The paint bucket tool.
	kBucketTool = 10,
	//! The gradient tool.
	kGradientTool = 11,
	//! The crop tool.
	kCropTool = 12,
	//! The clone tool.
	kCloneTool = 13,
	//! The smudging tool.
	kSmudgeTool = 14,
	//! The effect tool.
	kEffectTool = 15,
	//! The zoom tool.
	kZoomTool = 16,
	//! The layer positioning tool.
	kPositionTool = 17,
	//! The first selection tool.
	kFirstSelectionTool = 0,
	//! The last selection tool.
	kLastSelectionTool = 4,
	//! The last tool.
	kLastTool = 17
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
