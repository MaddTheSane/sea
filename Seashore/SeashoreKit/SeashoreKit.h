//
//  SeashoreKit.h
//  SeashoreKit
//
//  Created by C.W. Betts on 2/12/16.
//
//

#import <Foundation/Foundation.h>
#include <GIMPCore/GIMPCore.h>

//! Project version number for SeashoreKit.
FOUNDATION_EXPORT double SeashoreKitVersionNumber;

//! Project version string for SeashoreKit.
FOUNDATION_EXPORT const unsigned char SeashoreKitVersionString[];

#import <SeashoreKit/Constants.h>
#import <SeashoreKit/Rects.h>
#import <SeashoreKit/Globals.h>
#import <SeashoreKit/ColorConversion.h>
#import <SeashoreKit/SSKTerminatable.h>
#import <SeashoreKit/SSKPlugin.h>
#import <SeashoreKit/SSKVisualPlugin.h>
#import <SeashoreKit/SSKCIPlugin.h>
#import <SeashoreKit/SeaMain.h>
#import <SeashoreKit/Bitmap.h>
#import <SeashoreKit/CenteringClipView.h>
#import <SeashoreKit/ImageToolbarItem.h>
#import <SeashoreKit/IndiciesKeeper.h>
#import <SeashoreKit/RLE.h>
#import <SeashoreKit/SeaApplication.h>
#import <SeashoreKit/SeaContent.h>
#import <SeashoreKit/SeaController.h>
#import <SeashoreKit/SeaCursors.h>
#import <SeashoreKit/SeaDocumentController.h>
#import <SeashoreKit/SeaHelp.h>
#import <SeashoreKit/SeaHelpers.h>
#import <SeashoreKit/SeaLayer.h>
#import <SeashoreKit/SeaLayerUndo.h>
#import <SeashoreKit/SeaPrefs.h>
#import <SeashoreKit/SeaPrintView.h>
#import <SeashoreKit/SeaProxy.h>
#import <SeashoreKit/SeaSelection.h>
#import <SeashoreKit/SeaShadowView.h>
#import <SeashoreKit/SeaToolbarItem.h>
#import <SeashoreKit/SeaView.h>
#import <SeashoreKit/SeaWarning.h>
#import <SeashoreKit/SeaWindowContent.h>
#import <SeashoreKit/TextureExporter.h>
#import <SeashoreKit/Bucket.h>

#import <SeashoreKit/SeaImporter.h>
#import <SeashoreKit/CocoaContent.h>
#import <SeashoreKit/CocoaLayer.h>
#import <SeashoreKit/CocoaImporter.h>
#import <SeashoreKit/SVGContent.h>
#import <SeashoreKit/SVGLayer.h>
#import <SeashoreKit/SVGImporter.h>
#import <SeashoreKit/XBMContent.h>
#import <SeashoreKit/XBMLayer.h>
#import <SeashoreKit/XBMImporter.h>
#import <SeashoreKit/XCFContent.h>
#import <SeashoreKit/XCFLayer.h>
#import <SeashoreKit/XCFImporter.h>
#import <SeashoreKit/BrushExporter.h>

#import <SeashoreKit/SeaOperations.h>

//Cocoa extensions:
#import <SeashoreKit/NSOutlineView_Extensions.h>
#import <SeashoreKit/NSBezierPath_Extensions.h>
#import <SeashoreKit/NSArray_Extensions.h>
