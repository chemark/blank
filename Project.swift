import ProjectDescription

let appBundleId = "com.xingshuhao.NewFile"
let extensionBundleId = "\(appBundleId).FinderExtension"
let appGroup = "group.com.xingshuhao.NewFile"

let sharedSettings: SettingsDictionary = [
    "MACOSX_DEPLOYMENT_TARGET": "26.0",
    "SWIFT_VERSION": "6.0",
    "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
    "DEVELOPMENT_TEAM": "6SKPUQN55Z",
    "CODE_SIGN_STYLE": "Automatic",
    "CODE_SIGN_IDENTITY": "Apple Development",
    "MARKETING_VERSION": "1.0",
    "CURRENT_PROJECT_VERSION": "1",
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
]

let appSigningSettings: SettingsDictionary = [
    "DEVELOPMENT_TEAM": "6SKPUQN55Z",
    "CODE_SIGN_STYLE": "Manual",
    "CODE_SIGN_IDENTITY": "Apple Development",
    "PROVISIONING_PROFILE_SPECIFIER": "NewFile Mac Development",
]

let extensionSigningSettings: SettingsDictionary = [
    "DEVELOPMENT_TEAM": "6SKPUQN55Z",
    "CODE_SIGN_STYLE": "Manual",
    "CODE_SIGN_IDENTITY": "Apple Development",
    "PROVISIONING_PROFILE_SPECIFIER": "NewFile Finder Extension Mac Development",
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
            deploymentTargets: .macOS("26.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "NewFile",
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
            settings: .settings(base: [
                "PRODUCT_NAME": "NewFile",
                "INFOPLIST_KEY_LSMinimumSystemVersion": "26.0",
            ].merging(appSigningSettings) { current, _ in current })
        ),
        .target(
            name: "NewFileFinderExtension",
            destinations: [.mac],
            product: .appExtension,
            bundleId: extensionBundleId,
            deploymentTargets: .macOS("26.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "NewFile Finder Extension",
                "CFBundleShortVersionString": "$(MARKETING_VERSION)",
                "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
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
            settings: .settings(base: [
                "PRODUCT_NAME": "NewFileFinderExtension",
                "INFOPLIST_KEY_LSMinimumSystemVersion": "26.0",
            ].merging(extensionSigningSettings) { current, _ in current })
        ),
        .target(
            name: "NewFileTests",
            destinations: [.mac],
            product: .unitTests,
            bundleId: "\(appBundleId).tests",
            deploymentTargets: .macOS("26.0"),
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
