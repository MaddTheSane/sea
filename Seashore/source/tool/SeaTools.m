#import "SeaTools.h"
#import "ToolboxUtility.h"
#import "SeaController.h"
#import "UtilitiesManager.h"
#import "AbstractTool.h"
#import "RectSelectTool.h"
#import "EllipseSelectTool.h"
#import "LassoTool.h"
#import "PolygonLassoTool.h"
#import "WandTool.h"
#import "PencilTool.h"
#import "BrushTool.h"
#import "BucketTool.h"
#import "TextTool.h"
#import "EyedropTool.h"
#import "EraserTool.h"
#import "PositionTool.h"
#import "GradientTool.h"
#import "SmudgeTool.h"
#import "CloneTool.h"
#import "CropTool.h"
#import "EffectTool.h"
#import <SeashoreKit/SeaDocument.h>

@implementation SeaTools

- (id)currentTool
{
	return [self getTool:[[[SeaController utilitiesManager] toolboxUtilityFor:gCurrentDocument] tool]];
}

- (id)getTool:(SeaToolsDefines)whichOne
{
	switch (whichOne) {
		case SeaToolsInvalid:
			return nil;
			
		case kRectSelectTool:
			return rectSelectTool;
		break;
		case kEllipseSelectTool:
			return ellipseSelectTool;
		break;
		case kLassoTool:
			return lassoTool;
		break;
		case kPolygonLassoTool:
			return polygonLassoTool;
		break;
		case kWandTool:
			return wandTool;
		break;
		case kPencilTool:
			return pencilTool;
		break;
		case kBrushTool:
			return brushTool;
		break;
		case kBucketTool:
			return bucketTool;
		break;
		case kTextTool:
			return textTool;
		break;
		case kEyedropTool:
			return eyedropTool;
		break;
		case kEraserTool:
			return eraserTool;
		break;
		case kPositionTool:
			return positionTool;
		break;
		case kGradientTool:
			return gradientTool;
		break;
		case kSmudgeTool:
			return smudgeTool;
		break;
		case kCloneTool:
			return cloneTool;
		break;
		case kCropTool:
			return cropTool;
		break;
		case kEffectTool:
			return effectTool;
		break;
			
		case kZoomTool:
			
			break;
	}
	
	return NULL;
}

- (NSArray *)allTools
{
	return @[rectSelectTool, ellipseSelectTool, lassoTool, polygonLassoTool, wandTool, pencilTool, brushTool, bucketTool, textTool, eyedropTool, eraserTool, positionTool, gradientTool, smudgeTool, cloneTool, cropTool, effectTool];
}
@end
