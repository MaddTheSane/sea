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
		return nil;
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

- (void)shutdownForDocument:(SeaDocument*)doc
{
	NSNumber *key = @((size_t)doc);

	[pegasusUtilities removeObjectForKey:key];
	[toolboxUtilities removeObjectForKey:key];
	
	[[self brushUtilityForDocument:doc] shutdown];
	[brushUtilities removeObjectForKey:key];
	
	[[self optionsUtilityForDocument:doc] shutdown];
	[optionsUtilities removeObjectForKey:key];
	
	[[self textureUtilityForDocument:doc] shutdown];
	[textureUtilities removeObjectForKey:key];
	
	[[self infoUtilityForDocument:doc] shutdown];
	[infoUtilities removeObjectForKey:key];
}

- (void)activate:(SeaDocument*)sender
{
	[[self pegasusUtilityForDocument:sender] activate];
	[[self toolboxUtilityForDocument:sender] activate];
	[[self optionsUtilityForDocument:sender] activate];
	[[self infoUtilityForDocument:sender] activate];
}

- (PegasusUtility*)pegasusUtilityForDocument:(SeaDocument*)doc
{
	return pegasusUtilities[@((size_t)doc)];
}

@synthesize transparentUtility;

- (ToolboxUtility*)toolboxUtilityForDocument:(SeaDocument*)doc
{
	return toolboxUtilities[@((size_t)doc)];
}

- (BrushUtility*)brushUtilityForDocument:(SeaDocument*)doc
{
	return brushUtilities[@((size_t)doc)];
}

- (TextureUtility*)textureUtilityForDocument:(SeaDocument*)doc
{
	return textureUtilities[@((size_t)doc)];
}

- (OptionsUtility*)optionsUtilityForDocument:(SeaDocument*)doc
{
	return optionsUtilities[@((size_t)doc)];
}

- (InfoUtility*)infoUtilityForDocument:(SeaDocument*)doc
{
	return infoUtilities[@((size_t)doc)];
}

- (StatusUtility*)statusUtilityFor:(SeaDocument*)doc
{
	return statusUtilities[@((size_t)doc)];
}

- (void)setPegasusUtility:(PegasusUtility*)util forDocument:(SeaDocument*)doc
{
	pegasusUtilities[@((size_t)doc)] = util;
}

- (void)setToolboxUtility:(ToolboxUtility*)util forDocument:(SeaDocument*)doc
{
	toolboxUtilities[@((size_t)doc)] = util;
}

- (void)setBrushUtility:(BrushUtility*)util forDocument:(SeaDocument*)doc
{
	brushUtilities[@((size_t)doc)] = util;
}

- (void)setTextureUtility:(TextureUtility*)util forDocument:(SeaDocument*)doc
{
	textureUtilities[@((size_t)doc)] = util;
}

- (void)setOptionsUtility:(OptionsUtility*)util forDocument:(SeaDocument*)doc
{
	optionsUtilities[@((size_t)doc)] = util;
}

- (void)setInfoUtility:(InfoUtility*)util forDocument:(SeaDocument*)doc
{
	infoUtilities[@((size_t)doc)] = util;
}

- (void)setStatusUtility:(StatusUtility*)util forDocument:(SeaDocument*)doc
{
	statusUtilities[@((size_t)doc)] = util;
}

@end
