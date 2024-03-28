# Upload Sarif results to Defect Dojo

[![MegaLinter](https://github.com/wesley-dean-flexion/upload-sarif-to-defectdojo/actions/workflows/megalinter.yml/badge.svg)](https://github.com/wesley-dean-flexion/upload-sarif-to-defectdojo/actions/workflows/megalinter.yml)
[![Test](https://github.com/wesley-dean-flexion/upload-sarif-to-defectdojo/actions/workflows/test.yml/badge.svg)](https://github.com/wesley-dean-flexion/upload-sarif-to-defectdojo/actions/workflows/test.yml)
[![Publish](https://github.com/wesley-dean-flexion/upload-sarif-to-defectdojo/actions/workflows/publish.yml/badge.svg)](https://github.com/wesley-dean-flexion/upload-sarif-to-defectdojo/actions/workflows/publish.yml)

## Quickstart

This should get you started:

```bash
export DD_TOKEN="${DEFECT_DOJO_AUTH_TOKEN}"
curl -s \
  -o './upload_sarif_to_defectdojo.bash' \
  -L 'https://raw.githubusercontent.com/wesley-dean-flexion/upload-sarif-to-defectdojo/main/upload_sarif_to_defectdojo.bash'
./upload_sarif_to_defectdojo.bash \
  -p "${PRODUCT}" \
  -e "${ENGAGEMENT}" \
  -s "${DEFECT_DOJO_SERVER}" \
  /path/to/SARIF/files/*.sarif
 ```

The script can be...

* downloaded at runtime ([raw script link](https://raw.githubusercontent.com/wesley-dean-flexion/upload-sarif-to-defectdojo/main/upload_sarif_to_defectdojo.bash))
* pulled from [GHCR](https://github.com/wesley-dean-flexion/upload-sarif-to-defectdojo/pkgs/container/upload-sarif-to-defectdojo)
* pulled from [DockerHub](https://hub.docker.com/r/wesleydeanflexion/upload-sarif-to-defectdojo)

## Overview

This is a shell script that will iterate across a series of filenames
passed in and upload the results to a DefectDojo instance.  This
hope is to have one process generate SARIF results (e.g.,
[Megalinter](https://megalinter.io/))
so that this script can upload the results.  The original intent of
this script was to upload SARIF-formatted reports produced by
[Megalinter](https://megalinter.io/), but it can work with any
tool that produces SARIF output (e.g., `semgrep --sarif`).

There exist actions in the GitHub Actions Marketplace that will
upload SARIF results to DefectDojo, such as:
[defectdojo-import-scan](https://github.com/marketplace/actions/defectdojo-import-scan)

However, we want to be able to be able to upload results to
an internal, non-Internet-accessible DefectDojo instance, potentially
using an internal CI/CD system (e.g., a Jenkins instance).

Configuration for the tool is expected to be provided by environment
variables; this is to support clean integration with a CI/CD
system that populates environment variables rather than using
flags.  Additionally, the tool is able to use a configuration
file (e.g., `.env`) that can provide values.

The expected usage pattern is for a repository to include a
configuration file with parameters like project name, whether
or not to push results to Jira, etc. and environment variables to
pass server details and authentication credentials.  It's possible
to use all environment variables or all configuration files or
some mix.

The script supports passing multiple files to be uploaded, even
if those files are in different locations or even associated with
different projects. In situations like these, a configuration
file for each location is supported.

Several locations for configuration files are searched with the
first one found being used:

1. current directory's uploadsarifdd.conf
2. current directory's .uploadsarifdd.conf
3. file's repo's uploadsarifdd.conf
4. file's repo's .uploadsarif.dd.conf
5. ~/uploadsarifdd.conf
6. ~/.uploadsarifdd.conf

Future plans may include specifying the configuration via
CLI flag, supporting additional scan types, and/or additional
fields from DefectDojo's import-scan endpoint.

### Examples

```bash
upload_sarif_to_defectdojo.bash megalinter-reports/sarif/*.sarif
```

## CLI Flags

| Short flag | Long Flag    | Description                              |
|------------|--------------|------------------------------------------|
| -b         | --branch     | set the branch to report                 |
| -c         | --config     | specify a configuration file             |
| -d         | --date       | set the scan date                        |
| -D         | --dryrun     | dryrun -- show request but don't send it |
| -e         | --engagement | set the engagement                       |
| -h         | --help       | view the help documentation              |
| -m         | --mime-type  | set the MIME type of the file            |
| -p         | --product    | set the product                          |
| -s         | --server     | set the DefectDojo server hostname       |
| -S         | --severity   | set the minimum severity to include      |
| -t         | --scan-type  | set the type of scan we're reporting     |
| -u         | --url        | set the URL to the SCM                   |

## Containerized Usage

The tool may also be used in containerized form; a [Dockerfile](Dockerfile)
has been provided to simplify running it.

### Building the Image

```bash
docker build
  -t ghcr.io/wesley-dean-flexion/upload-sarif-to-defectdojo
  .
```

### Running the Image

```bash
docker run \
  --rm \
  -it -v "$PWD:$PWD" \
  -w "$PWD" \
  -u "$UID" \
  ghrc.io/wesley-dean-flexion/upload-sarif-to-defectdojo \
  megalinter-reports/sarif/*.sarif
```

## Configuration Values

### DD_TOKEN

`DD_TOKEN` is authentication token for interacting with DefectDojo (required).

**DD_TOKEN is required!!**

The API token may be found throught DefectDojo's web user interface
by going to `<server name>/api/key-v2`

Note: there is no CLI argument to pass the token via the command line as
doing so may result in the token being stored in the shell's history;
it must be passed via environment variable or configuration file.

### DD_PRODUCT

`DD_PRODCT` is name of the product in DefectDojo (required)

**DD_PRODUCT is required!!***

### DD_ENGAGEMENT

`DD_ENGAGEMENT` is name of the engagement in DefectDojo.

The default value is "cicd" (lowercase, no slash).

Set via CLI with `-e` or `--engagement`

### DD_SERVER_PROTO

`DD_SERVER_PROTO` is the protocol / scheme to use when talking to DefectDojo.

The default value is `https`.

### DD_SERVER_HOST

`DD_SERVER_HOST` is the hostname of the DefectDojo server (required)

Set via CLI with `-s` or `--server`

### DD_SERVER_PATH

`SS_SERVER_PATH` is path on the server to the import-scan API endpoint

The default is `/api/v2/import-scan/` which is the standard when
DefectDojo runs at the root of the server (i.e., `dojo.example.com`)

### DD_SCAN_DATE

`DD_SCAN_DATE` the date the scan took place

DefectDojo accepts ISO-8601 dates (but just year, month, and day)
for when scans took place; the default value is when the file being
uploaded was last modified

Set via CLI with `-d` or `--date`

### DD_MINIMUM_SEVERITY (-s)

`DD_MINIMUM_SEVERITY` IS minimum severity level to be imported

Set via CLI with `-S` or `--severity`.

The default value is 'Info'; values may be:

* Info
* Low
* Medium
* High
* Critica

### DD_ACTIVE

`DD_ACTIVE` specifies whether or not the findings are active

the default value is 'true'

### DD_VERIFIED

`DD_VERIFIED` specifies whether or not a finding has been verified

The default value is 'true'

### DD_SCAN_TYPE

`DD_SCAN_TYPE` is the type of scan results to be imported

Set via CLI with `-t` or --scan-type`

The default value is determined by the file's extension

### DD_CLOSE_OLD_FINDINGS

`DD_CLOSE_OLD_FINDINGS` is to close old findings as mitigated when importing

The default value is 'false'

### DD_CLOSE_OLD_FINDINGS_PRODUCT_SCOPE

`DD_CLOSE_OLD_FINDINGS_PRODUCT_SCOPE` will restrict closing to this product

The default value is 'false'

### DD_PUSH_TO_JIRA

`DD_PUSH_TO_JIRA` is whether or not to push findings to Jira as well

The default value is 'false'

### DD_FILE_TYPE

`DD_FILE_TYPE` is the MIME type for the file to be uploaded

Set via CLI with `-m` or `--mime`

The default value is determined by the file's extension

### DD_BRANCH

`DD_BRANCH` is the SCM branch where the finding was applicable

Set via CLI with `-b` or `--branch`

This is an optional field with no default

### DD_COMMIT_HASH

`DD_COMMIT_HASH` is the hash of the commit that is being examined

This is optional and the default value is determined using `git log`.

### DD_SCM_URL

`DD_SCM_URL` is the URL to the Source Code Management system for this repo

This is optional and the default value is determined using `git remote`.
Please be aware that some SCM URLs may include encoded credentials; the
default is filtered to remove such credentials (and any `.git` on the
end of the URL).
