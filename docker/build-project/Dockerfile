FROM ubuntu:latest

ARG INPUT_REPO
ARG INPUT_GAME_NAME
ARG INPUT_DEFAULT_EXPORT
ARG INPUT_XR_PLUGINS
ARG INPUT_NIGHTLY

# $HOME is overwritten by Github Action at runtime
ENV HOMEDIR '/root'

ENV BIN 'release/bin'
ENV BUILD_ARGS '--headless'
ENV BUILD_PLATFORMS 'Linux Windows Mac Android QuestAndroid Web Linux_arm64'
ENV GODOT_REPO 'V-Sekai/world-godot'
ENV GODOT_ZIP 'v-sekai-godot-linuxbsd.zip'
ENV GODOT_TPZ 'v-sekai-godot-templates.zip'
ENV GODOT_EDITOR 'godot.linuxbsd.editor.double.x86_64'
ENV TEMPLATE_DIR "$HOMEDIR/.local/share/godot/export_templates"
ENV ANDROID_SDK_ROOT "$HOMEDIR/android_sdk"
ENV ANDROID_HOME "$HOMEDIR/android_sdk"
ENV XR_PLUGIN_REPO 'V-Sekai/godot_openxr_vendors'

COPY ./build.sh /
RUN chmod +x /build.sh

WORKDIR $HOMEDIR

# Using process substitution feature (not POSIX)
SHELL [ "/bin/bash", "-c" ]

RUN apt-get update && apt-get upgrade -y \
  && apt-get install -y git curl jq zip unzip fontconfig openjdk-17-jdk tree

RUN mkdir -p "./src"
COPY ./editor_settings-4.tres ./src/
COPY ./export_presets.cfg ./src/

RUN TPZ_URLS=$( \
        curl -sS -L \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/repos/${GODOT_REPO}/releases" \
        | jq -r '.[0].assets.[] | select(.name | startswith(env.GODOT_TPZ)).browser_download_url | @sh' | tr -d "\'" \
    ) \
        && echo "${TPZ_URLS}" | while read -r URL; do \
            echo "Downloading ${URL}"; \
            curl -OL --url "${URL}" \
            && echo "Downloaded ${URL} archive."; \
        done && echo "Unzipping..." \
            && cat ${GODOT_TPZ}.* > "${GODOT_TPZ%.*}-merge.zip" && rm ${GODOT_TPZ}.* \
            && unzip "${GODOT_TPZ%.*}-merge.zip" && rm "${GODOT_TPZ%.*}-merge.zip" \
            && mv ${GODOT_TPZ%.*}/${GODOT_TPZ%.*}.tpz templates.zip && rmdir ${GODOT_TPZ%.*} \
            && unzip templates.zip && rm templates.zip

# Get latest Godot editor metadata
RUN curl -sS \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/${GODOT_REPO}/releases" \
    | jq -r '.[0]' > godot_editor_json.txt

# Get editor commit SHA
RUN GODOT_TAG=$( cat 'godot_editor_json.txt' | jq -r '.tag_name') \
    && read obj_type obj_sha < <( echo $( \
        curl -sS \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/repos/${GODOT_REPO}/git/ref/tags/${GODOT_TAG}" \
        | jq -r '.object.type, .object.sha' ) ) \
    && if [ $obj_type == "commit" ]; then \
           GODOT_SHA=${obj_sha}; \
       else \
           GODOT_SHA=$( curl -sS \
           -H "Accept: application/vnd.github+json" \
           "https://api.github.com/repos/${GODOT_REPO}/git/tags/${obj_sha}" \
           | jq '.object.sha' ); \
       fi \
    && echo "Godot Editor SHA: ${GODOT_SHA}" \
    && echo "${GODOT_SHA}" > godot_editor_sha.txt

# Get editor
RUN FILE_URL=$( \
        cat 'godot_editor_json.txt' \
        | jq -r '.assets.[] | select(.name == env.GODOT_ZIP).browser_download_url' \
    ) \
        && echo "Downloading ${FILE_URL}" \
        && curl -OL --url ${FILE_URL} \
        && echo "Downloaded ${GODOT_ZIP%.*} archive. Unzipping..." \
        && unzip ${GODOT_ZIP} && mv ${GODOT_ZIP%.*} ${HOMEDIR}/godot

RUN cp "./godot/${GODOT_EDITOR}" "./${GODOT_EDITOR}" \
        && chmod +x ${GODOT_EDITOR}

RUN mkdir -p ./src/${BIN} \
    && cp templates/version.txt ${HOMEDIR} \
    && GODOT_VERSION=$( cat ${HOMEDIR}/version.txt ) \
    && mkdir -p ${TEMPLATE_DIR}/${GODOT_VERSION} \
    && mv -v templates/* ${TEMPLATE_DIR}/${GODOT_VERSION}/

# Setup Android
RUN curl -sS -OL 'https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip' \
    && unzip commandlinetools-linux-11076708_latest.zip \
    && mkdir -p ${ANDROID_SDK_ROOT} \
    && yes | ./cmdline-tools/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --licenses \
    && yes | ./cmdline-tools/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} "ndk;23.2.8568313" 'cmdline-tools;latest' 'build-tools;34.0.0' 'platforms;android-34' 'cmake;3.22.1' \
    && curl -sS -OL 'https://dl.google.com/android/repository/platform-tools-latest-linux.zip' \
    && unzip platform-tools-latest-linux.zip -d ${ANDROID_SDK_ROOT} \
    && mkdir -p ./src/android/plugins ./src/android/build \
    && touch ./src/android/build/.gdignore \
    && GODOT_VERSION=$( cat ${HOMEDIR}/version.txt ) \
    && echo ${GODOT_VERSION} >> ./src/android/.build_version \
    && unzip ${TEMPLATE_DIR}/${GODOT_VERSION}/android_source.zip -d ./src/android/build

RUN keytool -v -genkey -keystore release.keystore -alias vsekaidebug -keyalg RSA -validity 10000 -dname "cn=Unknown, ou=Unknown, o=Unknown, c=Unknown" -storepass android


ENTRYPOINT ["/bin/bash", "-c", "/build.sh"] 
