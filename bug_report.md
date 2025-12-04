### **Bug Report: `flutter build web` Produces an Empty Directory in Firebase Studio (IDX)**

**Product:** Firebase Studio (Project IDX)

**Summary:**
When running `flutter build web` in a Firebase Studio workspace, the command completes and reports "✓ Built build/web" successfully. However, the `build/web` directory is consistently empty. This issue occurs 100% of the time and prevents the deployment of any Flutter web application.

**UPDATE:** This bug has been confirmed to be a platform-level issue. A brand-new project created via `flutter create` exhibits the exact same failure, proving the issue is not related to any specific project's code or dependencies.

**Environment:**
*   **Platform:** Firebase Studio (IDX)
*   **Workspace Configuration:** NixOS-based environment configured via `.idx/dev.nix`.
*   **Flutter Version:** (Determined from `flutter --version` in the environment)
*   **Dart Version:** (Determined from `dart --version` in the environment)

**Problem Description:**
Executing the `flutter build web` command appears to run the entire compilation process without any errors reported to the console. The final output is always a success message. However, upon inspecting the `build/web` folder, it is always empty, containing no files or subdirectories. This makes it impossible to view, test, or deploy the web application.

**Key Evidence from Verbose Build Log:**
Verbose build logs (`flutter build web --verbose`) reveal a critical anomaly. The build process is invalidated because it searches for the entrypoint `index.html` at a malformed path containing a wildcard:
```
invalidated build due to missing files: /home/user/myapp/web/*/index.html
```
This occurs even though `web/index.html` exists at the correct path. This indicates a fundamental issue in how the build tool resolves file paths within the IDX environment.

**Reproduction Steps (100% consistent):**
The bug can be reproduced with a minimal, clean project:
1.  Create a new Flutter project: `flutter create test_project`
2.  Navigate into the new project: `cd test_project`
3.  Attempt to build the web application: `flutter build web`

**Expected Behavior:**
After a successful `flutter build web` command, the `test_project/build/web` directory should be populated with the compiled application files, including `index.html`, `main.dart.js`, and other necessary resources.

**Actual Behavior:**
The command reports "✓ Built build/web", but the `test_project/build/web` directory is empty.

**Conclusion:**
Since a fresh, unmodified Flutter project also fails to build correctly in the same way, the issue is not related to the user's application code, dependencies, or `pubspec.yaml` file. The problem is a fundamental, platform-level issue within the Firebase Studio (IDX) environment where the Flutter build process is unable to write its output to the filesystem due to an internal path resolution error.
