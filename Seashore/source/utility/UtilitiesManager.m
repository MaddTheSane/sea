#import "UtilitiesManager.h"
#import "PegasusUtility.h"
#import "ToolboxUtility.h"
#import "OptionsUtility.h"
#import "InfoUtility.h"
#import "SeaController.h"

@implementation UtilitiesManager

- (instancetype)init
{
	if(![super init])
		return NULL;
	pegasusUtilities = [[NSMutableDictionary alloc] init];
	toolboxUtilities = [[NSMutableDictionary alloc] init];
	brushUtilities = [[NSMutableDictionary alloc] init];
	optionsUtilities = [[NSMutableDictionary alloc] init];
	textureUtilities = [[NSMutableDictionary alloc] init];
	infoUtilities = [[NSMutableDictionary alloc] init];
	statusUtilities = [[NSMutableDictionary alloc] init];
	return self;
}

- (void)awakeFromNib
{	
	// Make sure we are informed when the application shuts down
	[controller registerForTermination:self];
}

- (void)terminate
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	pegasusUtilities = nil;
	toolboxUtilities = nil;
	brushUtilities = nil;
	optionsUtilities = nil;
	textureUtilities = nil;
	infoUtilities = nil;
	statusUtilities = nil;
	
	// Force such information to be written to the hard disk
	[defaults synchronize];
}

- (void)shutdownFor:(id)doc
{
	NSNumber *key = @((size_t)doc);

	[pegasusUtilities removeObjectForKey:key];
	[toolboxUtilities  removeObjectForKey:key];
	
	[[self brushUtilityFor:doc] shutdown];
	[brushUtilities  removeObjectForKey:key];
	
	[[self optionsUtilityFor:doc] shutdown];
	[optionsUtilities  removeObjectForKey:key];
	
	[[self textureUtilityFor:doc] shutdown];
	[textureUtilities  removeObjectForKey:key];
	
	[[self infoUtilityFor:doc] shutdown];
	[infoUtilities  removeObjectForKey:key];
}

- (void)activate:(id)sender
{
	[(PegasusUtility *)[self pegasusUtilityFor:sender] activate];
	[(ToolboxUtility *)[self toolboxUtilityFor:sender] activate];
	[(OptionsUtility *)[self optionsUtilityFor:sender] activate];
	[(InfoUtility *)[self infoUtilityFor:sender] activate];
}

- (id)pegasusUtilityFor:(id)doc
{
	return pegasusUtilities[@((size_t)doc)];
}

- (id)transparentUtility
{
	return transparentUtility;
}

- (id)toolboxUtilityFor:(id)doc
{
	return toolboxUtilities[@((size_t)doc)];
}

- (id)brushUtilityFor:(id)doc
{
	return brushUtilities[@((size_t)doc)];
}

- (id)textureUtilityFor:(id)doc
{
	return textureUtilities[@((size_t)doc)];
}

- (id)optionsUtilityFor:(id)doc
{
	return optionsUtilities[@((size_t)doc)];
}

- (id)infoUtilityFor:(id)doc
{
	return infoUtilities[@((size_t)doc)];
}

- (id)statusUtilityFor:(id)doc
{
	return statusUtilities[@((size_t)doc)];
}

- (void)setPegasusUtility:(id)util for:(id)doc
{
	pegasusUtilities[@((size_t)doc)] = util;
}

- (void)setToolboxUtility:(id)util for:(id)doc
{
	toolboxUtilities[@((size_t)doc)] = util;
}

- (void)setBrushUtility:(id)util for:(id)doc
{
	brushUtilities[@((size_t)doc)] = util;
}

- (void)setTextureUtility:(id)util for:(id)doc
{
	textureUtilities[@((size_t)doc)] = util;
}

- (void)setOptionsUtility:(id)util for:(id)doc
{
	optionsUtilities[@((size_t)doc)] = util;
}

- (void)setInfoUtility:(id)util for:(id)doc
{
	infoUtilities[@((size_t)doc)] = util;
}

- (void)setStatusUtility:(id)util for:(id)doc
{
	statusUtilities[@((size_t)doc)] = util;
}

@end
