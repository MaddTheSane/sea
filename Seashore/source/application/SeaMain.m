//
//  SeaMain.m
//  Seashore
//
//  Created by C.W. Betts on 2/12/16.
//
//

#import "SeaMain.h"
#import "Globals.h"
#include <sys/sysctl.h>
#import "SeaDocumentController.h"

//int randomTable[4096];
extern int globalUniqueDocID;
int tempFileCount;
int diskWarningLevel;
BOOL useAltiVec;
BOOL userWarnedOnDiskSpace;
extern BOOL globalReadOnlyWarning;

BOOL isAltiVecAvailable()
{
#ifdef __ppc__
	int selectors[2] = { CTL_HW, HW_VECTORUNIT };
	int hasVectorUnit = 0;
	size_t length = sizeof(hasVectorUnit);
	int error = sysctl(selectors, 2, &hasVectorUnit, &length, NULL, 0);
	
	if	(error == 0) return (hasVectorUnit != 0);
#elif __ppc64__
	return YES;
#endif
	return NO;
}

int SeaShoreMain(int argc, const char *argv[])
{
	userWarnedOnDiskSpace = globalReadOnlyWarning = NO;
	globalUniqueDocID = tempFileCount = 0;
	useAltiVec = isAltiVecAvailable();
	[SeaDocumentController sharedDocumentController];
	return NSApplicationMain(argc, argv);
}
