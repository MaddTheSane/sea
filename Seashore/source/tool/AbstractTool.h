#import <Cocoa/Cocoa.h>
#import "Globals.h"
#import "SeaTools.h"

@class SeaDocument;
@class AbstractOptions;

NS_ASSUME_NONNULL_BEGIN

/*!
	@class		AbstractTool
	@abstract	Acts as a base class for all tools.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/
@interface AbstractTool : NSObject {

	// The document associated with this tool
	IBOutlet SeaDocument *document;
	
	// The options associated with this tool
	__unsafe_unretained __kindof AbstractOptions *options;
	
	// Is the selection being made
	BOOL intermediate;
	
}

/// The options associated with this tool
@property (unsafe_unretained) __kindof AbstractOptions *options;

/*!
	@property	toolId
	@discussion	For determining the type of a tool based on the object.
				This method must be defined by subclasses.
	@result		Returns an element of the k...Tool enum
*/
@property (readonly) SeaToolsDefines toolId;

/*!
	@method		setOptions:
	@discussion	Sets the options for this tool.
	@param		newOptions
				The options to set.
*/
- (void)setOptions:(__kindof AbstractOptions*)newOptions;

/*!
	@property	acceptsLineDraws
	@discussion	Returns whether or not this tool wants to allow line draws.
	@result		Returns YES if the tool does want to allow line draws, NO
				otherwise. The implementation in this class always returns NO.
*/
@property (readonly) BOOL acceptsLineDraws;

/*!
	@property	useMouseCoalescing
	@discussion	Returns whether or not this tool should use mouse coalescing.
	@result		Returns YES if this tool should use mouse coalescing, NO
				otherwise. The implementation in this class always returns YES.
*/
@property (readonly) BOOL useMouseCoalescing;

/*!
	@property	foregroundIsTexture
	@discussion	Returns whether the foreground colour should is the active
				texture.
	@result		Returns YES if the foreground colour is the active texture, NO
				otherwise. The implementation in this class always returns NO.
*/
@property (readonly) BOOL foregroundIsTexture;

/*!
	@method		mouseDownAt:withEvent:
	@discussion	Handles mouse down events.
	@param		where
				Where in the document the mouse down event occurred (in terms of
				the document's pixels).
	@param		event
				The mouse down event.
*/
- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event;

/*!
	@method		mouseDraggedTo:withEvent:
	@discussion	Handles mouse dragging events.
	@param		where
				Where in the document the mouse down event occurred (in terms of
				the document's pixels).
	@param		event
				The mouse dragged event.
*/
- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event;

/*!
	@method		mouseUpAt:withEvent:
	@discussion	Handles mouse up events.
	@param		where
				Where in the document the mouse up event occurred (in terms of
				the document's pixels).
	@param		event
				The mouse up event.
*/
- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event;

/*!
	@method		fineMouseDownAt:withEvent:
	@discussion	Handles mouse down events.
	@param		where
				Where in the document the mouse down event occurred (in terms of
				the document's pixels).
	@param		event
				The mouse down event.
*/
- (void)fineMouseDownAt:(NSPoint)where withEvent:(NSEvent *)event;

/*!
	@method		fineMouseDraggedTo:withEvent:
	@discussion	Handles mouse dragging events.
	@param		where
				Where in the document the mouse down event occurred (in terms of
				the document's pixels).
	@param		event
				The mouse dragged event.
*/
- (void)fineMouseDraggedTo:(NSPoint)where withEvent:(NSEvent *)event;

/*!
	@method		fineMouseUpAt:withEvent:
	@discussion	Handles mouse up events.
	@param		where
				Where in the document the mouse up event occurred (in terms of
				the document's pixels).
	@param		event
				The mouse up event.
*/
- (void)fineMouseUpAt:(NSPoint)where withEvent:(NSEvent *)event;

/*!
	 @property		intermediate
	 @discussion	This is used to detect if there is currently a mouse drag
	 @result		Returns a BOOL: YES if there is currently an action being made.
*/
@property (readonly) BOOL intermediate;

/*!
	@property	fineTool
	@discussion	Returns whether the tool needs an NSPoint input as opposed to an IntPoint
				input (i.e. whether fineMouse... or mouse... should be called).
	@result		Returns YES if the tool needs an NSPoint input as opposed to an IntPoint
				input, NO otherwise. The implementation in this class always returns NO.
*/
@property (readonly, getter=isFineTool) BOOL fineTool;

@end

NS_ASSUME_NONNULL_END
