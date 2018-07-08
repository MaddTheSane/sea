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
#import "Seashore-Swift.h"
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
			
		case SeaToolsSelectRect:
			return rectSelectTool;
		break;
		case SeaToolsSelectEllipse:
			return ellipseSelectTool;
		break;
		case SeaToolsLasso:
			return lassoTool;
		break;
		case SeaToolsPolygonLasso:
			return polygonLassoTool;
		break;
		case SeaToolsWand:
			return wandTool;
		break;
		case SeaToolsPencil:
			return pencilTool;
		break;
		case SeaToolsBrush:
			return brushTool;
		break;
		case SeaToolsBucket:
			return bucketTool;
		break;
		case SeaToolsText:
			return textTool;
		break;
		case SeaToolsEyedrop:
			return eyedropTool;
		break;
		case SeaToolsEraser:
			return eraserTool;
		break;
		case SeaToolsPosition:
			return positionTool;
		break;
		case SeaToolsGradient:
			return gradientTool;
		break;
		case SeaToolsSmudge:
			return smudgeTool;
		break;
		case SeaToolsClone:
			return cloneTool;
		break;
		case SeaToolsCrop:
			return cropTool;
		break;
		case SeaToolsEffect:
			return effectTool;
		break;
			
		case SeaToolsZoom:
			
			break;
	}
	
	return NULL;
}

- (NSArray *)allTools
{
	return @[rectSelectTool, ellipseSelectTool, lassoTool, polygonLassoTool, wandTool, pencilTool, brushTool, bucketTool, textTool, eyedropTool, eraserTool, positionTool, gradientTool, smudgeTool, cloneTool, cropTool, effectTool];
}
@end
