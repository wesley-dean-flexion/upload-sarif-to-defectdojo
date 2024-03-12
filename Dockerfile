FROM alpine:3.19

ENV RUNNER="runner"

SHELL ["/bin/ash", "-o", "pipefail", "-c"]

RUN apk add --no-cache \
  bash=~5 \
  coreutils=~9 \
  curl=~8 \
  git=~2 \
  sed=~4 \
&& rm -rf /var/cache/apk/* \
&& ( getent passwd "${RUNNER}" || adduser -D "${RUNNER}" )

COPY ./upload_sarif_to_defectdojo.bash /
ENTRYPOINT ["/upload_sarif_to_defectdojo.bash"]

HEALTHCHECK NONE

USER "${RUNNER}"
