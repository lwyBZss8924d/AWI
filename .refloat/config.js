import { commit } from "refloat";

import pkg from "../package.json";

const { version } = JSON.parse(pkg);
const triple = (platform, arch) => `${archs[arch]}-${platforms[platform]}`;
const sharedLib = {
    macos: "dylib",
    linux: "so",
};
const platforms = {
    macos: "apple-darwin",
    linux: "unknown-linux-gnu",
};
const archs = {
    arm64: "aarch64",
    amd64: "x86_64",
};

export const jobs = ["macos", "linux"].flatMap((platform) => {
    return [
        {
            name: `Build runtime (${platform})`,
            agent: { tags: ["chromium-src", platform] },
            steps: [
                ...["arm64", "amd64"].map((arch) => ({
                    import: { workspace: `core-${triple(platform, arch)}` },
                })),
                {
                    name: "Fetch Chromium",
                    command: `
                        if [ -z "$CHROMIUM_ROOT" ]; then
                            echo "Chromium build environment not setup"

                            exit 2
                        fi

                        if scripts/runtime-pull.sh arm64; then
                            touch skip-build-arm64
                        fi
                        if scripts/runtime-pull.sh amd64; then
                            touch skip-build-amd64
                        fi

                        if [ ! -f skip-build-amd64 ] || [ ! -f skip-build-amd64 ]; then
                            cp chromium/.gclient "$CHROMIUM_ROOT"

                            scripts/gclient.sh sync
                            scripts/patches.sh apply

                            rm -rf "$CHROMIUM_ROOT/src/carbonyl"
                            mkdir "$CHROMIUM_ROOT/src/carbonyl"
                            ln -s "$(pwd)/src" "$CHROMIUM_ROOT/src/carbonyl/src"
                            ln -s "$(pwd)/build" "$CHROMIUM_ROOT/src/carbonyl/build"
                        fi
                    `,
                },
                {
                    parallel: ["arm64", "amd64"].map((arch) => {
                        const target =
                            platform === "linux" && arch === "amd64" ? "Default" : arch;

                        return {
                            serial: [
                                {
                                    name: `Build Chromium (${arch})`,
                                    command: `
                                        if [ ! -f skip-build-${arch} ]; then
                                            (   
                                                export PATH="$PATH:$CHROMIUM_ROOT/depot_tools"

                                                cd "$CHROMIUM_ROOT/src/out/${target}"
                                                ninja headless:headless_shell -j4
                                            )

                                            scripts/copy-binaries.sh ${target} ${arch}
                                        fi
                                    `,
                                    env: {
                                        AR_AARCH64_UNKNOWN_LINUX_GNU: "aarch64-linux-gnu-ar",
                                        CC_AARCH64_UNKNOWN_LINUX_GNU: "aarch64-linux-gnu-gcc",
                                        CXX_AARCH64_UNKNOWN_LINUX_GNU: "aarch64-linux-gnu-g++",
                                        CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER:
                                            "aarch64-linux-gnu-gcc",
                                        AR_X86_64_UNKNOWN_LINUX_GNU: "x86_64-linux-gnu-ar",
                                        CC_X86_64_UNKNOWN_LINUX_GNU: "x86_64-linux-gnu-gcc",
                                        CXX_X86_64_UNKNOWN_LINUX_GNU: "x86_64-linux-gnu-g++",
                                        CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER:
                                            "x86_64-linux-gnu-gcc",
                                    },
                                },

                                {
                                    parallel: [
                                        {
                                            name: `Push binaries to CDN (${arch})`,
                                            command: `
                                            if [ ! -f skip-build-${arch} ]; then
                                                scripts/runtime-push.sh ${arch}
                                            fi
                                        `,
                                            env: {
                                                CDN_ACCESS_KEY_ID: { secret: true },
                                                CDN_SECRET_ACCESS_KEY: { secret: true },
                                            },
                                        },
                                        {
                                            export: {
                                                workspace: `runtime-${triple(platform, arch)}`,
                                                path: `build/pre-built/${triple(platform, arch)}`,
                                            },
                                        },
                                    ],
                                },
                            ],
                        };
                    }),
                },
            ],
        },
        ...["arm64", "amd64"].flatMap((arch) => {
            const triple = `${archs[arch]}-${platforms[platform]}`;
            const lib = `build/${triple}/release/libcarbonyl.${sharedLib[platform]}`;

            return [
                {
                    name: `Build core (${platform}/${arch})`,
                    docker:
                        platform === "linux"
                            ? {
                                image: "fathyb/rust-cross",
                                cache: ["/usr/local/cargo/registry"],
                            }
                            : undefined,
                    agent: { tags: platform === "linux" ? ["docker"] : ["macos"] },
                    steps: [
                        {
                            name: "Install Rust toolchain",
                            command: `rustup target add ${triple}`,
                        },
                        {
                            name: "Build core library",
                            command: `cargo build --target ${triple} --release`,
                            env: { MACOSX_DEPLOYMENT_TARGET: "10.13" },
                        },
                        {
                            name: "Set core library install name",
                            command:
                                platform === "macos"
                                    ? `install_name_tool -id @executable_path/libcarbonyl.dylib ${lib}`
                                    : "echo not necessary",
                        },
                        {
                            export: {
                                workspace: `core-${triple}`,
                                path: "build/*/release/*.{dylib,so,dll}",
                            },
                        },
                    ],
                },
                {
                    name: `Package (${platform}/${arch})`,
                    docker: "fathyb/rust-cross",
                    agent: { tags: ["docker"] },
                    steps: [
                        {
                            import: { workspace: `runtime-${triple}` },
                        },
                        {
                            name: "Zip binaries",
                            command: `
                                mkdir build/zip
                                cp -r build/pre-built/${triple} build/zip/carbonyl-${version}
        
                                cd build/zip
                                zip -r package.zip carbonyl-${version}
                            `,
                        },
                        {
                            export: {
                                artifact: {
                                    name: `carbonyl.${platform}-${arch}.zip`,
                                    path: "build/zip/package.zip",
                                },
                            },
                        },
                    ],
                },
            ];
        }),
    ];
});

if (commit.defaultBranch) {
    jobs.push({
        name: "Publish to npm",
        agent: { tags: ["carbonyl-publish"] },
        docker: "node:18",
        steps: [
            ...["macos", "linux"].flatMap((platform) =>
                ["arm64", "amd64"].map((arch) => ({
                    import: { workspace: `runtime-${triple(platform, arch)}` },
                }))
            ),
            {
                name: "Publish",
                env: { CARBONYL_NPM_PUBLISH_TOKEN: { secret: true } },
                command: `
                    echo "//registry.npmjs.org/:_authToken=\${CARBONYL_NPM_PUBLISH_TOKEN}" > ~/.npmrc

                    scripts/npm-publish.sh --tag next
                `,
            },
        ],
    });
}
