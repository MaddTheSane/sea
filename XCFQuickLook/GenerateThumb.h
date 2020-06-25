//
//  GenerateThumb.h
//  XCFQuickLook
//
//  Created by C.W. Betts on 1/2/17.
//
//

#ifndef GenerateThumb_h
#define GenerateThumb_h

#include <CoreFoundation/CoreFoundation.h>
#include <QuickLook/QuickLook.h>

#ifndef __private_extern
#define __private_extern __attribute__((visibility("hidden")))
#endif

// The thumbnail generation function to be implemented in GenerateThumbnailForURL.c
__private_extern OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize);
__private_extern void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail);

// The preview generation function to be implemented in GeneratePreviewForURL.c
__private_extern OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
__private_extern void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

#endif /* GenerateThumb_h */
