# Itch.io Publish Release - Docker image
## Run from Docker
```bash
INPUT_API_KEY='api-key'
FILEPATH='./example/' #Folder with files to release.
                      #File names must contain platform tag
                      # '_Mac_' or '_windows.exe'
                      #Example: game_0.0.1_windows_latest.exe

INPUT_ITCHIO_PROJECT='example-project' #itch.io Project name
INPUT_RELEASE_VERSION='0.0.1'

docker run --rm --name itch-publish --workdir /github/workspace \
-e "INPUT_API_KEY" -e INPUT_FILEPATH="releases" \
-e "INPUT_ITCHIO_PROJECT" -e "INPUT_RELEASE_VERSION" \
-v "${FILEPATH}":"/github/workspace/releases" \
 itchio-publish:latest
```

## Run as Github Action
```
job-name:
    runs-on: ubuntu-latest
    needs: 
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      ...

      - name: Docker Itch.io Publish
        uses: ./docker/itch-io
        with:
          api_key: ${{ secrets.ITCH_IO_API_KEY }}
          filepath: ${{ github.workspace }}/files_folder
          itchio_project: project_name
          release_version: 0.0.1
```
