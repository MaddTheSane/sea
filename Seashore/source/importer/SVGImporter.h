//
//  SVGImporter.h
//  SeashoreKit
//
//  Created by C.W. Betts on 7/5/18.
//

#import <Foundation/Foundation.h>

extern NSErrorDomain _Nonnull const SVGImporterErrorsDomain;
typedef NS_ERROR_ENUM(SVGImporterErrorsDomain, SVGImporterErrors) {
	SVGImporterErrorsCouldNotFindBundle = -1,
	SVGImporterErrorsCouldNotLoadBundle = -2,
	SVGImporterErrorsCouldNotLoadSVG = -3,
	SVGImporterErrorsUnableToGenerateTIFF = -4,
	SVGImporterErrorsUnableToCreateBitmap = -5,
	SVGImporterErrorsUnableToCreateLayer = -6,
	SVGImporterErrorsCouldNotFindApp = -7,
	SVGImporterErrorsCouldNotLoadConvertedPNG = -8,
};
