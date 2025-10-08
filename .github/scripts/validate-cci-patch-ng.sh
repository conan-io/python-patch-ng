#!/usr/bin/env bash

set -euo pipefail

SAMPLE_RECIPES_NUM=30
RECIPES_BUILD_NUM=10
RECIPES_BUILT_COUNT=0

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

    if [ $RECIPES_BUILT_COUNT -ge $RECIPES_BUILD_NUM ]; then
        echo "Reached the limit of $RECIPES_BUILD_NUM recipes built, stopping. All done."
        break
    fi

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

    # Allow conan create to fail without stopping the script, we will handle errors manually
    set +e

    # Create the package with the specified version
    output=$(conan create . --version=${version} 2>&1)
    # Accept some errors as non-fatal
    if [ $? -ne 0 ]; then
        echo "WARNING: conan create failed for $recipe_dir"
        if echo "$output" | grep -q "ERROR: There are invalid packages"; then
            echo "WARNING: Invalid packages found, skipping the build."
        elif echo "$output" | grep -q "ERROR: Version conflict"; then
            echo "WARNING: Version conflict, skipping the build."
        elif echo "$output" | grep -q "ERROR: Missing binary"; then
            echo "WARNING: Missing binary, skipping the build."
        else
            echo "ERROR: Fatal error during conan create command execution:"
            echo "$output"
            popd
            exit 1
        fi
    else
        echo "INFO: Successfully patched $recipe_dir."
        echo "$output" | tail -n 10
        echo "-------------------------------------------------------"
        RECIPES_BUILT_COUNT=$((RECIPES_BUILT_COUNT + 1))
    fi
    popd
done