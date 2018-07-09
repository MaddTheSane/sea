//
//  SeaImporter.h
//  SeashoreKit
//
//  Created by C.W. Betts on 7/8/18.
//

#import <Foundation/Foundation.h>
#import "Globals.h"

NS_ASSUME_NONNULL_BEGIN

@class SeaDocument;

@protocol SeaImporter <NSObject>
/*!
 @method		addToDocument:contentsOfURL:error:
 @discussion	Adds the given image file to the given document.
 @param			doc
 				The document to add to.
 @param			path
 				The file URL to the image file.
 @result		\c YES if the operation was successful, \c NO otherwise.
 */
- (BOOL)addToDocument:(SeaDocument*)doc contentsOfURL:(NSURL *)path error:(NSError * _Nullable __autoreleasing *)error;

@optional
/*!
 @method		endPanel:
 @discussion	Closes the current modal dialog.
 @param			sender
 				Ignored.
 */
- (IBAction)endPanel:(nullable id)sender;

@end

NS_ASSUME_NONNULL_END
