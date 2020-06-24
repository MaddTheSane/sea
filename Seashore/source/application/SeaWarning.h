#ifndef __SEASHOREKIT_SEAWARNINGS_H__
#define __SEASHOREKIT_SEAWARNINGS_H__

#import <Cocoa/Cocoa.h>
#ifdef SEASYSPLUGIN
#import "Globals.h"
#else
#import <SeashoreKit/Globals.h>
#endif

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
	//! Used for some message that is essential to the UI workflow (such as a floating layer).
	SeaWarningImportanceUI,
	//! Used when the message is of high importance (e.g. data loss upon saving).
	SeaWarningImportanceHigh,
	//! Used when the message is of moderate importance.
	SeaWarningImportanceModerate,
	/*! Used when the message is of low importance (e.g. saving is not possible because
	 the format or file is read-only).
	 */
	SeaWarningImportanceLow,
	//! Used when the message is of little importance (e.g. user advice).
	SeaWarningImportanceVeryLow,
	//! Placeholder when the importance isn't known.
	SeaWarningImportanceUnknown = -1,
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

static const SeaWarningImportance kUIImportance NS_DEPRECATED_WITH_REPLACEMENT_MAC("SeaWarningImportanceUI", 10.2, 10.8) = SeaWarningImportanceUI;
static const SeaWarningImportance kHighImportance NS_DEPRECATED_WITH_REPLACEMENT_MAC("SeaWarningImportanceHigh", 10.2, 10.8) = SeaWarningImportanceHigh;
static const SeaWarningImportance kModerateImportance NS_DEPRECATED_WITH_REPLACEMENT_MAC("SeaWarningImportanceModerate", 10.2, 10.8) = SeaWarningImportanceModerate;
static const SeaWarningImportance kLowImportance NS_DEPRECATED_WITH_REPLACEMENT_MAC("SeaWarningImportanceLow", 10.2, 10.8) = SeaWarningImportanceLow;
static const SeaWarningImportance kVeryLowImportance NS_DEPRECATED_WITH_REPLACEMENT_MAC("SeaWarningImportanceLow", 10.2, 10.8) = SeaWarningImportanceVeryLow;

#endif
