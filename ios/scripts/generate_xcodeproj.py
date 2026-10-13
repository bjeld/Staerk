#!/usr/bin/env python3
"""Generate a Xcode 15-compatible .xcodeproj for Staerk (no XcodeGen required)."""

from __future__ import annotations

import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "Staerk"
TESTS = ROOT / "StaerkTests"
PROJ = ROOT / "Staerk.xcodeproj"


def uid(name: str) -> str:
    digest = hashlib.sha1(f"staerk-{name}".encode()).hexdigest().upper()
    return digest[:24]


def pbx_path(path: Path) -> str:
    return str(path.relative_to(ROOT)).replace("\\", "/")


def main() -> None:
    swift_files = sorted(APP.rglob("*.swift"))
    test_files = sorted(TESTS.rglob("*.swift")) if TESTS.exists() else []
    resource_files = [
        APP / "Assets.xcassets",
        APP / "PrivacyInfo.xcprivacy",
        APP / "Localizable.xcstrings",
        APP / "InfoPlist.xcstrings",
    ]
    plist = APP / "Info.plist"
    entitlements = APP / "Staerk.entitlements"

    file_refs: dict[str, tuple[str, str, str]] = {}

    def add_ref(path: Path, file_type: str) -> str:
        key = pbx_path(path)
        ident = uid(f"ref:{key}")
        file_refs[key] = (ident, path.name, file_type)
        return ident

    for path in swift_files + test_files:
        add_ref(path, "sourcecode.swift")
    add_ref(APP / "Assets.xcassets", "folder.assetcatalog")
    add_ref(APP / "PrivacyInfo.xcprivacy", "text.xml")
    add_ref(APP / "Localizable.xcstrings", "text.json.xcstrings")
    add_ref(APP / "InfoPlist.xcstrings", "text.json.xcstrings")
    add_ref(plist, "text.plist.xml")
    add_ref(entitlements, "text.plist.entitlements")

    frameworks = {
        "HealthKit.framework": ("wrapper.framework", "System/Library/Frameworks/HealthKit.framework"),
        "XCTest.framework": ("wrapper.framework", "System/Library/Frameworks/XCTest.framework"),
    }
    fw_ids = {}
    for name, (ftype, path) in frameworks.items():
        ident = uid(f"fw:{name}")
        fw_ids[name] = ident
        file_refs[name] = (ident, name, ftype)

    source_build = []
    resource_build = []
    framework_build = []
    test_source_build = []
    test_framework_build = []
    build_file_entries = []

    for path in swift_files:
        key = pbx_path(path)
        ref_id = file_refs[key][0]
        bid = uid(f"build:{key}")
        source_build.append(bid)
        build_file_entries.append((bid, ref_id, path.name, "app"))

    for path in test_files:
        key = pbx_path(path)
        ref_id = file_refs[key][0]
        bid = uid(f"build:{key}")
        test_source_build.append(bid)
        build_file_entries.append((bid, ref_id, path.name, "test"))

    for path in resource_files:
        if not path.exists():
            continue
        key = pbx_path(path)
        ref_id = file_refs[key][0]
        bid = uid(f"build:{key}")
        resource_build.append(bid)
        build_file_entries.append((bid, ref_id, path.name, "resource"))

    for name in ["HealthKit.framework"]:
        ref_id = fw_ids[name]
        bid = uid(f"buildfw:{name}")
        framework_build.append(bid)
        build_file_entries.append((bid, ref_id, name, "fw"))

    for name in ["XCTest.framework"]:
        ref_id = fw_ids[name]
        bid = uid(f"buildfw:{name}")
        test_framework_build.append(bid)
        build_file_entries.append((bid, ref_id, name, "testfw"))

    group_ids = {
        "": uid("group:root"),
        "Staerk": uid("group:Staerk"),
        "StaerkTests": uid("group:StaerkTests"),
        "Products": uid("group:Products"),
        "Frameworks": uid("group:Frameworks"),
    }

    folders: set[str] = set()
    for path in swift_files:
        rel = path.relative_to(APP)
        parent = str(rel.parent)
        while parent not in (".", ""):
            folders.add(parent)
            parent = str(Path(parent).parent)
    for folder in sorted(folders):
        group_ids[folder] = uid(f"group:{folder}")

    product_ref = uid("product:Staerk.app")
    test_product_ref = uid("product:StaerkTests.xctest")
    target_id = uid("target:Staerk")
    test_target_id = uid("target:StaerkTests")
    project_id = uid("project:Staerk")
    sources_phase = uid("phase:sources")
    resources_phase = uid("phase:resources")
    frameworks_phase = uid("phase:frameworks")
    test_sources_phase = uid("phase:testsources")
    test_frameworks_phase = uid("phase:testframeworks")
    target_config_list = uid("cfglist:target")
    test_config_list = uid("cfglist:testtarget")
    project_config_list = uid("cfglist:project")
    target_debug = uid("cfg:target:debug")
    target_release = uid("cfg:target:release")
    test_debug = uid("cfg:test:debug")
    test_release = uid("cfg:test:release")
    project_debug = uid("cfg:project:debug")
    project_release = uid("cfg:project:release")
    dep_id = uid("dep:tests-on-app")
    proxy_id = uid("proxy:app")

    lines: list[str] = []
    w = lines.append
    w("// !$*UTF8*$!")
    w("{")
    w("\tarchiveVersion = 1;")
    w("\tclasses = {")
    w("\t};")
    w("\tobjectVersion = 56;")
    w("\tobjects = {")
    w("")

    w("/* Begin PBXBuildFile section */")
    for bid, ref_id, name, _kind in build_file_entries:
        extra = ""
        if name.endswith(".framework"):
            extra = " settings = {ATTRIBUTES = (Required, ); };"
        w(f"\t\t{bid} /* {name} in Build */ = {{isa = PBXBuildFile; fileRef = {ref_id} /* {name} */;{extra} }};")
    w("/* End PBXBuildFile section */")
    w("")

    w("/* Begin PBXContainerItemProxy section */")
    w(f"\t\t{proxy_id} /* PBXContainerItemProxy */ = {{")
    w("\t\t\tisa = PBXContainerItemProxy;")
    w(f"\t\t\tcontainerPortal = {project_id} /* Project object */;")
    w("\t\t\tproxyType = 1;")
    w(f"\t\t\tremoteGlobalIDString = {target_id};")
    w('\t\t\tremoteInfo = Staerk;')
    w("\t\t};")
    w("/* End PBXContainerItemProxy section */")
    w("")

    w("/* Begin PBXFileReference section */")
    w(
        f"\t\t{product_ref} /* Staerk.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Staerk.app; sourceTree = BUILT_PRODUCTS_DIR; }};"
    )
    w(
        f"\t\t{test_product_ref} /* StaerkTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = StaerkTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};"
    )
    for key, (ident, name, ftype) in file_refs.items():
        if key.endswith(".framework"):
            path = frameworks[key][1]
            w(
                f"\t\t{ident} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = {ftype}; name = {name}; path = {path}; sourceTree = SDKROOT; }};"
            )
        else:
            w(
                f"\t\t{ident} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = {ftype}; path = {name}; sourceTree = \"<group>\"; }};"
            )
    w("/* End PBXFileReference section */")
    w("")

    def children_for(folder: str) -> list[tuple[str, str]]:
        kids: list[tuple[str, str]] = []
        if folder == "":
            kids.append((group_ids["Staerk"], "Staerk"))
            kids.append((group_ids["StaerkTests"], "StaerkTests"))
            kids.append((group_ids["Products"], "Products"))
            kids.append((group_ids["Frameworks"], "Frameworks"))
            return kids
        if folder == "Products":
            kids.append((product_ref, "Staerk.app"))
            kids.append((test_product_ref, "StaerkTests.xctest"))
            return kids
        if folder == "Frameworks":
            for name, ident in fw_ids.items():
                kids.append((ident, name))
            return kids
        if folder == "StaerkTests":
            for path in test_files:
                key = pbx_path(path)
                kids.append((file_refs[key][0], path.name))
            return kids

        base = APP if folder == "Staerk" else APP / folder
        immediate_dirs: set[Path] = set()
        for path in swift_files:
            try:
                rel = path.relative_to(base)
            except ValueError:
                continue
            if len(rel.parts) > 1:
                immediate_dirs.add(base / rel.parts[0])
        for d in sorted(immediate_dirs):
            rel = str(d.relative_to(APP))
            kids.append((group_ids[rel], d.name))

        extra_names = {
            "Info.plist",
            "Staerk.entitlements",
            "PrivacyInfo.xcprivacy",
            "Assets.xcassets",
            "Localizable.xcstrings",
            "InfoPlist.xcstrings",
        }
        for path in sorted(base.iterdir() if base.exists() else []):
            if path.name == ".DS_Store":
                continue
            if path.suffix == ".swift":
                key = pbx_path(path)
                kids.append((file_refs[key][0], path.name))
            elif path.name in extra_names:
                key = pbx_path(path)
                kids.append((file_refs[key][0], path.name))
        return kids

    w("/* Begin PBXFrameworksBuildPhase section */")
    w(f"\t\t{frameworks_phase} /* Frameworks */ = {{")
    w("\t\t\tisa = PBXFrameworksBuildPhase;")
    w("\t\t\tbuildActionMask = 2147483647;")
    w("\t\t\tfiles = (")
    for bid in framework_build:
        w(f"\t\t\t\t{bid} /* Framework */,")
    w("\t\t\t);")
    w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    w("\t\t};")
    w(f"\t\t{test_frameworks_phase} /* Frameworks */ = {{")
    w("\t\t\tisa = PBXFrameworksBuildPhase;")
    w("\t\t\tbuildActionMask = 2147483647;")
    w("\t\t\tfiles = (")
    for bid in test_framework_build:
        w(f"\t\t\t\t{bid} /* Framework */,")
    w("\t\t\t);")
    w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    w("\t\t};")
    w("/* End PBXFrameworksBuildPhase section */")
    w("")

    w("/* Begin PBXGroup section */")
    w(f"\t\t{group_ids['']} = {{")
    w("\t\t\tisa = PBXGroup;")
    w("\t\t\tchildren = (")
    for ident, name in children_for(""):
        w(f"\t\t\t\t{ident} /* {name} */,")
    w("\t\t\t);")
    w("\t\t\tsourceTree = \"<group>\";")
    w("\t\t};")

    w(f"\t\t{group_ids['Products']} /* Products */ = {{")
    w("\t\t\tisa = PBXGroup;")
    w("\t\t\tchildren = (")
    w(f"\t\t\t\t{product_ref} /* Staerk.app */,")
    w(f"\t\t\t\t{test_product_ref} /* StaerkTests.xctest */,")
    w("\t\t\t);")
    w("\t\t\tname = Products;")
    w("\t\t\tsourceTree = \"<group>\";")
    w("\t\t};")

    w(f"\t\t{group_ids['Frameworks']} /* Frameworks */ = {{")
    w("\t\t\tisa = PBXGroup;")
    w("\t\t\tchildren = (")
    for name, ident in fw_ids.items():
        w(f"\t\t\t\t{ident} /* {name} */,")
    w("\t\t\t);")
    w("\t\t\tname = Frameworks;")
    w("\t\t\tsourceTree = \"<group>\";")
    w("\t\t};")

    w(f"\t\t{group_ids['Staerk']} /* Staerk */ = {{")
    w("\t\t\tisa = PBXGroup;")
    w("\t\t\tchildren = (")
    for ident, name in children_for("Staerk"):
        w(f"\t\t\t\t{ident} /* {name} */,")
    w("\t\t\t);")
    w("\t\t\tpath = Staerk;")
    w("\t\t\tsourceTree = \"<group>\";")
    w("\t\t};")

    w(f"\t\t{group_ids['StaerkTests']} /* StaerkTests */ = {{")
    w("\t\t\tisa = PBXGroup;")
    w("\t\t\tchildren = (")
    for ident, name in children_for("StaerkTests"):
        w(f"\t\t\t\t{ident} /* {name} */,")
    w("\t\t\t);")
    w("\t\t\tpath = StaerkTests;")
    w("\t\t\tsourceTree = \"<group>\";")
    w("\t\t};")

    for folder in sorted(folders):
        ident = group_ids[folder]
        w(f"\t\t{ident} /* {Path(folder).name} */ = {{")
        w("\t\t\tisa = PBXGroup;")
        w("\t\t\tchildren = (")
        for cid, name in children_for(folder):
            w(f"\t\t\t\t{cid} /* {name} */,")
        w("\t\t\t);")
        w(f"\t\t\tpath = {Path(folder).name};")
        w("\t\t\tsourceTree = \"<group>\";")
        w("\t\t};")
    w("/* End PBXGroup section */")
    w("")

    w("/* Begin PBXNativeTarget section */")
    w(f"\t\t{target_id} /* Staerk */ = {{")
    w("\t\t\tisa = PBXNativeTarget;")
    w(f"\t\t\tbuildConfigurationList = {target_config_list} /* Build configuration list for PBXNativeTarget \"Staerk\" */;")
    w("\t\t\tbuildPhases = (")
    w(f"\t\t\t\t{sources_phase} /* Sources */,")
    w(f"\t\t\t\t{frameworks_phase} /* Frameworks */,")
    w(f"\t\t\t\t{resources_phase} /* Resources */,")
    w("\t\t\t);")
    w("\t\t\tbuildRules = (")
    w("\t\t\t);")
    w("\t\t\tdependencies = (")
    w("\t\t\t);")
    w("\t\t\tname = Staerk;")
    w("\t\t\tproductName = Staerk;")
    w(f"\t\t\tproductReference = {product_ref} /* Staerk.app */;")
    w("\t\t\tproductType = \"com.apple.product-type.application\";")
    w("\t\t};")
    w(f"\t\t{test_target_id} /* StaerkTests */ = {{")
    w("\t\t\tisa = PBXNativeTarget;")
    w(f"\t\t\tbuildConfigurationList = {test_config_list} /* Build configuration list for PBXNativeTarget \"StaerkTests\" */;")
    w("\t\t\tbuildPhases = (")
    w(f"\t\t\t\t{test_sources_phase} /* Sources */,")
    w(f"\t\t\t\t{test_frameworks_phase} /* Frameworks */,")
    w("\t\t\t);")
    w("\t\t\tbuildRules = (")
    w("\t\t\t);")
    w("\t\t\tdependencies = (")
    w(f"\t\t\t\t{dep_id} /* PBXTargetDependency */,")
    w("\t\t\t);")
    w("\t\t\tname = StaerkTests;")
    w("\t\t\tproductName = StaerkTests;")
    w(f"\t\t\tproductReference = {test_product_ref} /* StaerkTests.xctest */;")
    w("\t\t\tproductType = \"com.apple.product-type.bundle.unit-test\";")
    w("\t\t};")
    w("/* End PBXNativeTarget section */")
    w("")

    w("/* Begin PBXProject section */")
    w(f"\t\t{project_id} /* Project object */ = {{")
    w("\t\t\tisa = PBXProject;")
    w("\t\t\tattributes = {")
    w("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
    w("\t\t\t\tLastSwiftUpdateCheck = 1500;")
    w("\t\t\t\tLastUpgradeCheck = 1500;")
    w("\t\t\t\tTargetAttributes = {")
    w(f"\t\t\t\t\t{target_id} = {{")
    w("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
    w("\t\t\t\t\t};")
    w(f"\t\t\t\t\t{test_target_id} = {{")
    w("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
    w("\t\t\t\t\t\tTestTargetID = " + target_id + ";")
    w("\t\t\t\t\t};")
    w("\t\t\t\t};")
    w("\t\t\t};")
    w(f"\t\t\tbuildConfigurationList = {project_config_list} /* Build configuration list for PBXProject \"Staerk\" */;")
    w("\t\t\tcompatibilityVersion = \"Xcode 14.0\";")
    w("\t\t\tdevelopmentRegion = da;")
    w("\t\t\thasScannedForEncodings = 0;")
    w("\t\t\tknownRegions = (")
    w("\t\t\t\tda,")
    w("\t\t\t\ten,")
    w("\t\t\t\tBase,")
    w("\t\t\t);")
    w(f"\t\t\tmainGroup = {group_ids['']};")
    w(f"\t\t\tproductRefGroup = {group_ids['Products']} /* Products */;")
    w("\t\t\tprojectDirPath = \"\";")
    w("\t\t\tprojectRoot = \"\";")
    w("\t\t\ttargets = (")
    w(f"\t\t\t\t{target_id} /* Staerk */,")
    w(f"\t\t\t\t{test_target_id} /* StaerkTests */,")
    w("\t\t\t);")
    w("\t\t};")
    w("/* End PBXProject section */")
    w("")

    w("/* Begin PBXResourcesBuildPhase section */")
    w(f"\t\t{resources_phase} /* Resources */ = {{")
    w("\t\t\tisa = PBXResourcesBuildPhase;")
    w("\t\t\tbuildActionMask = 2147483647;")
    w("\t\t\tfiles = (")
    for bid in resource_build:
        w(f"\t\t\t\t{bid} /* Resource */,")
    w("\t\t\t);")
    w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    w("\t\t};")
    w("/* End PBXResourcesBuildPhase section */")
    w("")

    w("/* Begin PBXSourcesBuildPhase section */")
    w(f"\t\t{sources_phase} /* Sources */ = {{")
    w("\t\t\tisa = PBXSourcesBuildPhase;")
    w("\t\t\tbuildActionMask = 2147483647;")
    w("\t\t\tfiles = (")
    for bid, _, name, kind in build_file_entries:
        if kind == "app" and name.endswith(".swift"):
            w(f"\t\t\t\t{bid} /* {name} in Sources */,")
    w("\t\t\t);")
    w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    w("\t\t};")
    w(f"\t\t{test_sources_phase} /* Sources */ = {{")
    w("\t\t\tisa = PBXSourcesBuildPhase;")
    w("\t\t\tbuildActionMask = 2147483647;")
    w("\t\t\tfiles = (")
    for bid, _, name, kind in build_file_entries:
        if kind == "test" and name.endswith(".swift"):
            w(f"\t\t\t\t{bid} /* {name} in Sources */,")
    w("\t\t\t);")
    w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    w("\t\t};")
    w("/* End PBXSourcesBuildPhase section */")
    w("")

    w("/* Begin PBXTargetDependency section */")
    w(f"\t\t{dep_id} /* PBXTargetDependency */ = {{")
    w("\t\t\tisa = PBXTargetDependency;")
    w(f"\t\t\ttarget = {target_id} /* Staerk */;")
    w(f"\t\t\ttargetProxy = {proxy_id} /* PBXContainerItemProxy */;")
    w("\t\t};")
    w("/* End PBXTargetDependency section */")
    w("")

    common_target = """
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_ENTITLEMENTS = Staerk/Staerk.entitlements;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 2;
				DEVELOPMENT_TEAM = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = Staerk/Info.plist;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 2.0.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.bjeld.apps.staerk;
				PRODUCT_NAME = Staerk;
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO;
				SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD = NO;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_STRICT_CONCURRENCY = targeted;
				SWIFT_VERSION = 5.9;
				TARGETED_DEVICE_FAMILY = 1;
"""

    common_test = """
				BUNDLE_LOADER = "$(TEST_HOST)";
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 2;
				DEVELOPMENT_TEAM = "";
				GENERATE_INFOPLIST_FILE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
					"@loader_path/Frameworks",
				);
				MARKETING_VERSION = 2.0.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.bjeld.apps.staerk.tests;
				PRODUCT_NAME = StaerkTests;
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SWIFT_EMIT_LOC_STRINGS = NO;
				SWIFT_STRICT_CONCURRENCY = targeted;
				SWIFT_VERSION = 5.9;
				TARGETED_DEVICE_FAMILY = 1;
				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/Staerk.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Staerk";
"""

    common_project = """
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_LOCALIZABILITY_NONLOCALIZED = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = NO;
				MTL_FAST_MATH = YES;
				SDKROOT = iphoneos;
				SWIFT_EMIT_LOC_STRINGS = YES;
"""

    w("/* Begin XCBuildConfiguration section */")
    w(f"\t\t{project_debug} /* Debug */ = {{")
    w("\t\t\tisa = XCBuildConfiguration;")
    w("\t\t\tbuildSettings = {")
    w(common_project)
    w("\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;")
    w("\t\t\t\tENABLE_TESTABILITY = YES;")
    w("\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;")
    w("\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;")
    w("\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (")
    w('\t\t\t\t\t"DEBUG=1",')
    w('\t\t\t\t\t"$(inherited)",')
    w("\t\t\t\t);")
    w("\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;")
    w("\t\t\t\tONLY_ACTIVE_ARCH = YES;")
    w("\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = \"DEBUG $(inherited)\";")
    w("\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-Onone\";")
    w("\t\t\t};")
    w("\t\t\tname = Debug;")
    w("\t\t};")

    w(f"\t\t{project_release} /* Release */ = {{")
    w("\t\t\tisa = XCBuildConfiguration;")
    w("\t\t\tbuildSettings = {")
    w(common_project)
    w("\t\t\t\tDEBUG_INFORMATION_FORMAT = \"dwarf-with-dsym\";")
    w("\t\t\t\tENABLE_NS_ASSERTIONS = NO;")
    w("\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;")
    w("\t\t\t\tVALIDATE_PRODUCT = YES;")
    w("\t\t\t};")
    w("\t\t\tname = Release;")
    w("\t\t};")

    w(f"\t\t{target_debug} /* Debug */ = {{")
    w("\t\t\tisa = XCBuildConfiguration;")
    w("\t\t\tbuildSettings = {")
    w(common_target)
    w("\t\t\t};")
    w("\t\t\tname = Debug;")
    w("\t\t};")

    w(f"\t\t{target_release} /* Release */ = {{")
    w("\t\t\tisa = XCBuildConfiguration;")
    w("\t\t\tbuildSettings = {")
    w(common_target)
    w("\t\t\t};")
    w("\t\t\tname = Release;")
    w("\t\t};")

    w(f"\t\t{test_debug} /* Debug */ = {{")
    w("\t\t\tisa = XCBuildConfiguration;")
    w("\t\t\tbuildSettings = {")
    w(common_test)
    w("\t\t\t};")
    w("\t\t\tname = Debug;")
    w("\t\t};")

    w(f"\t\t{test_release} /* Release */ = {{")
    w("\t\t\tisa = XCBuildConfiguration;")
    w("\t\t\tbuildSettings = {")
    w(common_test)
    w("\t\t\t};")
    w("\t\t\tname = Release;")
    w("\t\t};")
    w("/* End XCBuildConfiguration section */")
    w("")

    w("/* Begin XCConfigurationList section */")
    w(f"\t\t{project_config_list} /* Build configuration list for PBXProject \"Staerk\" */ = {{")
    w("\t\t\tisa = XCConfigurationList;")
    w("\t\t\tbuildConfigurations = (")
    w(f"\t\t\t\t{project_debug} /* Debug */,")
    w(f"\t\t\t\t{project_release} /* Release */,")
    w("\t\t\t);")
    w("\t\t\tdefaultConfigurationIsVisible = 0;")
    w("\t\t\tdefaultConfigurationName = Release;")
    w("\t\t};")
    w(f"\t\t{target_config_list} /* Build configuration list for PBXNativeTarget \"Staerk\" */ = {{")
    w("\t\t\tisa = XCConfigurationList;")
    w("\t\t\tbuildConfigurations = (")
    w(f"\t\t\t\t{target_debug} /* Debug */,")
    w(f"\t\t\t\t{target_release} /* Release */,")
    w("\t\t\t);")
    w("\t\t\tdefaultConfigurationIsVisible = 0;")
    w("\t\t\tdefaultConfigurationName = Release;")
    w("\t\t};")
    w(f"\t\t{test_config_list} /* Build configuration list for PBXNativeTarget \"StaerkTests\" */ = {{")
    w("\t\t\tisa = XCConfigurationList;")
    w("\t\t\tbuildConfigurations = (")
    w(f"\t\t\t\t{test_debug} /* Debug */,")
    w(f"\t\t\t\t{test_release} /* Release */,")
    w("\t\t\t);")
    w("\t\t\tdefaultConfigurationIsVisible = 0;")
    w("\t\t\tdefaultConfigurationName = Release;")
    w("\t\t};")
    w("/* End XCConfigurationList section */")
    w("\t};")
    w(f"\trootObject = {project_id} /* Project object */;")
    w("}")

    PROJ.mkdir(parents=True, exist_ok=True)
    (PROJ / "project.pbxproj").write_text("\n".join(lines) + "\n", encoding="utf-8")

    scheme_dir = PROJ / "xcshareddata" / "xcschemes"
    scheme_dir.mkdir(parents=True, exist_ok=True)
    scheme = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1500"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{target_id}"
               BuildableName = "Staerk.app"
               BlueprintName = "Staerk"
               ReferencedContainer = "container:Staerk.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES"
      shouldAutocreateTestPlan = "YES">
      <Testables>
         <TestableReference
            skipped = "NO"
            parallelizable = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{test_target_id}"
               BuildableName = "StaerkTests.xctest"
               BlueprintName = "StaerkTests"
               ReferencedContainer = "container:Staerk.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      language = "da"
      region = "DK"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{target_id}"
            BuildableName = "Staerk.app"
            BlueprintName = "Staerk"
            ReferencedContainer = "container:Staerk.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{target_id}"
            BuildableName = "Staerk.app"
            BlueprintName = "Staerk"
            ReferencedContainer = "container:Staerk.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""
    (scheme_dir / "Staerk.xcscheme").write_text(scheme, encoding="utf-8")
    print(f"Wrote {PROJ / 'project.pbxproj'} ({len(swift_files)} app Swift files, {len(test_files)} tests)")


if __name__ == "__main__":
    main()
