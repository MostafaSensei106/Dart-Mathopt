//! Link the NDK C++ standard library **statically** on Android.
//!
//! Background: `highs-sys` unconditionally emits `cargo:rustc-link-lib=stdc++`
//! for any `*-linux-*` target  including `*-linux-android`. Android has no
//! `libstdc++.so` (only the NDK's `libc++`), so the produced `.so` fails to
//! `dlopen` on devices with `cannot locate symbol ...` / missing
//! `libstdc++.so`. Pulling `libc++_static.a` (+ `libc++abi.a`, `libunwind.a`)
//! into the final link resolves every C++ symbol at build time: no shared
//! C++ runtime to bundle, no APK bloat, no loader surprises.
//!
//! NDK discovery is cargokit-proof: besides the usual env vars it derives the
//! sysroot from the `CC_<target>` compiler cargokit always provides, so this
//! works under Gradle (which scrubs the user's shell env) with zero setup.
//!
//! This script is a no-op for every non-Android target (desktop builds and
//! `cargo check` on the host are unaffected). If no NDK is found it emits a
//! warning and does nothing, so other platforms never break.

use std::env;
use std::path::PathBuf;

fn main() {
    let target = env::var("TARGET").unwrap_or_default();
    if !target.contains("android") {
        return;
    }

    // Guard: only known Android triples get the static-libc++ treatment.
    match target.as_str() {
        t if t.starts_with("aarch64")
            || t.starts_with("armv7")
            || t.starts_with("i686")
            || t.starts_with("x86_64")
            || t.starts_with("riscv64") => {}
        _ => {
            println!(
                "cargo:warning=dart_mathopt: unknown Android triple `{target}`, \
                 skipping static libc++ link (device dlopen may fail)"
            );
            return;
        }
    };

    let Some(lib_dir) = find_android_lib_dir(&target) else {
        println!(
            "cargo:warning=dart_mathopt: no Android NDK sysroot found \
             (tried ANDROID_NDK_ROOT/ANDROID_NDK_HOME/ANDROID_NDK, \
             $ANDROID_HOME/ndk, and CC_<target>/-print-sysroot), \
             skipping static libc++ link (device dlopen may fail)"
        );
        return;
    };

    // Dependents first: libc++ needs c++abi. (libunwind is intentionally
    // omitted: NDK 28's libc++_static.a links clean without it, verified by
    // zero remaining undefined C++ symbols; adding a missing archive would
    // only print noise.)
    for lib in ["libc++_static.a", "libc++abi.a"] {
        let path = lib_dir.join(lib);
        if !path.exists() {
            println!(
                "cargo:warning=dart_mathopt: {} not found, skipping",
                path.display()
            );
            continue;
        }
        println!("cargo:rustc-link-arg={}", path.display());
    }

    // `highs-sys` unconditionally emits `cargo:rustc-link-lib=stdc++` for any
    // `*-linux-*` target. The linker would resolve it to the NDK's per-API
    // `libstdc++.so` stub and record it as DT_NEEDED  but no such file
    // exists on devices, so `dlopen` fails. Shadow it with an *empty* static
    // archive placed earlier on the search path: `-lstdc++` then resolves to
    // nothing (all real symbols already came from `libc++_static.a` above),
    // and static archives never produce DT_NEEDED entries.
    // An empty archive is just the 8-byte magic  no tooling required.
    let out_dir = PathBuf::from(env::var("OUT_DIR").unwrap_or_default());
    let stub_dir = out_dir.join("android_stubs");
    std::fs::create_dir_all(&stub_dir).ok();
    if std::fs::write(stub_dir.join("libstdc++.a"), b"!<arch>\n").is_ok() {
        println!("cargo:rustc-link-search=native={}", stub_dir.display());
    } else {
        println!(
            "cargo:warning=dart_mathopt: could not write libstdc++.a stub \
             (device dlopen may fail)"
        );
    }

    println!("cargo:rerun-if-env-changed=ANDROID_NDK_ROOT");
    println!("cargo:rerun-if-env-changed=ANDROID_NDK_HOME");
    println!("cargo:rerun-if-env-changed=ANDROID_NDK");
    println!("cargo:rerun-if-env-changed=ANDROID_HOME");
}

/// Returns `<sysroot>/usr/lib/<triple>` for the current Android target.
///
/// Search order:
/// 1. `ANDROID_NDK_ROOT` > `ANDROID_NDK_HOME` > `ANDROID_NDK` (plus the host
///    prebuilt dir derived from `HOST`), then newest `$ANDROID_HOME/ndk/*`
///    / `$ANDROID_SDK_ROOT/ndk/*`.
/// 2. The `CC_<target>` compiler cargokit/gradle always provides
///    (`CC_aarch64-linux-android`, `CC_AARCH64_LINUX_ANDROID`, `TARGET_CC`,
///    `CC`): `<clang> -print-sysroot`, falling back to
///    `<clang>/../sysroot` path derivation.
fn find_android_lib_dir(target: &str) -> Option<PathBuf> {
    let triple_dir: &str = match target {
        t if t.starts_with("aarch64") => "aarch64-linux-android",
        t if t.starts_with("armv7") => "arm-linux-androideabi",
        t if t.starts_with("i686") => "i686-linux-android",
        t if t.starts_with("x86_64") => "x86_64-linux-android",
        t if t.starts_with("riscv64") => "riscv64-linux-android",
        _ => return None,
    };

    // 1. NDK root from the environment.
    if let Some(ndk) = find_ndk_root() {
        let dir = ndk_sysroot_lib(&ndk, triple_dir);
        if dir.join("libc++_static.a").exists() {
            return Some(dir);
        }
    }

    // 2. Compiler-derived sysroot (works under Gradle/cargokit, which sets
    //    CC_<target> but scrubs ANDROID_* from the user's shell).
    let transformed = target.to_uppercase().replace(['-', '.'], "_");
    let raw_key = format!("CC_{target}");
    let mut candidates = vec![
        raw_key,
        format!("CC_{transformed}"),
        "TARGET_CC".to_string(),
        "CC".to_string(),
    ];
    for key in candidates.drain(..) {
        let Ok(cc) = env::var(&key) else {
            continue;
        };
        let cc_path = PathBuf::from(&cc);
        if !cc_path.exists() {
            continue;
        }
        // Prefer the compiler's own answer...
        if let Some(sysroot) = print_sysroot(&cc) {
            let dir = sysroot.join("usr/lib").join(triple_dir);
            if dir.join("libc++_static.a").exists() {
                return Some(dir);
            }
        }
        // ...fall back to <clang>/../sysroot path derivation.
        if let Some(parent) = cc_path.parent().and_then(|p| p.parent()) {
            let dir = parent.join("sysroot/usr/lib").join(triple_dir);
            if dir.join("libc++_static.a").exists() {
                return Some(dir);
            }
        }
    }
    None
}

/// `<ndk>/toolchains/llvm/prebuilt/<host>/sysroot/usr/lib/<triple>`.
fn ndk_sysroot_lib(ndk: &str, triple_dir: &str) -> PathBuf {
    let host = env::var("HOST").unwrap_or_default();
    let prebuilt = if host.contains("apple") {
        "darwin-x86_64"
    } else if host.contains("windows") {
        "windows-x86_64"
    } else {
        "linux-x86_64"
    };
    PathBuf::from(ndk)
        .join("toolchains/llvm/prebuilt")
        .join(prebuilt)
        .join("sysroot/usr/lib")
        .join(triple_dir)
}

/// `ANDROID_NDK_ROOT` > `ANDROID_NDK_HOME` > `ANDROID_NDK` > newest `$ANDROID_HOME/ndk/*`.
fn find_ndk_root() -> Option<String> {
    for var in ["ANDROID_NDK_ROOT", "ANDROID_NDK_HOME", "ANDROID_NDK"] {
        if let Ok(path) = env::var(var) {
            if !path.is_empty() {
                return Some(path);
            }
        }
    }
    let home = env::var("ANDROID_HOME")
        .or_else(|_| env::var("ANDROID_SDK_ROOT"))
        .ok()?;
    let mut candidates: Vec<PathBuf> = std::fs::read_dir(PathBuf::from(home).join("ndk"))
        .ok()?
        .filter_map(|e| e.ok().map(|e| e.path()))
        .filter(|p| p.is_dir())
        .collect();
    candidates.sort();
    candidates.pop().map(|p| p.to_string_lossy().into_owned())
}

/// Runs `<cc> -print-sysroot`; never fails the build on error.
fn print_sysroot(cc: &str) -> Option<PathBuf> {
    let out = std::process::Command::new(cc)
        .arg("-print-sysroot")
        .output()
        .ok()?;
    if !out.status.success() {
        return None;
    }
    let path = String::from_utf8(out.stdout).ok()?.trim().to_string();
    if path.is_empty() {
        return None;
    }
    Some(PathBuf::from(path))
}
