#import "UtilitiesManager.h"
#import "PegasusUtility.h"
#import "ToolboxUtility.h"
#import "OptionsUtility.h"
#import "InfoUtility.h"
#import "SeaController.h"

@implementation UtilitiesManager {
	// Outlets to the various utilities of Seashore
	NSMapTable<SeaDocument*,PegasusUtility*> *pegasusUtilities;
	NSMapTable<SeaDocument*,TransparentUtility*> *transparentUtilities;
	NSMapTable<SeaDocument*,ToolboxUtility*> *toolboxUtilities;
	NSMapTable<SeaDocument*,BrushUtility*> *brushUtilities;
	NSMapTable<SeaDocument*,OptionsUtility*> *optionsUtilities;
	NSMapTable<SeaDocument*,TextureUtility*> *textureUtilities;
	NSMapTable<SeaDocument*,InfoUtility*> *infoUtilities;
	NSMapTable<SeaDocument*,StatusUtility*> *statusUtilities;
}

- (instancetype)init
{
	if(![super init])
		return nil;
	pegasusUtilities = [[NSMapTable alloc] initWithKeyOptions:NSMapTableWeakMemory valueOptions:NSMapTableStrongMemory capacity:5];
	toolboxUtilities = [[NSMapTable alloc] initWithKeyOptions:NSMapTableWeakMemory valueOptions:NSMapTableStrongMemory capacity:5];
	brushUtilities = [[NSMapTable alloc] initWithKeyOptions:NSMapTableWeakMemory valueOptions:NSMapTableStrongMemory capacity:5];
	optionsUtilities = [[NSMapTable alloc] initWithKeyOptions:NSMapTableWeakMemory valueOptions:NSMapTableStrongMemory capacity:5];
	textureUtilities = [[NSMapTable alloc] initWithKeyOptions:NSMapTableWeakMemory valueOptions:NSMapTableStrongMemory capacity:5];
	infoUtilities = [[NSMapTable alloc] initWithKeyOptions:NSMapTableWeakMemory valueOptions:NSMapTableStrongMemory capacity:5];
	statusUtilities = [[NSMapTable alloc] initWithKeyOptions:NSMapTableWeakMemory valueOptions:NSMapTableStrongMemory capacity:5];
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
	[pegasusUtilities removeObjectForKey:doc];
	[toolboxUtilities removeObjectForKey:doc];
	
	[[self brushUtilityForDocument:doc] shutdown];
	[brushUtilities removeObjectForKey:doc];
	
	[[self optionsUtilityForDocument:doc] shutdown];
	[optionsUtilities removeObjectForKey:doc];
	
	[[self textureUtilityForDocument:doc] shutdown];
	[textureUtilities removeObjectForKey:doc];
	
	[[self infoUtilityForDocument:doc] shutdown];
	[infoUtilities removeObjectForKey:doc];
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
	return [pegasusUtilities objectForKey:doc];
}

@synthesize transparentUtility;

- (ToolboxUtility*)toolboxUtilityForDocument:(SeaDocument*)doc
{
	return [toolboxUtilities objectForKey:doc];
}

- (BrushUtility*)brushUtilityForDocument:(SeaDocument*)doc
{
	return [brushUtilities objectForKey:doc];
}

- (TextureUtility*)textureUtilityForDocument:(SeaDocument*)doc
{
	return [textureUtilities objectForKey:doc];
}

- (OptionsUtility*)optionsUtilityForDocument:(SeaDocument*)doc
{
	return [optionsUtilities objectForKey:doc];
}

- (InfoUtility*)infoUtilityForDocument:(SeaDocument*)doc
{
	return [infoUtilities objectForKey:doc];
}

- (StatusUtility*)statusUtilityFor:(SeaDocument*)doc
{
	return [statusUtilities objectForKey:doc];
}

- (void)setPegasusUtility:(PegasusUtility*)util forDocument:(SeaDocument*)doc
{
	[pegasusUtilities setObject:util forKey:doc];
}

- (void)setToolboxUtility:(ToolboxUtility*)util forDocument:(SeaDocument*)doc
{
	[toolboxUtilities setObject:util forKey:doc];
}

- (void)setBrushUtility:(BrushUtility*)util forDocument:(SeaDocument*)doc
{
	[brushUtilities setObject:util forKey:doc];
}

- (void)setTextureUtility:(TextureUtility*)util forDocument:(SeaDocument*)doc
{
	[textureUtilities setObject:util forKey:doc];
}

- (void)setOptionsUtility:(OptionsUtility*)util forDocument:(SeaDocument*)doc
{
	[optionsUtilities setObject:util forKey:doc];
}

- (void)setInfoUtility:(InfoUtility*)util forDocument:(SeaDocument*)doc
{
	[infoUtilities setObject:util forKey:doc];
}

- (void)setStatusUtility:(StatusUtility*)util forDocument:(SeaDocument*)doc
{
	[statusUtilities setObject:util forKey:doc];
}

@end
