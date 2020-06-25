//
//  NSOutlineView_Extensions.h
//
//  Copyright (c) 2001-2005, Apple. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SeaDocument;

@interface NSOutlineView(MyExtensions)

- (NSArray *)allSelectedItems;
- (void)selectItems:(NSArray *)items byExtendingSelection:(BOOL)extend;

@end

@interface SeaOutlineView : NSOutlineView
{
	//! The document the outline view is in
	IBOutlet SeaDocument *document;
	
	//! Whether or not the view is the first responder
	BOOL isFirst;
}

@end

