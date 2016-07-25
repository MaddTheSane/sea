#import "SeaWindowContent.h"


@implementation SeaWindowContent

-(void)awakeFromNib
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	dict = @{@(kOptionsBar): [NSMutableDictionary dictionaryWithObjectsAndKeys: @YES, @"visibility", optionsBar, @"view", nonOptionsBar, @"nonView", @"above", @"side", @0.0f, @"oldValue", nil],
			 @(kSidebar): [NSMutableDictionary dictionaryWithObjectsAndKeys: @YES, @"visibility", sidebar, @"view", nonSidebar, @"nonView", @"left", @"side", @0.0f, @"oldValue", nil],
			 @(kPointInformation): [NSMutableDictionary dictionaryWithObjectsAndKeys: @YES, @"visibility", pointInformation, @"view", layers, @"nonView", @"below", @"side", @0.0f, @"oldValue", nil],
			 @(kWarningsBar): [NSMutableDictionary dictionaryWithObjectsAndKeys: @YES, @"visibility", warningsBar, @"view", mainDocumentView, @"nonView", @"above", @"side", @0.0f, @"oldValue", nil],
			 @(kStatusBar): [NSMutableDictionary dictionaryWithObjectsAndKeys: @YES, @"visibility", statusBar, @"view", mainDocumentView, @"nonView", @"below", @"side", @0.0f, @"oldValue", nil]};
	
	int i;
	for(i = kOptionsBar; i <= kStatusBar; i++){
		NSString *key = [NSString stringWithFormat:@"region%ldvisibility", (long)i];
		if([defaults objectForKey: key] && ![defaults boolForKey:key]){
			// We need to hide it
			[self setVisibility: NO forRegion: i];
		}
	}
	
	// by default, the warning bar should be hidden. we will only show it iff we need it
	[self setVisibility:NO forRegion:kWarningsBar];
}

-(BOOL)visibilityForRegion:(SeaWindowRegion)region
{
	return [dict[@(region)][@"visibility"] boolValue];
}

-(void)setVisibility:(BOOL)visibility forRegion:(SeaWindowRegion)region
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary<NSString*,id> *thisDict = dict[@(region)];
	BOOL currentVisibility = [thisDict[@"visibility"] boolValue];
	
	// Check to see if we are already in the proper state
	if(currentVisibility == visibility){
		return;
	}
	
	CGFloat oldValue = [thisDict[@"oldValue"] doubleValue];
	NSView *view = thisDict[@"view"];
	NSView *nonView = thisDict[@"nonView"];
	NSString *side = thisDict[@"side"];
	if (!visibility) {
		
		if([side isEqual:@"above"] || [side isEqual:@"below"]){
			oldValue = [view frame].size.height;
		}else {
			oldValue = [view frame].size.width;
		}

		NSRect oldRect = [view frame];
		
		
		if([side isEqual:@"above"] || [side isEqual:@"below"]){
			oldRect.size.height = 0;
		}else {
			oldRect.size.width = 0;
		}
		
		[view setFrame:oldRect];
		
		oldRect = [nonView frame];
		
		if([side isEqual:@"above"]){
			oldRect.size.height += oldValue;
		}else if([side isEqual:@"below"]){
			oldRect.origin.y = [view frame].origin.y;
			oldRect.size.height += oldValue;
		}else if([side isEqual:@"left"]){
			oldRect.origin.x = [view frame].origin.x;
			oldRect.size.width += oldValue;
		}else if([side isEqual:@"right"]){
			oldRect.size.width += oldValue;
		}
		
		[nonView setFrame:oldRect];
				
		[nonView setNeedsDisplay:YES];
		
		thisDict[@"oldValue"] = @(oldValue);
		[defaults setObject: @"NO" forKey:[NSString stringWithFormat:@"region%ldvisibility", (long)region]];		
	} else {
		NSRect newRect = [view frame];
		if([side isEqual:@"above"] || [side isEqual:@"below"]){
			newRect.size.height = oldValue;
		}else{
			newRect.size.width = oldValue;
		}
		
		[view setFrame:newRect];
		
		newRect = [nonView frame];

		if([side isEqual:@"above"]){
			newRect.size.height -= oldValue;
		}else if([side isEqual:@"below"]){
			newRect.origin.y += oldValue;
			newRect.size.height -= oldValue;
		}else if([side isEqual:@"left"]){
			newRect.origin.x += oldValue;
			newRect.size.width -= oldValue;
		}else if([side isEqual:@"right"]){
			newRect.size.width -= oldValue;
		}
		
		[nonView setFrame:newRect];
				
		[nonView setNeedsDisplay:YES];
		
		[defaults setObject: @"YES" forKey:[NSString stringWithFormat:@"region%ldvisibility", (long)region]];
	}
	thisDict[@"visibility"] = @(visibility);
}

-(CGFloat)sizeForRegion:(SeaWindowRegion)region
{
	if ([self visibilityForRegion:region]) {
		NSMutableDictionary *thisDict = dict[@(region)];
		NSString *side = thisDict[@"side"];
		NSView *view = thisDict[@"view"];
		if([side isEqual: @"above"] || [side isEqual: @"below"]){
			return [view frame].size.height;
		}else{
			return [view frame].size.width;
		}
	}
	return 0.0;
}

@end
