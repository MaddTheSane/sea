#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#include "GenerateThumb.h"
#import <Cocoa/Cocoa.h>

#import "XCFContent.h"
#import "SeaWhiteboard.h"

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
	@autoreleasepool {
		XCFContent *contents = [[XCFContent alloc] initWithContentsOfFile: [(__bridge NSURL *)url path]];
		SeaWhiteboard *whiteboard = [[SeaWhiteboard alloc] initWithContent:contents];
		[whiteboard update];
		
		QLThumbnailRequestSetImageWithData(thumbnail,(__bridge CFDataRef)[[whiteboard printableImage] TIFFRepresentation], NULL);
		
		return noErr;
	}
}

void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail)
{
    // implement only if supported
}
