**A Flutter code generator using Dart Analyzer for multi mini-app architecture.**

Scans the entire project (including local packages and git dependencies) to discover annotations and generates a centralized router mapping + one-time DI setup.

---

## ✨ Features

- Uses **Dart Analyzer** to scan source code (no build_runner needed)
- Supports both built-in and **custom user-defined annotations**
- Generates centralized router map
- Generates single DI setup registry (run only once)
- Works with local code + packages downloaded from git or pub.dev

---

## 📦 Installation

```yaml
dependencies:
  fl_inject: ^1.0.0