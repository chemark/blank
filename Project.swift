import ProjectDescription

let appBundleId = "com.xingshuhao.NewFile"
let extensionBundleId = "\(appBundleId).FinderExtension"

let sharedSettings: SettingsDictionary = [
    "MACOSX_DEPLOYMENT_TARGET": "13.0",
    "SWIFT_VERSION": "6.0",
    "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
    "DEVELOPMENT_TEAM": "6SKPUQN55Z",
    "CODE_SIGN_STYLE": "Automatic",
    "CODE_SIGN_IDENTITY": "Apple Development",
    "MARKETING_VERSION": "1.0",
    "CURRENT_PROJECT_VERSION": "1",
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
]

// Debug 用分发证书签名：Apple Development 证书的私钥已丢失，本机没有其他可用身份。
// 拿到 Developer ID Application 证书后应改用它。不带描述文件，沙盒临时例外仍然生效。
let appSigningSettings: SettingsDictionary = [
    "DEVELOPMENT_TEAM": "6SKPUQN55Z",
    "CODE_SIGN_STYLE": "Manual",
    "CODE_SIGN_IDENTITY": "3rd Party Mac Developer Application",
    "CODE_SIGN_INJECT_BASE_ENTITLEMENTS": "NO",
    "PROVISIONING_PROFILE_SPECIFIER": "",
]

let extensionSigningSettings: SettingsDictionary = [
    "DEVELOPMENT_TEAM": "6SKPUQN55Z",
    "CODE_SIGN_STYLE": "Manual",
    "CODE_SIGN_IDENTITY": "3rd Party Mac Developer Application",
    "CODE_SIGN_INJECT_BASE_ENTITLEMENTS": "NO",
    "PROVISIONING_PROFILE_SPECIFIER": "",
]

let appDistributionSettings: SettingsDictionary = [
    "DEVELOPMENT_TEAM": "6SKPUQN55Z",
    "CODE_SIGN_STYLE": "Manual",
    "CODE_SIGN_IDENTITY": "3rd Party Mac Developer Application",
    "PROVISIONING_PROFILE_SPECIFIER": "NewFile Mac App Store",
]

let extensionDistributionSettings: SettingsDictionary = [
    "DEVELOPMENT_TEAM": "6SKPUQN55Z",
    "CODE_SIGN_STYLE": "Manual",
    "CODE_SIGN_IDENTITY": "3rd Party Mac Developer Application",
    "PROVISIONING_PROFILE_SPECIFIER": "NewFile Finder Extension Mac App Store",
]

let project = Project(
    name: "NewFile",
    organizationName: "Xing Shuhao",
    options: .options(
        automaticSchemesOptions: .disabled
    ),
    settings: .settings(base: sharedSettings),
    targets: [
        .target(
            name: "NewFile",
            destinations: [.mac],
            product: .app,
            bundleId: appBundleId,
            deploymentTargets: .macOS("13.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "Blank",
                "CFBundleShortVersionString": "$(MARKETING_VERSION)",
                "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
                "LSApplicationCategoryType": "public.app-category.productivity",
                "NSHumanReadableCopyright": "Copyright © 2026 Xing Shuhao. All rights reserved.",
            ]),
            sources: [
                "NewFile/App/**",
                "NewFile/Shared/**",
            ],
            resources: [
                "NewFile/Resources/**",
            ],
            entitlements: "NewFile/NewFile.entitlements",
            dependencies: [
                .target(name: "NewFileFinderExtension"),
            ],
            settings: .settings(
                base: ["PRODUCT_NAME": "Blank", "INFOPLIST_KEY_LSMinimumSystemVersion": "13.0"],
                debug: appSigningSettings,
                release: appDistributionSettings
            )
        ),
        .target(
            name: "NewFileFinderExtension",
            destinations: [.mac],
            product: .appExtension,
            bundleId: extensionBundleId,
            deploymentTargets: .macOS("13.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "Blank",
                "CFBundleShortVersionString": "$(MARKETING_VERSION)",
                "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
                "LSUIElement": true,
                "NSExtension": [
                    "NSExtensionPointIdentifier": "com.apple.FinderSync",
                    "NSExtensionPrincipalClass": "$(PRODUCT_MODULE_NAME).FinderSync",
                ],
            ]),
            sources: [
                "NewFile/FinderExtension/**",
                "NewFile/Shared/**",
            ],
            resources: [
                "NewFile/FinderExtensionResources/**",
            ],
            entitlements: "NewFile/NewFileFinderExtension.entitlements",
            settings: .settings(
                base: ["PRODUCT_NAME": "NewFileFinderExtension", "INFOPLIST_KEY_LSMinimumSystemVersion": "13.0"],
                debug: extensionSigningSettings,
                release: extensionDistributionSettings
            )
        ),
        .target(
            name: "NewFileTests",
            destinations: [.mac],
            product: .unitTests,
            bundleId: "\(appBundleId).tests",
            deploymentTargets: .macOS("13.0"),
            infoPlist: .default,
            sources: [
                "NewFile/Tests/**",
                "NewFile/Shared/**",
            ],
            dependencies: [],
            settings: .settings(base: [
                "PRODUCT_NAME": "NewFileTests",
            ])
        ),
    ],
    schemes: [
        .scheme(
            name: "NewFile",
            shared: true,
            buildAction: .buildAction(targets: ["NewFile"]),
            testAction: .targets(["NewFileTests"]),
            runAction: .runAction(executable: "NewFile")
        )
    ]
)
