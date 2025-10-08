#!/usr/bin/env bash

set -euo pipefail

# Get TEST_ALL_RECIPES from environment variable, default to 0 (false)
PYTHON_NG_TEST_ALL_RECIPES=${PYTHON_NG_TEST_ALL_RECIPES:-0}

SAMPLE_RECIPES_NUM=30
RECIPES_BUILD_NUM=10
RECIPES_BUILT_COUNT=0

# Ensure required tools are installed
COMMANDS=("conan" "yq" "jq")
for cmd in "${COMMANDS[@]}"; do
    if ! which $cmd &> /dev/null; then
        echo "ERROR: $cmd is not installed. Please install $cmd to proceed."
        exit 1
    fi
done

# Find all conanfile.py files that use apply_conandata_patches
RECIPES=$(find . -type f -name "conanfile.py" -exec grep -l "apply_conandata_patches(self)" {} + | sort | uniq)
# And does not need system requirement
RECIPES=$(grep -L "/system" $RECIPES)
# And does not contain Conan 1 imports
RECIPES=$(grep -L "from conans" $RECIPES)

echo "Found $(echo "$RECIPES" | wc -l) recipes using apply_conandata_patches."

if [ "${PYTHON_NG_TEST_ALL_RECIPES}" -eq "1" ]; then
    SAMPLE_RECIPES_NUM=$(echo "$RECIPES" | wc -l)
    RECIPES_BUILD_NUM=$SAMPLE_RECIPES_NUM
    echo "PYTHON_NG_TEST_ALL_RECIPES is set to 1, testing all $SAMPLE_RECIPES_NUM recipes."
else
    RECIPES=$(shuf -e ${RECIPES[@]} -n $SAMPLE_RECIPES_NUM)
    echo "Pick $SAMPLE_RECIPES_NUM random recipes to test:"
    echo "$RECIPES"
fi

# Run conan create for each sampled recipe
for it in $RECIPES; do

    if [ $RECIPES_BUILT_COUNT -ge $RECIPES_BUILD_NUM ]; then
        echo "Reached the limit of $RECIPES_BUILD_NUM recipes built, stopping. All done."
        break
    fi

    recipe_dir=$(dirname "${it}")
    pushd "$recipe_dir" > /dev/null
    echo "Testing recipe in directory: ${recipe_dir}"
    # Get a version from conandata.yml that uses a patch
    version=$(yq '.patches | keys | .[0]' conandata.yml 2>/dev/null)
    if [ -z "$version" ]; then
        echo "ERROR: No patches found in conandata.yml for $recipe_dir, skipping."
        popd > /dev/null
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
        allowed_errors=(
            "ERROR: There are invalid packages"
            "ERROR: Version conflict"
            "ERROR: Missing binary"
            "Failed to establish a new connection"
            "ConanException: sha256 signature failed"
            "ConanException: Error downloading file"
            "ConanException: Cannot find"
            "certificate verify failed: certificate has expired"
            "NotFoundException: Not found"
        )
        # check if any allowed error is in the output
        if printf '%s\n' "${allowed_errors[@]}" | grep -q -f - <(echo "$output"); then
            echo "WARNING: Could not apply patches, skipping build:"
            echo "$output" | tail -n 10
            echo "-------------------------------------------------------"
        else
            echo "ERROR: Fatal error during conan create command execution:"
            echo "$output"
            popd > /dev/null
            exit 1
        fi
    else
        echo "INFO: Successfully patched $recipe_dir."
        echo "$output" | tail -n 10
        echo "-------------------------------------------------------"
        RECIPES_BUILT_COUNT=$((RECIPES_BUILT_COUNT + 1))
    fi
    popd > /dev/null
done