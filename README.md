# 🚀 fl_inject

[![Pub Version](https://img.shields.io/pub/v/fl_inject?color=blue)](https://pub.dev/packages/fl_inject)
[![Flutter](https://img.shields.io/badge/Flutter-%E2%9D%A4-red)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

**A lightning-fast, `build_runner`-free Dependency Injection and Router Code Generator tailored for Flutter Super App / Monorepo architectures.**

`fl_inject` leverages the raw power of **Dart Analyzer (AST)** to scan your entire project—including local packages, sub-apps, and git dependencies. It automatically generates a **centralized Screen Registry** and a **unified DI setup function** without the heavy performance toll of standard build runners.

---

## ✨ Why `fl_inject`?

In a large Monorepo (e.g., using `melos`), managing Multi-Routers and cross-module Dependency Injections often leads to spaghetti code or massive `shell_app` imports. `fl_inject` solves this by providing:

- ⚡ **Zero `build_runner` dependency:** Generates code in milliseconds using AST scanning.
- 🔗 **Absolute Decoupling:** Mini apps declare their own DI and Routes. The Shell App knows nothing about them until generation.
- 🛡️ **Type-Safe:** Say goodbye to runtime `ClassNotFound` or typos in routing keys.
- 🌍 **Monorepo Native:** Effortlessly scans nested packages and `package_config.json`.

---

## 📦 Installation

Add `fl_inject` to your `pubspec.yaml`:

```yaml
dependencies:
  fl_inject: ^1.0.2
```

For detailed technical documentation and how the generators work under the hood, please refer to [README_GENERATION.md](README_GENERATION.md).