#!/bin/sh
# Publishes a release: builds, tags, uploads the zip to GitHub, bumps the Homebrew cask.
#   ./release.sh 0.2.0
# Needs: gh (logged in), push access to this repo and nicholastn1/homebrew-tap.
set -e
V=${1:?usage: ./release.sh <version>}
cd "$(dirname "$0")"
[ -z "$(git status --porcelain)" ] || { echo "Commit your changes first."; exit 1; }

VERSION=$V ./build.sh
./Cadence.app/Contents/MacOS/Cadence --selftest
ZIP=Cadence-$V.zip
ditto -c -k --keepParent Cadence.app "$ZIP"
SHA=$(shasum -a 256 "$ZIP" | cut -d' ' -f1)

git tag "v$V" && git push origin "v$V"
gh release create "v$V" "$ZIP" --title "Cadence $V" --generate-notes

TAP=$(mktemp -d)
gh repo clone nicholastn1/homebrew-tap "$TAP" -- -q
sed -e "s/@VERSION@/$V/" -e "s/@SHA256@/$SHA/" Casks/cadence.rb > "$TAP/Casks/cadence.rb"
git -C "$TAP" add -A && git -C "$TAP" commit -qm "cadence $V" && git -C "$TAP" push -q
rm -rf "$TAP" "$ZIP"
echo "Released $V. Install: brew install --cask nicholastn1/tap/cadence"
