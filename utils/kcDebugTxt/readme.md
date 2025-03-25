# kcDebugTxt

This shell script generates a debug report (`debug.txt`) of a repository's structure and file contents, excluding common build dependency folders and hidden files. 

This file can then be pasted into an Chat AI assistant (such as ChatGPT) to assist with debugging.

## Usage

```
./debug.sh
```

The script will generate a `debug.txt` file in the current directory, containing:

- Repository Layout: A tree-like structure of directories and files.
- File Details: Name and contents in a Markdown code block.

## Example Output

```shell
Current time: Tue Mar 25 12:34:56 PDT 2025
Let's review the current status of the entire repository, and find any errors or issues.

Current repo layout:
./src
./src/main.sh
./scripts

fileName: `main.sh`
fileContents:
```bash
#!/bin/bash
echo "Hello, world!"
```
```

## Options

- Exclude Files/Folders: Modify the `exclude_patterns` array in the script to add or remove directory/file patterns to exclude.

```shell
exclude_patterns=('*/\.*' '*/node_modules*' '*/my-custom-folder*')
```

## Limitations

- Does not handle very large files gracefully (contents are included in full).