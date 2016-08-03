#ifndef __SEASHOREKIT_SEAWARNINGS_H__
#define __SEASHOREKIT_SEAWARNINGS_H__

#import <Cocoa/Cocoa.h>
#import "Globals.h"

/*!
	@enum		k...Importance
	@constant	kUIImportance
				Used for some message that is essential to the UI workflow (such as a floating layer).
	@constant	kHighImportance
				Used when the message is of high importance (e.g. data loss upon saving).
	@constant	kModerateImportance
				Used when the message is of moderate importance.
	@constant	kLowImportance
				Used when the message is of low importance (e.g. saving is not possible because
				the format or file is read-only).
	@constant	kVeryLowImportance
				Used when the message is of little importance (e.g. user advice).
*/
typedef NS_ENUM(NSInteger, SeaWarningImportance) {
	SeaWarningImportanceUI,
	SeaWarningImportanceHigh,
	SeaWarningImportanceModerate,
	SeaWarningImportanceLow,
	SeaWarningImportanceVeryLow,
	SeaWarningImportanceUnknown = -1,
	
	kUIImportance NS_SWIFT_UNAVAILABLE("Use .UI instead") = SeaWarningImportanceUI,
	kHighImportance NS_SWIFT_UNAVAILABLE("Use .High instead") = SeaWarningImportanceHigh,
	kModerateImportance NS_SWIFT_UNAVAILABLE("Use .Moderate instead") = SeaWarningImportanceModerate,
	kLowImportance NS_SWIFT_UNAVAILABLE("Use .Low instead") = SeaWarningImportanceLow,
	kVeryLowImportance NS_SWIFT_UNAVAILABLE("Use .VeryLow instead") = SeaWarningImportanceVeryLow,
};

@class SeaDocument;

/*!
	@class		SeaWarning
	@abstract	Informs the user of various warnings.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli				
*/
@interface SeaWarning : NSObject {
	// A dictionary of the queue of all of the document messages waiting to be displayed
	NSMutableDictionary *documentQueues;
	
	// A queue for the whole app (some messages can't be displayed in document)
	NSMutableArray *appQueue;
}

/*!
	@method		addMessage:level:
	@discussion	Adds a message to the warning message queue.
	@param		message	
				The message to add.
	@param		level
				The level of importance of the message.
*/
- (void)addMessage:(NSString *)message level:(SeaWarningImportance)level;

/*!
	@method		triggerQueue:
	@discussion	Moves to the next warning message in the queue for this document
				If no warnings were able to be displayed, then display the first
	@param		key
				The queue to look in
*/
- (void)triggerQueue:(id)key;

/*!
	@method		addMessage:forDocument:level:
	@discussion	Adds a message to the warning message queue.
	@param		message
				The message to add.
	@param		document
				The queue to add this message to
	@param		level
				The level of importance of the message.
*/
- (void)addMessage:(NSString *)message forDocument:(SeaDocument*)document level:(SeaWarningImportance)level;

@end

#endif
