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
		case SeaToolsSelectRect:
			return rectSelectOptions;
		break;
		case SeaToolsSelectEllipse:
			return ellipseSelectOptions;
		break;
		case SeaToolsLasso:
			return lassoOptions;
		break;
		case SeaToolsPolygonLasso:
			return polygonLassoOptions;
		break;
		case SeaToolsPosition:
			return positionOptions;
		break;
		case SeaToolsZoom:
			return zoomOptions;
		break;
		case SeaToolsPencil:
			return pencilOptions;
		break;
		case SeaToolsBrush:
			return brushOptions;
		break;
		case SeaToolsBucket:
			return bucketOptions;
		break;
		case SeaToolsText:
			return textOptions;
		break;
		case SeaToolsEyedrop:
			return eyedropOptions;
		break;
		case SeaToolsEraser:
			return eraserOptions;
		break;
		case SeaToolsSmudge:
			return smudgeOptions;
		break;
		case SeaToolsGradient:
			return gradientOptions;
		break;
		case SeaToolsWand:
			return wandOptions;
		break;
		case SeaToolsClone:
			return cloneOptions;
		break;
		case SeaToolsCrop:
			return cropOptions;
		break;
		case SeaToolsEffect:
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
