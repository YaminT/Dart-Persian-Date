#!/usr/bin/env bash
# Publishes packages/<name> from a temporary copy outside this repository.
#
# pub applies every .pubignore from the git root down, and packages/.pubignore
# keeps the sub-packages out of the jalali_date archive, so they cannot be
# published in place. The copy drops pubspec_overrides.yaml, so the package
# resolves its jalali_date dependency from pub.dev like a user would.
#
# Publish jalali_date first: the sub-packages depend on the jalali_date
# version in their pubspec, and pub resolves it from pub.dev.
#
# Usage: tool/publish_package.sh <name> [--dry-run]
set -euo pipefail

name=${1:?usage: tool/publish_package.sh <name> [--dry-run]}
shift
root=$(cd "$(dirname "$0")/.." && pwd)
src="$root/packages/$name"
[ -f "$src/pubspec.yaml" ] || { echo "no package at $src" >&2; exit 1; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cp -R "$src" "$tmp/$name"
cd "$tmp/$name"
rm -rf .dart_tool build pubspec.lock pubspec_overrides.yaml

if grep -q 'sdk: flutter' pubspec.yaml; then
  flutter pub publish "$@"
else
  dart pub publish "$@"
fi
