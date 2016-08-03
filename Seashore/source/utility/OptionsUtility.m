#import "OptionsUtility.h"
#import "ToolboxUtility.h"
#import "AbstractOptions.h"
#import "SeaTools.h"
#import "SeaController.h"
#import "SeaPrefs.h"
#import "ZoomOptions.h"
#import "AbstractSelectOptions.h"
#import "UtilitiesManager.h"
#import "SeaDocument.h"
#import "AbstractTool.h"
#import "SeaWindowContent.h"

// SeaOptions subclasses
#import "LassoOptions.h"
#import "PolygonLassoOptions.h"
#import "PositionOptions.h"
#import "ZoomOptions.h"
#import "PencilOptions.h"
#import "BrushOptions.h"
#import "BucketOptions.h"
#import "TextOptions.h"
#import "EyedropOptions.h"
#import "RectSelectOptions.h"
#import "EllipseSelectOptions.h"
#import "EraserOptions.h"
#import "SmudgeOptions.h"
#import "GradientOptions.h"
#import "WandOptions.h"
#import "CloneOptions.h"
#import "CropOptions.h"
#import "EffectOptions.h"

@implementation OptionsUtility

- (instancetype)init
{
	if (self = [super init]) {
		currentTool = -1;
	}
	
	return self;
}

- (void)awakeFromNib
{
	[view addSubview:blankView];
	lastView = blankView;
	
	NSArray *allTools = [[document tools] allTools];
	for (AbstractTool *tool in allTools){
		[tool setOptions: [self getOptions:[tool toolId]]];
	}
	
	[[SeaController utilitiesManager] setOptionsUtility: self for:document];
}

- (void)activate
{
	[self update];
}

- (void)deactivate
{
	[self update];
}

- (void)shutdown
{
	int i = 0;
	id options = NULL;
	
	do {
		options = [self getOptions:i];
		[options shutdown];
		i++;
	} while (options != NULL);
}

- (__kindof AbstractOptions*)currentOptions
{
	if (document == NULL)
		return NULL;
	else
		return [self getOptions:[toolboxUtility tool]];
}

- (__kindof AbstractOptions*)getOptions:(SeaToolsDefines)whichTool
{
	switch (whichTool) {
		case kRectSelectTool:
			return rectSelectOptions;
		break;
		case kEllipseSelectTool:
			return ellipseSelectOptions;
		break;
		case kLassoTool:
			return lassoOptions;
		break;
		case kPolygonLassoTool:
			return polygonLassoOptions;
		break;
		case kPositionTool:
			return positionOptions;
		break;
		case kZoomTool:
			return zoomOptions;
		break;
		case kPencilTool:
			return pencilOptions;
		break;
		case kBrushTool:
			return brushOptions;
		break;
		case kBucketTool:
			return bucketOptions;
		break;
		case kTextTool:
			return textOptions;
		break;
		case kEyedropTool:
			return eyedropOptions;
		break;
		case kEraserTool:
			return eraserOptions;
		break;
		case kSmudgeTool:
			return smudgeOptions;
		break;
		case kGradientTool:
			return gradientOptions;
		break;
		case kWandTool:
			return wandOptions;
		break;
		case kCloneTool:
			return cloneOptions;
		break;
		case kCropTool:
			return cropOptions;
		break;
		case kEffectTool:
			return effectOptions;
		break;
			
		case SeaToolsInvalid:
			return nil;
	}
	
	return NULL;
}

- (void)update
{
	AbstractOptions *currentOptions = [self currentOptions];
	
	// If there are no current options put up a blank view
	if (currentOptions == NULL) {
		[view replaceSubview:lastView with:blankView];
		lastView = blankView;
		currentTool = -1;
		return;
	}
	
	// Otherwise select the current options are up-to-date with the current tool
	if (currentTool != [toolboxUtility tool]) {
		[view replaceSubview:lastView with:[currentOptions view]];
		lastView = [currentOptions view];
		currentTool = [toolboxUtility tool];
	}
	
	// Update the options
	[currentOptions activate:document];
	[currentOptions update];
}

- (IBAction)show:(id)sender
{
	[[[document window] contentView] setVisibility:YES forRegion:SeaWindowRegionOptionsBar];
}

- (IBAction)hide:(id)sender
{
	[[[document window] contentView] setVisibility:NO forRegion:SeaWindowRegionOptionsBar];
}


- (IBAction)toggle:(id)sender
{
	if (self.visible) {
		[self hide:sender];
	} else {
		[self show:sender];
	}
}

- (void)viewNeedsDisplay
{
	[view setNeedsDisplay: YES];
}

- (BOOL)isVisible
{
	return [[[document window] contentView] visibilityForRegion: SeaWindowRegionOptionsBar];
}

@end
