//
//  ColorSyncDeprecated.h
//  Seashore
//
//  Created by C.W. Betts on 2/13/16.
//
//	This code contains ColorSync mehtods removed from Apple's
//	headers. They are so deprecated.

#ifndef ColorSyncDeprecated_h
#define ColorSyncDeprecated_h

#include <ApplicationServices/ApplicationServices.h>

#pragma mark Accessing Profiles

CMError CMOpenProfile(CMProfileRef *prof, const CMProfileLocation *theProfile) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;
CMError CMValidateProfile(CMProfileRef prof, Boolean *valid, Boolean *preferredCMMnotfound) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;
CMError CMCloseProfile(CMProfileRef prof) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;
CMError CMUpdateProfile(CMProfileRef prof) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;
CMError CMCopyProfile(CMProfileRef *targetProf, const CMProfileLocation *targetLocation, CMProfileRef srcProf) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;
CMError CMProfileModified(CMProfileRef prof, Boolean *modified) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;
CMError CMGetProfileMD5 ( CMProfileRef prof, CMProfileMD5 digest ) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;
CMError CMGetProfileHeader ( CMProfileRef prof, CMAppleProfileHeader *header ) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;
CMError CMSetProfileHeader ( CMProfileRef prof, const CMAppleProfileHeader *header ) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;
CMError CMGetProfileLocation ( CMProfileRef prof, CMProfileLocation *location ) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;
CMError NCMGetProfileLocation ( CMProfileRef prof, CMProfileLocation *theProfile, UInt32 *locationSize ) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;
CMError CMCloneProfileRef ( CMProfileRef prof ) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;
CMError CMGetProfileRefCount ( CMProfileRef prof, long *count ) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;
CMError CMFlattenProfile(CMProfileRef prof, UInt32 flags, CMFlattenUPP proc, void *refCon, Boolean *preferredCMMnotfound) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;
CMError NCMUnflattenProfile(CMProfileLocation *targetLocation, CMFlattenUPP proc, void *refCon, Boolean *preferredCMMnotfound) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;

#pragma mark Iterating Installed Profiles

CMError CMIterateColorSyncFolder (CMProfileIterateUPP proc, UInt32 *seed, UInt32 *count, void *refCon) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;
#if !__LP64__
CMError CMGetColorSyncFolderSpec(short vRefNum, Boolean createFolder, short *foundVRefNum, long *foundDirID) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;
#endif

#pragma mark Creating Profiles

CMError CMNewProfile(CMProfileRef *prof, const CMProfileLocation *theProfile) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;
CMError CWNewLinkProfile(CMProfileRef *prof, const CMProfileLocation *targetLocation, CMConcatProfileSet *profileSet) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;
CMError NCWNewLinkProfile(CMProfileRef *prof, const CMProfileLocation *targetLocation, NCMConcatProfileSet *profileSet, CMConcatCallBackUPP proc, void *refCon) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;
CMError CMMakeProfile(CMProfileRef prof, CFDictionaryRef spec) __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_3, __MAC_10_6, __IPHONE_NA, __IPHONE_NA);

#pragma mark Accessing Special Profiles

CMError CMGetSystemProfile(CMProfileRef *prof) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;
#if !__LP64__
CMError CMSetSystemProfile(const FSSpec *profileFileSpec) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;
CMError NCMSetSystemProfile(const CMProfileLocation *profLoc) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;
#endif
CMError CMGetDefaultProfileBySpace(OSType dataColorSpace, CMProfileRef *prof) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;

#if !__LP64__
CMError CMSetDefaultProfileBySpace(OSType dataColorSpace, CMProfileRef prof) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;
#endif

CMError CMGetDefaultProfileByUse(OSType use, CMProfileRef *prof) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;

#if !__LP64__
CMError CMSetDefaultProfileByUse(OSType use, CMProfileRef prof) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;
#endif

CMError CMGetProfileByAVID(CMDisplayIDType theID, CMProfileRef *prof) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;
CMError CMSetProfileByAVID(CMDisplayIDType theID, CMProfileRef prof) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;

#pragma mark Working With ColorWorlds

CMError NCWNewColorWorld(CMWorldRef *cw, CMProfileRef src, CMProfileRef dst) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;
CMError CWConcatColorWorld(CMWorldRef *cw, CMConcatProfileSet *profileSet) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;
CMError NCWConcatColorWorld(CMWorldRef *cw, NCMConcatProfileSet *profileSet, CMConcatCallBackUPP proc, void *refCon) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;
#if !__LP64__
CMError CMGetCWInfo(CMWorldRef cw, CMCWInfoRecord *info) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;
#endif
void CWDisposeColorWorld(CMWorldRef cw) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;
CMError CWMatchColors(CMWorldRef cw, CMColor *myColors, size_t count) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;
CMError CWCheckColors(CMWorldRef cw, CMColor *myColors, size_t count, UInt8 *result) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;
CMError CWMatchBitmap(CMWorldRef cw, CMBitmap *bitmap, CMBitmapCallBackUPP progressProc, void *refCon, CMBitmap *matchedBitmap) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;
CMError CWCheckBitmap(CMWorldRef cw, const CMBitmap *bitmap, CMBitmapCallBackUPP progressProc, void *refCon, CMBitmap *resultBitmap) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;
CMError CWFillLookupTexture(CMWorldRef cw, UInt32 gridPoints, UInt32 format, UInt32 dataSize, void *data) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;

#pragma mark Accessing Default Devices

CMError CMGetDefaultDevice(CMDeviceClass deviceClass, CMDeviceID *deviceID) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;
CMError CMSetDefaultDevice(CMDeviceClass deviceClass, CMDeviceID deviceID) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;

#pragma mark Accessing Devices Profiles

CMError CMGetDeviceFactoryProfiles(CMDeviceClass deviceClass, CMDeviceID deviceID, CMDeviceProfileID *defaultProfID, UInt32 *arraySize, CMDeviceProfileArray *deviceProfiles) AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_6;
CMError CMSetDeviceFactoryProfiles(CMDeviceClass deviceClass, CMDeviceID deviceID, CMDeviceProfileID defaultProfID, const CMDeviceProfileArray *deviceProfiles) AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_6;
#if !__LP64__
CMError CMGetDeviceProfiles(CMDeviceClass deviceClass, CMDeviceID deviceID, UInt32 *arraySize, CMDeviceProfileArray *deviceProfiles) AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_6;
#endif
CMError CMSetDeviceProfiles(CMDeviceClass deviceClass, CMDeviceID deviceID, const CMDeviceProfileScope *profileScope, const CMDeviceProfileArray *deviceProfiles) AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_6;
CMError CMGetDeviceDefaultProfileID(CMDeviceClass deviceClass, CMDeviceID deviceID, CMDeviceProfileID *defaultProfID) AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_6;
CMError CMSetDeviceDefaultProfileID(CMDeviceClass deviceClass, CMDeviceID deviceID, CMDeviceProfileID defaultProfID) AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_6;
CMError CMSetDeviceProfile(CMDeviceClass deviceClass, CMDeviceID deviceID, const CMDeviceProfileScope *profileScope, CMDeviceProfileID profileID, const CMProfileLocation *profileLoc) AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_6;
CMError CMGetDeviceDefaultProfileID(CMDeviceClass deviceClass, CMDeviceID deviceID, CMDeviceProfileID *defaultProfID) AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_6;
CMError CMSetDeviceDefaultProfileID(CMDeviceClass deviceClass, CMDeviceID deviceID, CMDeviceProfileID defaultProfID) AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_6;
CMError CMSetDeviceProfile(CMDeviceClass deviceClass, CMDeviceID deviceID, const CMDeviceProfileScope *profileScope, CMDeviceProfileID profileID, const CMProfileLocation *profileLoc) AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_6;
CMError CMGetDeviceProfile(CMDeviceClass deviceClass, CMDeviceID deviceID, CMDeviceProfileID profileID, CMProfileLocation *profileLoc) AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_6;


#endif /* ColorSyncDeprecated_h */
