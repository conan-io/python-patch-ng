#!/usr/bin/env bash

set -euo pipefail

SAMPLE_RECIPES_NUM=10

# Find all conanfile.py files that use apply_conandata_patches
RECIPES=$(find . -type f -name "conanfile.py" -exec grep -l "apply_conandata_patches(self)" {} + | sort | uniq)
# And does not need system requirement
RECIPES=$(grep -L "/system" $RECIPES)

echo "Found $(echo "$RECIPES" | wc -l) recipes using apply_conandata_patches."

SAMPLE_RECIPES=$(shuf -e ${RECIPES[@]} -n $SAMPLE_RECIPES_NUM)

echo "Pick $SAMPLE_RECIPES_NUM random recipes to test:"
echo "$SAMPLE_RECIPES"

# Run conan create for each sampled recipe
for it in $SAMPLE_RECIPES; do
    recipe_dir=$(dirname "${it}")
    pushd "$recipe_dir"
    echo "Testing recipe in directory: ${recipe_dir}"
    # Get a version from conandata.yml that uses a patch
    version=$(yq '.patches | keys | .[0]' conandata.yml 2>/dev/null)
    if [ -z "$version" ]; then
        echo "ERROR: No patches found in conandata.yml for $recipe_dir, skipping."
        continue
    fi
    version=$(echo ${version} | tr -d '"')
    # Replace apply_conandata_patches to exit just after applying patches
    sed -i -e 's/apply_conandata_patches(self)/apply_conandata_patches(self); import sys; sys.exit(0)/g' conanfile.py
    # Create the package with the specified version
    conan create . --version=${version} --build=missing
    popd
done