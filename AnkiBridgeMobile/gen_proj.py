#!/usr/bin/env python3
"""Generates AnkiBridgeMobile.xcodeproj/project.pbxproj for iOS."""

import hashlib
import os

# ── Configuration ──────────────────────────────────────────────────────────────

APP_NAME     = "AnkiBridgeMobile"
BUNDLE_ID    = "com.ankibridge.mobile"
DEPLOY_TARGET = "17.0"
SWIFT_VERSION = "5.0"

SOURCES = [
    "AnkiBridgeMobileApp.swift",
    "ContentView.swift",
    "AppState.swift",
    "AppSettings.swift",
    "Models.swift",
    "OpenAIClient.swift",
    "AnkiConnectClient.swift",
    "CardParser.swift",
    "ChatView.swift",
    "CardsView.swift",
    "DecksView.swift",
    "SettingsView.swift",
]

RESOURCES = [
    "Assets.xcassets",
    "Info.plist",
]

# ── ID generation ──────────────────────────────────────────────────────────────

def uid(tag: str) -> str:
    """Stable 24-hex-char ID derived from tag."""
    return hashlib.sha1(tag.encode()).hexdigest()[:24].upper()

# Stable IDs
FILE_REF     = {s: uid(f"ref_{s}") for s in SOURCES + RESOURCES}
BUILD_FILE   = {s: uid(f"bf_{s}")  for s in SOURCES + RESOURCES}

ID_PROJECT      = uid("project")
ID_TARGET       = uid("target")
ID_SOURCES_PH   = uid("phase_sources")
ID_RESOURCES_PH = uid("phase_resources")
ID_FWKS_PH      = uid("phase_frameworks")
ID_GROUP_ROOT   = uid("group_root")
ID_GROUP_SRC    = uid("group_src")
ID_GROUP_PROD   = uid("group_products")
ID_PROD_REF     = uid("product_ref")
ID_CFG_LIST_PRJ = uid("cfglist_project")
ID_CFG_LIST_TGT = uid("cfglist_target")
ID_CFG_DBG      = uid("cfg_debug")
ID_CFG_REL      = uid("cfg_release")
ID_CFG_TGT_DBG  = uid("cfg_target_debug")
ID_CFG_TGT_REL  = uid("cfg_target_release")

# ── pbxproj sections ──────────────────────────────────────────────────────────

def build_file_refs() -> str:
    lines = []
    for name in SOURCES:
        path = f"{APP_NAME}/{name}"
        lines.append(f"\t\t{FILE_REF[name]} = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = \"<group>\"; }};")
    lines.append(f"\t\t{FILE_REF['Assets.xcassets']} = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = \"<group>\"; }};")
    lines.append(f"\t\t{FILE_REF['Info.plist']} = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = \"<group>\"; }};")
    lines.append(f"\t\t{ID_PROD_REF} = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {APP_NAME}.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
    return "\n".join(lines)

def build_build_files() -> str:
    lines = []
    for name in SOURCES:
        lines.append(f"\t\t{BUILD_FILE[name]} = {{isa = PBXBuildFile; fileRef = {FILE_REF[name]}; }};")
    for name in ["Assets.xcassets", "Info.plist"]:
        lines.append(f"\t\t{BUILD_FILE[name]} = {{isa = PBXBuildFile; fileRef = {FILE_REF[name]}; }};")
    return "\n".join(lines)

def sources_list() -> str:
    return "\n".join(f"\t\t\t\t{BUILD_FILE[s]}," for s in SOURCES)

def resources_list() -> str:
    return "\n".join(f"\t\t\t\t{BUILD_FILE[r]}," for r in RESOURCES)

def group_src_children() -> str:
    all_items = SOURCES + ["Assets.xcassets", "Info.plist"]
    return "\n".join(f"\t\t\t\t{FILE_REF[i]}," for i in all_items)

def build_settings_shared() -> str:
    return f"""\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tINFOPLIST_FILE = {APP_NAME}/Info.plist;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = {DEPLOY_TARGET};
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = {BUNDLE_ID};
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
\t\t\t\tSWIFT_VERSION = {SWIFT_VERSION};
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";"""

def pbxproj() -> str:
    return f"""// !$*UTF8*$!
{{
\tarchiveVersion = 1;
\tclasses = {{
\t}};
\tobjectVersion = 56;
\tobjects = {{

/* Begin PBXBuildFile section */
{build_build_files()}
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
{build_file_refs()}
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
\t\t{ID_FWKS_PH} = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
\t\t{ID_GROUP_ROOT} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{ID_GROUP_SRC},
\t\t\t\t{ID_GROUP_PROD},
\t\t\t);
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{ID_GROUP_SRC} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{group_src_children()}
\t\t\t);
\t\t\tpath = {APP_NAME};
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{ID_GROUP_PROD} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{ID_PROD_REF},
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = "<group>";
\t\t}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\t{ID_TARGET} = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {ID_CFG_LIST_TGT};
\t\t\tbuildPhases = (
\t\t\t\t{ID_SOURCES_PH},
\t\t\t\t{ID_FWKS_PH},
\t\t\t\t{ID_RESOURCES_PH},
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = {APP_NAME};
\t\t\tproductName = {APP_NAME};
\t\t\tproductReference = {ID_PROD_REF};
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t{ID_PROJECT} = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastUpgradeCheck = 1600;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{ID_TARGET} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {ID_CFG_LIST_PRJ};
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t);
\t\t\tmainGroup = {ID_GROUP_ROOT};
\t\t\tproductRefGroup = {ID_GROUP_PROD};
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{ID_TARGET},
\t\t\t);
\t\t}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\t{ID_RESOURCES_PH} = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{resources_list()}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\t{ID_SOURCES_PH} = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{sources_list()}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
\t\t{ID_CFG_DBG} = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = {DEPLOY_TARGET};
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{ID_CFG_REL} = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = {DEPLOY_TARGET};
\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-O";
\t\t\t\tVALIDATE_PRODUCT = YES;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
\t\t{ID_CFG_TGT_DBG} = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
{build_settings_shared()}
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{ID_CFG_TGT_REL} = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
{build_settings_shared()}
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-O";
\t\t\t\tVALIDATE_PRODUCT = YES;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t{ID_CFG_LIST_PRJ} = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{ID_CFG_DBG},
\t\t\t\t{ID_CFG_REL},
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{ID_CFG_LIST_TGT} = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{ID_CFG_TGT_DBG},
\t\t\t\t{ID_CFG_TGT_REL},
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
/* End XCConfigurationList section */

\t}};
\trootObject = {ID_PROJECT};
}}
"""

def main():
    proj_dir = f"{APP_NAME}.xcodeproj"
    os.makedirs(proj_dir, exist_ok=True)
    out = os.path.join(proj_dir, "project.pbxproj")
    with open(out, "w") as f:
        f.write(pbxproj())
    print(f"Wrote {out}")

if __name__ == "__main__":
    main()
