# CI workflow

1. Push this repo. `Build` will report "not bootstrapped" (expected).
2. Actions tab -> "Bootstrap platform folders" -> Run workflow (once).
3. `git pull --rebase origin main` locally.
4. Every push to main runs analyze, test and a debug APK build.
   Download the APK from the run's Artifacts and install on your phone.

Pin Flutter: Settings -> Secrets and variables -> Actions -> Variables -> FLUTTER_VERSION (e.g. 3.35.0).
