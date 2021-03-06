#import "AspectRatio.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "Units.h"

#define customItemIndex 2

@implementation AspectRatio

- (void)awakeWithMaster:(id)imaster andString:(NSString*)iprefString
{
	NSInteger ratioIndex;
	id customItem;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	master = imaster;
	prefString = [iprefString copy];

	[ratioCheckbox setState:NSOffState];
	[ratioPopup setEnabled:[ratioCheckbox state]];
	
	if ([defaults objectForKey:[NSString stringWithFormat:@"%@ ratio index", prefString]] == NULL) {
		[ratioPopup selectItemAtIndex:1];
	}
	else {
		ratioIndex = [defaults integerForKey:[NSString stringWithFormat:@"%@ ratio index", prefString]];
		if (ratioIndex < 0 || ratioIndex > customItemIndex) ratioIndex = 1;
		[ratioPopup selectItemAtIndex:ratioIndex];
	}

	if ([defaults objectForKey:[NSString stringWithFormat:@"%@ ratio horiz", prefString]] == NULL) {
		ratioX = 2.0;
	}
	else {
		ratioX = [defaults integerForKey:[NSString stringWithFormat:@"%@ ratio horiz", prefString]];
	}
	
	if ([defaults objectForKey:[NSString stringWithFormat:@"%@ ratio vert", prefString]] == NULL) {
		ratioY = 1.0;
	}
	else {
		ratioY = [defaults integerForKey:[NSString stringWithFormat:@"%@ ratio vert", prefString]];
	}
	
	if ([defaults objectForKey:[NSString stringWithFormat:@"%@ ratio type", prefString]] == NULL) {
		aspectType = SeaAspectTypeRatio;
	}
	else {
		aspectType = [defaults integerForKey:[NSString stringWithFormat:@"%@ ratio type", prefString]];
	}
	
	customItem = [ratioPopup itemAtIndex:customItemIndex];
	switch (aspectType) {
		case SeaAspectTypeRatio:
			[customItem setTitle:[NSString stringWithFormat:@"%g to %g", ratioX, ratioY]];
			break;
			
		case SeaAspectTypeExactPixel:
			[customItem setTitle:[NSString stringWithFormat:@"%d by %d px", (int)ratioX, (int)ratioY]];
			break;
			
		case SeaAspectTypeExactInch:
			[customItem setTitle:[NSString stringWithFormat:@"%g by %g in", ratioX, ratioY]];
			break;
			
		case SeaAspectTypeExactMillimeter:
			[customItem setTitle:[NSString stringWithFormat:@"%g by %g mm", ratioX, ratioY]];
			break;
			
		case SeaAspectTypeNone:
			break;
	}

	forgotX = 472;
	forgotY = 364;
}

- (IBAction)setCustomItem:(id)sender
{
	[xRatioValue setStringValue:[NSString stringWithFormat:@"%g", ratioX]];
	[yRatioValue setStringValue:[NSString stringWithFormat:@"%g", ratioY]];
	switch (aspectType) {
		case SeaAspectTypeRatio:
			[toLabel setStringValue:@"to"];
			[aspectTypePopup selectItemAtIndex:0];
			break;
			
		case SeaAspectTypeExactPixel:
			[toLabel setStringValue:@"by"];
			[aspectTypePopup selectItemAtIndex:1];
			break;
			
		case SeaAspectTypeExactInch:
			[toLabel setStringValue:@"by"];
			[aspectTypePopup selectItemAtIndex:2];
			break;
			
		case SeaAspectTypeExactMillimeter:
			[toLabel setStringValue:@"by"];
			[aspectTypePopup selectItemAtIndex:3];
			break;
			
		case SeaAspectTypeNone:
			break;
	}
	
	[panel center];
	[panel makeFirstResponder:xRatioValue];
	[document.window beginSheet:panel completionHandler:^(NSModalResponse returnCode) {
		
	}];
}

- (IBAction)applyCustomItem:(id)sender
{
	id customItem;
	
	if (aspectType == SeaAspectTypeExactPixel) {
		ratioX = [xRatioValue intValue];
		ratioY = [yRatioValue intValue];
	}
	else {
		ratioX = [xRatioValue floatValue];
		ratioY = [yRatioValue floatValue];
	}
	customItem = [ratioPopup itemAtIndex:customItemIndex];
	switch (aspectType) {
		case SeaAspectTypeRatio:
			[customItem setTitle:[NSString stringWithFormat:@"%g to %g", ratioX, ratioY]];
		break;
			
		case SeaAspectTypeExactPixel:
			[customItem setTitle:[NSString stringWithFormat:@"%d by %d px", (int)ratioX, (int)ratioY]];
		break;
			
		case SeaAspectTypeExactInch:
			[customItem setTitle:[NSString stringWithFormat:@"%g by %g in", ratioX, ratioY]];
		break;
			
		case SeaAspectTypeExactMillimeter:
			[customItem setTitle:[NSString stringWithFormat:@"%g by %g mm", ratioX, ratioY]];
		break;
			
		case SeaAspectTypeNone:
			break;

	}
	[NSApp stopModal];
	[document.window endSheet:panel returnCode:NSModalResponseOK];
	[panel orderOut:self];
	[ratioPopup selectItemAtIndex:customItemIndex];
}

- (IBAction)changeCustomAspectType:(id)sender
{
	CGFloat xres = [[gCurrentDocument contents] xres], yres = [[gCurrentDocument contents] yres];
	SeaAspectType oldType;
	
	oldType = aspectType;
	aspectType = [aspectTypePopup indexOfSelectedItem] - 1;
	if (oldType != SeaAspectTypeRatio) {
		forgotX = SeaPixelsFromFloat([xRatioValue doubleValue], (SeaUnits)oldType, xres);
		forgotY = SeaPixelsFromFloat([yRatioValue doubleValue], (SeaUnits)oldType, yres);
	}
	switch (aspectType) {
		case SeaAspectTypeRatio:
			ratioX = 2;
			ratioY = 1;
			[xRatioValue setStringValue:[NSString stringWithFormat:@"%d", (int)ratioX]];
			[yRatioValue setStringValue:[NSString stringWithFormat:@"%d", (int)ratioY]];
			[toLabel setStringValue:@"to"];
			[aspectTypePopup setTitle:@"ratio"];
			break;
		case SeaAspectTypeExactPixel:
			[xRatioValue setStringValue:SeaStringFromPixels(forgotX, (SeaUnits)aspectType, xres)];
			[yRatioValue setStringValue:SeaStringFromPixels(forgotY, (SeaUnits)aspectType, yres)];
			ratioX = [xRatioValue floatValue];
			ratioY = [yRatioValue floatValue];
			[toLabel setStringValue:@"by"];
			[aspectTypePopup setTitle:@"px"];
			break;
		case SeaAspectTypeExactInch:
			[xRatioValue setStringValue:SeaStringFromPixels(forgotX, (SeaUnits)aspectType, xres)];
			[yRatioValue setStringValue:SeaStringFromPixels(forgotY, (SeaUnits)aspectType, yres)];
			ratioX = [xRatioValue floatValue];
			ratioY = [yRatioValue floatValue];
			[toLabel setStringValue:@"by"];
			[aspectTypePopup setTitle:@"in"];
			break;
		case SeaAspectTypeExactMillimeter:
			[xRatioValue setStringValue:SeaStringFromPixels(forgotX, (SeaUnits)aspectType, xres)];
			[yRatioValue setStringValue:SeaStringFromPixels(forgotY, (SeaUnits)aspectType, yres)];
			ratioX = [xRatioValue floatValue];
			ratioY = [yRatioValue floatValue];
			[toLabel setStringValue:@"by"];
			[aspectTypePopup setTitle:@"mm"];
			break;
			
		case SeaAspectTypeNone:
			break;
			
	}
}

- (NSSize)ratio
{
	NSSize result;
	
	switch ([ratioPopup indexOfSelectedItem]) {
		case 0:
			result = NSMakeSize(1.0, 1.0);
			break;
			
		case 1:
			result = NSMakeSize(4.0 / 3.0, 3.0 / 4.0);
			break;
			
		case 2:
			if (aspectType == SeaAspectTypeRatio)
				result = NSMakeSize(ratioX / ratioY, ratioY / ratioX);
			else if (aspectType == SeaAspectTypeExactPixel)
				result = NSMakeSize((int)ratioX, (int)ratioY);
			else
				result = NSMakeSize(ratioX, ratioY);
			break;
			
		default:
			result = NSMakeSize(1.0, 1.0);
			break;
	}
	
	if (result.width <= 0.0)
		result.width = 1.0;
	if (result.height <= 0.0)
		result.height = 1.0;
	
	return result;
}

- (SeaAspectType)aspectType
{
	SeaAspectType result;
	
	if ([ratioCheckbox state]) {
		if ([ratioPopup indexOfSelectedItem] < customItemIndex)
			result = SeaAspectTypeRatio;
		else
			result = aspectType;
	} else {
		result = SeaAspectTypeNone;
	}
	
	return result;
}

- (IBAction)update:(id)sender;
{
	[ratioPopup setEnabled:[ratioCheckbox state]];
}

- (void)shutdown
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:[ratioPopup indexOfSelectedItem] forKey:[NSString stringWithFormat:@"%@ ratio index", prefString]];
	[defaults setFloat:ratioX forKey:[NSString stringWithFormat:@"%@ ratio index", prefString]];
	[defaults setFloat:ratioY forKey:[NSString stringWithFormat:@"%@ ratio index", prefString]];
	[defaults setInteger:aspectType forKey:[NSString stringWithFormat:@"%@ ratio index", prefString]];
}

@end
