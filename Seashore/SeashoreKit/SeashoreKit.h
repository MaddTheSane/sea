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

#import "Rects.h"
#import "Constants.h"
#import "Globals.h"
#import "ColorConversion.h"
#import "SSKTerminatable.h"
#import "SSKPlugin.h"
#import "SSKVisualPlugin.h"
#import "SSKCIPlugin.h"
#import "SeaMain.h"
#import "Bitmap.h"
#import "CenteringClipView.h"
#import "ImageToolbarItem.h"
#import "IndiciesKeeper.h"
#import "RLE.h"
#import "SeaApplication.h"
#import "SeaContent.h"
#import "SeaController.h"
#import "SeaCursors.h"
#import "SeaDocumentController.h"
#import "SeaHelp.h"
#import "SeaHelpers.h"
#import "SeaLayer.h"
#import "SeaLayerUndo.h"
#import "SeaPrefs.h"
#import "SeaPrintView.h"
#import "SeaProxy.h"
#import "SeaSelection.h"
#import "SeaShadowView.h"
#import "SeaToolbarItem.h"
#import "SeaView.h"
#import "SeaWarning.h"
#import "SeaWindowContent.h"
#import "TextureExporter.h"

//Cocoa extensions:
#import "NSOutlineView_Extensions.h"
#import "NSBezierPath_Extensions.h"
