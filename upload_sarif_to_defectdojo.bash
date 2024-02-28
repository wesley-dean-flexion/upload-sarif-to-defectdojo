#!/usr/bin/env bash

## @file upload_sarif_to_defectdojo.bash
## @author CQPFC Team
## @brief a shell script to automate uploading SARIF results to DefectDojo
## @details
## This is a shell script that will iterate across a series of filenames
## passed in and upload the results to a DefectDojo instance.  This
## hope is to have one process generate SARIF results (e.g., Megalinter)
## so that this script can upload the results.
##
## There exist actions in the GitHub Actions Marketplace that will
## upload SARIF results to DefectDojo, such as:
## https://github.com/marketplace/actions/defectdojo-import-scan
##
## However, we want to be able to be able to upload results to
## an internal, non-Internet-accessible DefectDojo instance, potentially
## using an internal CI/CD system (e.g., a Jenkins instance).
##
## Configuration for the tool is expected to be provided by environment
## variables; this is to support clean integration with a CI/CD
## system that populates environment variables rather than using
## flags.  Additionally, the tool is able to use a configuration
## file (e.g., `.env`) that can provide values.
##
## The expected usage pattern is for a repository to include a
## configuration file with parameters like project name, whether
## or not to push results to Jira, etc. and environment variables to
## pass server details and authentication credentials.  It's possible
## to use all environment variables or all configuration files or
## some mix.
##
## The script supports passing multiple files to be uploaded, even
## if those files are in different locations or even associated with
## different projects. In situations like these, a configuration
## file for each location is supported.
##
## Several locations for configuration files are searched with the
## first one found being used:
##
## 1. current directory's uploadsarifdd.conf
## 2. current directory's .uploadsarifdd.conf
## 3. file's repo's uploadsarifdd.conf
## 4. file's repo's .uploadsarif.dd.conf
## 5. ~/uploadsarifdd.conf
## 6. ~/.uploadsarifdd.conf
##
## Future plans may include specifying the configuration via
## CLI flag, supporting additional scan types, and/or additional
## fields from DefectDojo's import-scan endpoint.
##
## @par Examples
## @code
## upload_sarif_to_defectdojo.bash megalinter-reports/sarif/*.sarif
## @endcode


set -euo pipefail


## @fn is_git_repository()
## @brief determine if a file is in a git-associated file structure
## @details
## This determines in the directory structure where a file is located
## is associated with a git repository.  It does NOT check to see if
## a file is staged or tracked by git.  We want to be able to have
## a tool (e.g., Megalinter) deposit scan results (e.g., to
## megalinter-reports/sarif/REPOSITORY_KICS.sarf without having
## to add that file to the repository.  This will allow us to check
## to see if there's a configuration file in the root of the repository
## if, in fact, it's being run from inside of a git repository.
## @param filename the filename to use as a basis for searching
## @retval 0 (True) if the file's in a git directory
## @retval 1 (False) if the file isn't in a git directory
## @par Examples
## @code
## if is_git_repository "megalinter-reports/sarif/REPOSITORY_KICS.sarif" ; then
## @endcode
is_git_repository() {
  directory="$(dirname "${1:-.}")"

  (
    cd "$directory" || exit 1
    git rev-parse --quiet > /dev/null 2>&1
  )
}


## @fn git_branch()
## @brief determine the current branch of a git repository
## @details
## This will determine the current branch of a git repository
## where a specified file lives.  Unlike `git rev-parse`,
## we can't provide a `--prefix` so we're just going to
## `cd` there and run `git branch`.
## @param filename the file to use as a basis for searching
## @retval 0 (True) if a branch could be determined
## @retval 1 (False) if a branch could not be determined
## @returns the current branch of the repository
## @par Examples
## @code
## filename=~/src/projecta
## echo "The current branch for '$filename' is '$(git_branch "$filename")'"
## @endcode
git_branch() {
  directory="$(dirname "${1:-.}")"

  (
    cd "$directory" || exit 1
    git branch --show-current
  )
}


## @fn get_scan_type()
## @brief determine the scan type based on a filename
## @details
## DefectDojo doesn't get the filename we're sending, so we
## have to explicitly tell it what type of scan results we're
## sending to it.  This looks at the filename and attempts to
## determine what we're sending based on the filename.  So,
## for example, if a file matches *.sarif, we tell DefectDojo
## that we're sending SARIF results.  Note, this really only
## looks at the filename -- it doesn't interact with the file;
## in fact, it doesn't matter if the file exists or not.
## @param filename the filename to examine
## @retval 0 (True) if a scan type was determined
## @retval 1 (False) if a scan type could not be determined
## @returns the scan type of the specified file
## @par Examples
## @code
## echo "The scan type was $(get_scan_type "foobar.sarif")"
## @endcode
get_scan_type() {
  case "${1?No filename provided to get_scan_type}" in
    *.sarif)
      echo "SARIF"
      ;;
    *)
      echo "Unable to determine scan type" 1>&2
      exit 1
      ;;
  esac
}


## @fn get_mime_type()
## @brief determine a file's MIME type based on a filename
## @details
## Just like get_scan_type(), this looks at a filename (which
## may not exist) and attempts to determine its MIME type.
## As a fallback, we use the `file` command to try to figure
## it out.  If that fails, we're done.  It's less likely that
## `file` will optimally detect the type; for example, a SARIF
## file is reported as "text/plain" rather than ## "application/sarif"
## Also, we're doing the simple test first because want to
## minimize the number of external dependencies.  The result is
## returned via STDOUT.
## @param filename the filename to examine
## @retval 0 (True) if a MIME type could be guessed
## @retval 1 (False) if a MIME type couldn't be determined
## @returns the MIME type of the specified file
## @par Examples
## @code
## curl -F "file=@filename;type=$(get_mime_type "$filename")" ...
## @endcode
get_mime_type() {
  case "${1?No filename provded to get_mime_type}" in
    *.sarif)
      echo "application/SARIF"
      ;;
    *)
      file --brief --mime-type "$1"
      ;;
  esac
}


## @fn get_scan_date()
## @brief determine when a scan report was updated
## @details
## This will look at a provided filename, extract its last modification
## date, and then returns the year, month, and day-of-month in ISO-8601
## format (YYYY-mm-dd); DefectDojo only accepts the date, not the full
## ISO-8601 formatted datetime string.  The result is returned via STDOUT.
## @param filename the filename to examine
## @param DD_SCAN_DATE force this specific date
## @retval 0 (True) if a date could be determined
## @retval 1 (False) if a date could not be determined
## @returns the date of the scan
##
## @par Examples
## @code
## date1="$(get_scan_date "$filename1")"
## date2="$(DD_SCAN_DATE=2024-02-26 get_scan_date "$filename2")"
## DD_SCAN_DATE=2024-02-27
## get_scan_date "$filename3"
## @endcode
get_scan_date() {
  filename="${1?No filename provided to get_scan_date}"
  echo "${DD_SCAN_DATE:-$(date +'%Y-%m-%d' -d "$(stat -L -c '%y' "$filename")")}"
}


## @fn get_scm_url()
## @brief get the SCM URL associated with a repository
## @details
## This is a wrapper around `git remote get-url` that will filter out
## any usernames in the SCM URL and strip any .git extension
##
## https://wesley-dean-flexion@github.com/wesley-dean-flexion/sample.git
##   becomes
## https://github.com/wesley-dean-flexion/sample
##
## The default origin is 'origin' and the default location is the
## current directory.  The result is returned via STDOUT.
## @param filename where to find the repository
## @param origin the origin to examine
## @retval 0 (True) if the URL could be determined
## @retval 1 (False) if the URL could not be determined
## @returns URL to the SCM
## @par Examples
## @code
## remote_url="$(get_scm_url "/path/to/repo")"
## @endcode
get_scm_url() {
  directory="$(dirname "${1:-.}")"
  origin="${2:-origin}"

  (
    cd "$directory" || exit 1
    git remote get-url --push "$origin" | sed -Ee 's|://[^@]*@|://|' -Ee 's|\.git$||'
  )
}


## @fn get_commit_hash()
## @brief get the current full commit hash for a repository
## @details
## This is just a wrapper around `git log` that's easier to
## read.  Nothing special, nothing filtered.  The output
## is returned via STDOUT.
## @param filename the location of the repository to examine
## @retval 0 (True) if the commit hash could be found
## @retval 1 (False) if the commit hash could not be found
## @returns full commit hash
## @par Examples
## @code
## commit_hash="$(get_commit_hash "/path/to/repo")"
## @endcode
get_commit_hash() {
  directory="$(dirname "${1:-.}")"

  (
    cd "$directory" || exit 1
    git log -n1 --pretty=format:"%H"
  )
}


declare -a configuration_sources
declare -a form_values

if [ "$#" -eq 0 ] ; then
  echo "Error: no report filenames passed" 1>&2
  exit 1
fi


for filename in "$@" ; do
 form_values=()

  configuration_sources=(
  "./uploadsarifdd.conf"
  "./.uploadsarifdd.conf"
  )

  if is_git_repository "$filename" ; then
    configuration_sources+=("$(git rev-parse --show-toplevel --prefix "$filename")/uploadsarifdd.conf")
    configuration_sources+=("$(git rev-parse --show-toplevel --prefix "$filename")/.uploadsarifdd.conf")
  fi

  configuration_sources+=("${HOME}/uploadsarifdd.conf")
  configuration_sources+=("${HOME}/.uploadsarifdd.conf")

  for configuration_file in "${configuration_sources[@]}" ; do
    if [ -e "$configuration_file" ] ; then
      echo "Importing configuration from $configuration_file"

      set -o allexport
      # shellcheck disable=SC1090
      source "$configuration_file"
      set +o allexport

      break
    fi
  done

  NOOP="${NOOP:-echo}"

  if [ -z "${DD_TOKEN:-}" ] ; then
    echo "No value for DD_TOKEN provided" 1>&2
    exit 1
  fi

  if [ -z "$DD_PRODUCT" ] ; then
    echo "No value for DD_PRODUCT provided" 1>&2
    exit 1
  fi

  if [ -z "$DD_SERVER_HOST" ] ; then
    echo "No value for DD_SERVER_HOST provided" 1>&1
    exit 1
  fi

  # attach form values for DefectDojo's API
  form_values+=("active=${DD_ACTIVE:-true}")
  form_values+=("close_old_findings=${DD_CLOSE_OLD_FINDINGS:-false}")
  form_values+=("close_old_findings_product_scope=${DD_CLOSE_OLD_FINDINGS_PRODUCT_SCOPE:-false}")
  form_values+=("create_finding_groups_for_all_findings=${DD_CREATE_FINDINGS_GROUP:-false}")
  form_values+=("engagement_name=${DD_ENGAGEMENT:-cicd}")
  form_values+=("minimum_severity=${DD_MINIMUM_SEVERITY:-Info}")
  form_values+=("product_name=${DD_PRODUCT?No DD_PRODUCT provided}")
  form_values+=("push_to_jira=${DD_PUSH_TO_JIRA:-false}")
  form_values+=("scan_date=${DD_SCAN_DATE:-$(get_scan_date "$filename")}")
  form_values+=("scan_type=${DD_SCAN_TYPE:-$(get_scan_type "$filename")}")
  form_values+=("verified=${DD_VERIFIED:-true}")

  # attach the filename of the scan results with curl's `@` notation
  form_values+=("file=@${filename};type=${DD_FILE_TYPE:-$(get_mime_type "$filename")}")

  if is_git_repository "$filename" \
  || [ -n "${DD_BRANCH:-}" ] ; then
    form_values+=("branch=${DD_BRANCH:-$(git_branch "$filename")}")
  fi

  if is_git_repository "$filename" \
  || [ -n "${DD_COMMIT_HASH:-}" ] ; then
    form_values+=("commit_hash=${DD_COMMIT_HASH:-$(get_commit_hash "$filename")}")
  fi

  if is_git_repository "$filename" \
  || [ -n "${DD_SCM_URL:-}" ] ; then
    form_values+=("source_code_management_uri=${DD_SCM_URL:-$(get_scm_url "$filename")}")
  fi

  "$NOOP" curl -X 'POST' \
    "${DD_SERVER_PROTO:-https}://${DD_SERVER_HOST}${DD_SERVER_PATH:-/api/v2/import-scan/}" \
    -H "accept: application/json" \
    -H "Content-Type: multipart/form-data" \
    -H "Authorization: Token ${DD_TOKEN}" \
    "${form_values[@]/#/-F }"
done
