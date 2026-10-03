"""
Switch the app to its final application ID, e.g.:

    python tool/set_app_id.py com.spendroo.app

Changes the Android application ID and namespace (android/app/build.gradle.kts),
moves MainActivity.kt to the matching Kotlin package, and sets the iOS bundle
IDs. Run it once, before the first Play upload: Play never lets an ID change
after that. See docs/release.md for what else has to follow (OAuth clients,
Firebase config).
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ID_PATTERN = re.compile(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$')


def replace_once(path, pattern, replacement):
    text = path.read_text(encoding='utf-8')
    updated, count = re.subn(pattern, replacement, text)
    if count == 0:
        sys.exit(f'{path}: nothing matched {pattern!r}')
    path.write_text(updated, encoding='utf-8')


def main():
    if len(sys.argv) != 2 or not ID_PATTERN.match(sys.argv[1]):
        sys.exit('usage: python tool/set_app_id.py <lowercase.reverse.domain.id>')
    new_id = sys.argv[1]

    gradle = ROOT / 'android' / 'app' / 'build.gradle.kts'
    old_id = re.search(r'val baseApplicationId = "([^"]+)"', gradle.read_text(encoding='utf-8')).group(1)
    if old_id == new_id:
        sys.exit(f'already {new_id}')
    replace_once(gradle, r'val baseApplicationId = "[^"]+"', f'val baseApplicationId = "{new_id}"')
    replace_once(gradle, r'namespace = "[^"]+"', f'namespace = "{new_id}"')

    kotlin_root = ROOT / 'android' / 'app' / 'src' / 'main' / 'kotlin'
    old_activity = kotlin_root.joinpath(*old_id.split('.')) / 'MainActivity.kt'
    new_activity = kotlin_root.joinpath(*new_id.split('.')) / 'MainActivity.kt'
    new_activity.parent.mkdir(parents=True, exist_ok=True)
    source = old_activity.read_text(encoding='utf-8').replace(f'package {old_id}', f'package {new_id}', 1)
    new_activity.write_text(source, encoding='utf-8')
    old_activity.unlink()
    # Remove the old package folders if they are now empty
    folder = old_activity.parent
    while folder != kotlin_root and not any(folder.iterdir()):
        folder.rmdir()
        folder = folder.parent

    pbxproj = ROOT / 'ios' / 'Runner.xcodeproj' / 'project.pbxproj'
    replace_once(pbxproj, rf'PRODUCT_BUNDLE_IDENTIFIER = {re.escape(old_id)}(\.RunnerTests)?;',
                 lambda m: f'PRODUCT_BUNDLE_IDENTIFIER = {new_id}{m.group(1) or ""};')

    print(f'{old_id} -> {new_id}')
    print('Next: flutter clean, rebuild, and follow "After changing the ID" in docs/release.md.')


if __name__ == '__main__':
    main()
