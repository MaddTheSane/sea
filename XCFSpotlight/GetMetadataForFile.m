#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h> 
#include <Cocoa/Cocoa.h>

#import "XCFContent.h"
#import "XCFLayer.h"
#import "GetMetadataForFile.h"

/* -----------------------------------------------------------------------------
 Step 1
 Set the UTI types the importer supports
 
 Modify the CFBundleDocumentTypes entry in Info.plist to contain
 an array of Uniform Type Identifiers (UTI) for the LSItemContentTypes 
 that your importer can handle
 
 ----------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
 Step 2 
 Implement the GetMetadataForFile function
 
 Implement the GetMetadataForFile function below to scrape the relevant
 metadata from your document and return it as a CFDictionary using standard keys
 (defined in MDItem.h) whenever possible.
 ----------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
 Step 3 (optional) 
 If you have defined new attributes, update the schema.xml file
 
 Edit the schema.xml file to include the metadata keys that your importer returns.
 Add them to the <allattrs> and <displayattrs> elements.
 
 Add any custom types that your importer requires to the <attributes> element
 
 <attribute name="com_mycompany_metadatakey" type="CFString" multivalued="true"/>
 
 ----------------------------------------------------------------------------- */



/* -----------------------------------------------------------------------------
 Get metadata attributes from file
 
 This function's job is to extract useful information your file format supports
 and return it as a dictionary
 ----------------------------------------------------------------------------- */

Boolean GetMetadataForFile(void* thisInterface, 
						   CFMutableDictionaryRef attributes, 
						   CFStringRef contentTypeUTI,
						   CFStringRef pathToFile)
{
    /* Pull any available metadata from the file at the specified path */
    /* Return the attribute keys and attribute values in the dict */
    /* Return TRUE if successful, FALSE if there was no data provided */
    
    /* Return the attribute keys and attribute values in the dict */
    /* Return true if successful, false if there was no data provided */
    Boolean success=NO;
	
    // Don't assume that there is an autorelease pool around the calling of this function.
	@autoreleasepool {
		NSMutableDictionary *nsAttribs = (__bridge NSMutableDictionary*)attributes;
		// load the document at the specified location
		XCFContent *contents = [[XCFContent alloc] initWithContentsOfFile: (__bridge NSString *)pathToFile];
		if (contents) {
			int width = [contents width];
			int height = [contents height];
			nsAttribs[(NSString *)kMDItemPixelWidth] = @(width);
			
			nsAttribs[(NSString *)kMDItemPixelHeight] = @(height);
			
			if (width > height) {
				nsAttribs[(NSString *)kMDItemOrientation] = @1;
			} else {
				nsAttribs[(NSString *)kMDItemOrientation] = @0;
			}
			
			
			nsAttribs[(NSString *)kMDItemBitsPerSample] = @([contents spp] * 8);
			nsAttribs[(NSString *)kMDItemResolutionWidthDPI] = @([contents xres]);
			nsAttribs[(NSString *)kMDItemResolutionHeightDPI] = @([contents yres]);
			
			if ([contents type] == XCF_RGB_IMAGE) {
				nsAttribs[(NSString *)kMDItemColorSpace] = @"RGB";
			} else if([contents type] == XCF_GRAY_IMAGE) {
				nsAttribs[(NSString *)kMDItemColorSpace] = @"Gray";
			}
			
			NSMutableArray *names = [NSMutableArray arrayWithCapacity:[contents layerCount]];
			BOOL hasAlpha = NO;
			for (XCFLayer *layer in contents.layers) {
				[names addObject:[layer name]];
				if ([layer hasAlpha]) {
					hasAlpha = YES;
				}
			}
			
			nsAttribs[(NSString *)kMDItemHasAlphaChannel] = @(hasAlpha);
			nsAttribs[(NSString *)kMDItemLayerNames] = [names copy];
			
			if ([contents exifData]) {
				NSDictionary *data = [contents exifData];
				if(data[@"FNumber"]){
					nsAttribs[(NSString *)kMDItemFNumber] = data[@"FNumber"];
				}
				
				if(data[@"ExifVersion"]){
					nsAttribs[(NSString *)kMDItemEXIFVersion] = [data[@"ExifVersion"] componentsJoinedByString:@"."];
				}
				
				if(data[@"DateTimeOriginal"]){
					nsAttribs[(NSString *)kMDItemContentCreationDate] = data[@"DateTimeOriginal"];
					
				}
			}
			
			success=YES;
		}
		
		
		return success;
	}
}
