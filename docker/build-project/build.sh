#!/bin/bash
set -e

export HOME=$HOMEDIR
cd $HOMEDIR

git clone "https://github.com/${INPUT_REPO}.git" "./source"

if [ -n "$INPUT_GAME_NAME" ]; then
    GAME_NAME=$INPUT_GAME_NAME;
else
    GAME_NAME=$( echo ${INPUT_REPO} | cut -d '/' -f2 );
fi

if [ "${INPUT_DEFAULT_EXPORT}" == 'true' ]; then
    echo "default_export enabled. Default exports presets will be used.";
else
    # Don't clobber
    rm -f ./src/export_presets.cfg;
fi

GODOT_SHORT=$( cat ${HOMEDIR}/'version.txt' | cut -d '.' -f1-2 )

shopt -s dotglob
mv -f ./src/* ./source/ && rmdir ./src/ && mv ./source ./src

# Set root folder in config files and copy editor settings
sed -i -r "s|(^[a-z]*/[a-z]*=\")~|\1${HOMEDIR}|g" './src/export_presets.cfg' \
    && mkdir -p ${HOMEDIR}/.config/godot/ \
    && sed -i -r "s|(^export/android/android_sdk_path = \")~|\1${HOMEDIR}|g" './src/editor_settings-4.tres' \
    && sed -i -r "s|(^export/android/debug_keystore = \")~|\1${HOMEDIR}|g" './src/editor_settings-4.tres' \
    && cp -v ./src/editor_settings-4.tres ${HOMEDIR}/.config/godot/editor_settings-${GODOT_SHORT}.tres

cd ./src && echo -n $( git log --format="%(describe:tags,abbrev=0)" -n 1 | cut -d '-' -f1 ) >version-tag.txt \
    && cp version-tag.txt version-nightly.txt \
    && echo -n "-$( git rev-parse --short HEAD )" >>version-nightly.txt \
    && GODOT_SHA=$( cat ${HOMEDIR}/'godot_editor_sha.txt' ) \
    && echo -n "_editor-${GODOT_SHA:0:7}" >>version-nightly.txt \
    && cd ..
    
if [ "${INPUT_NIGHTLY}" == 'true' ]; then
    GIT_REV=$(cat ./src/version-nightly.txt );
else
    GIT_REV=$(cat ./src/version-tag.txt );
fi

echo -e "Game: ${GAME_NAME}\nVersion: ${GIT_REV}\nGodot ${GODOT_SHORT}"

# Import resources
"./${GODOT_EDITOR}" --editor --headless --quit --path './src' 2>&1 >/dev/null

for PLATFORM in ${BUILD_PLATFORMS}; do \
    echo "Building ${PLATFORM}..."; \
    BUILD_DIR="./${BIN}"; EXT=''; \
    if [ "${PLATFORM}" == 'Windows' ]; then \
        EXT='.exe'; \
    elif [ "${PLATFORM}" == 'Android' ] \
        || [ "${PLATFORM}" == 'QuestAndroid' ]; then \
        EXT='.apk'; \
    elif [ "${PLATFORM}" == 'Mac' ]; then \
        EXT='.zip'; \
    elif [ "${PLATFORM}" == 'Web' ]; then \
        BUILD_DIR="${BUILD_DIR}/${GAME_NAME}_${GIT_REV}_${PLATFORM}"; \
        mkdir -p "./src/${BUILD_DIR}"; \
    fi; \
    "./${GODOT_EDITOR}" ${BUILD_ARGS} --path './src' --export-release ${PLATFORM} ${BUILD_DIR}/${GAME_NAME}_${GIT_REV}_${PLATFORM}${EXT} || true; \
    if [ "${PLATFORM}" == 'Web' ]; then \
         zip -r "./src/${BIN}/${GAME_NAME}_${GIT_REV}_${PLATFORM}.zip" ./src/${BUILD_DIR}; \
         rm -r ./src/${BUILD_DIR}; \
    fi; \
done


mkdir -p ${GITHUB_WORKSPACE}/releases && tree -a /root/src && \
    echo "Copying to Github output..." \
    && cp -v $HOMEDIR/src/$BIN/* ${GITHUB_WORKSPACE}/releases \
    && echo "INPUT_NIGHTLY: $INPUT_NIGHTLY"

ls ./src/${BIN}

echo "VERSION_TAG=${GIT_REV}" >> $GITHUB_OUTPUT
