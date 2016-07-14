#import "SeaWarning.h"
#import "SeaController.h"
#import "SeaPrefs.h"
#import "SeaWindowContent.h"
#import "SeaDocument.h"
#import "WarningsUtility.h"

@implementation SeaWarning

- (instancetype)init
{
	self = [super init];
	if(self){
		documentQueues = [NSMutableDictionary dictionary];
		appQueue = [NSMutableArray array];
	}
	return self;
}


- (void)addMessage:(NSString *)message level:(int)level
{
	[appQueue addObject: @{@"message": message, @"importance": @(level)}];
	[self triggerQueue: NULL];
}

- (void)triggerQueue:(id)key
{
	NSMutableArray* queue;
	if(!key){
		queue = appQueue;
	}else{
		queue = documentQueues[@((long)key)];
	}
	// First check to see if we have any messages
	if(queue && [queue count] > 0){
		// This is the app modal queue
		if(!key){
			while([queue count] > 0){
				NSDictionary *thisWarning = queue[0];
				if([thisWarning[@"importance"] intValue] <= [[SeaController seaPrefs] warningLevel]){
					NSRunAlertPanel(NULL, @"%@", NULL, NULL, NULL, thisWarning[@"message"]);
				}
				[queue removeObjectAtIndex:0];
			}
		}else {
			// First we need to see if the app has a warning object that
			// is ready to be used (at init it's not all hooked up)
			if([(SeaDocument *)key warnings] && [[key warnings] activeWarningImportance] == -1){
				// Next, pop the object out of the queue and pass to the warnings
				NSDictionary *thisWarning = queue[0];
				[[key warnings] setWarning: thisWarning[@"message"] ofImportance: [thisWarning[@"importance"] intValue]];
				 [queue removeObjectAtIndex:0];
			}
		}
	}
}

- (void)addMessage:(NSString *)message forDocument:(id)document level:(int)level
{	
	NSMutableArray* thisDocQueue = documentQueues[@((long)document)];
	if(!thisDocQueue){
		thisDocQueue = [NSMutableArray array];
		documentQueues[@((long)document)] = thisDocQueue;
	}
	[thisDocQueue addObject: @{@"message": message, @"importance": @(level)}];
	[self triggerQueue: document];
}

@end
