FROM alpine:3.19

RUN apk add --no-cache \
  bash=~5 \
  coreutils=~9 \
  curl=~8 \
  git=~2 \
  sed=~4 \
&& rm -rf /var/cache/apk/*

COPY ./upload_sarif_to_defectdojo.bash /
ENTRYPOINT ["/upload_sarif_to_defectdojo.bash"]

LABEL org.opencontainers.image.source=https://github.com/wesley-dean-flexion/
LABEL org.opencontainers.image.description="Upload SARIF to Defect Dojo"
