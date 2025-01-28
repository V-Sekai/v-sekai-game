#!/bin/sh

# Github Action sets inputs when running image
if [ -z "$BUTLER_API_KEY" ]; then
    BUTLER_API_KEY=$INPUT_API_KEY
fi

echo "Workspace release folder: ${GITHUB_WORKSPACE}/${INPUT_FILEPATH}"
echo "Butler version:"
butler -V

cd ${INPUT_FILEPATH}
for file in *; do
   CHANNEL=$( echo "${file}" | cut -d '_' -f3 | cut -d '.' -f1 | tr '[:upper:]' '[:lower:]');
   echo "Uploading ${file} to ${INPUT_ITCHIO_PROJECT} for platform ${CHANNEL}...";
   butler push ${file} ${INPUT_ITCHIO_PROJECT}:${CHANNEL} --userversion ${INPUT_RELEASE_VERSION};
done
