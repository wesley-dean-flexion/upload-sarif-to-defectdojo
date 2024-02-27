# Upload Sarif results to Defect Dojo

## Configuration Values

### DD_TOKEN

`DD_TOKEN` is authentication token for interacting with DefectDojo (required)

The API token may be found throught DefectDojo's web user interface
by going to `<server name>/api/key-v2`

### DD_PRODUCT

`DD_PRODCT` is name of the product in DefectDojo (required)

### DD_ENGAGEMENT

`DD_ENGAGEMENT` is name of the engagement in DefectDojo

The default value is "cicd" (lowercase, no slash).

### DD_SERVER_PROTO

`DD_SERVER_PROTO` is the protocol / scheme to use when talking to DefectDojo

The default value is `https`.

### DD_SERVER_HOST

`DD_SERVER_HOST` is the hostname of the DefectDojo server (required)

### DD_SERVER_PATH

`SS_SERVER_PATH` is path on the server to the import-scan API endpoint

The default is `/api/v2/import-scan/` which is the standard when
DefectDojo runs at the root of the server (i.e., `dojo.example.com`)

### DD_SCAN_DATE

`DD_SCAN_DATE` the date the scan took place

DefectDojo accepts ISO-8601 dates (but just year, month, and day)
for when scans took place; the default value is when the file being
uploaded was last modified

### DD_MINIMUM_SEVERITY

`DD_MINIMUM_SEVERITY` IS minimum severity level to be imported

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

### DD_CREATE_FINDINGS_GROUP

`DD_CREATE_FINDINGS_GROUP` will create finding groups for single findings

If false, findings will be grouped only when multiple findings.  The default
value is 'true'.  Regardless of this setting, scans with multiple findings
will always be grouped

### DD_FILE_TYPE

`DD_FILE_TYPE` is the MIME type for the file to be uploaded

The default value is determined by the file's extension

### DD_BRANCH

`DD_BRANCH` is the SCM branch where the finding was applicable

This is an optional field with no default
