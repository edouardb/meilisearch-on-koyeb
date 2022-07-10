#!/bin/sh

if [[  -z "${WRITE_INSTANCE}" && -z "${KOYEB_TOKEN}" ]]; then
  echo "Environment variable KOYEB_TOKEN is undefined."
  exit 1
fi

if [[ -z "${WRITE_INSTANCE}" && -z "${KOYEB_APP_SERVICE_SLUG}" ]]; then
  echo "Environment variable KOYEB_APP_SERVICE_SLUG is undefined. Should be set to the slug of the Koyeb app and service, i.e. my-app/my-service."
  exit 1
fi

if [[ -z "${BUCKET_NAME}" ]]; then
  echo "Environment variable BUCKET_NAME is undefined."
  exit 1
fi

if [[ -z "${RCLONE_CONFIG_NAME}" ]]; then
  echo "Environment variable RCLONE_CONFIG_NAME is undefined."
  exit 1
fi

rclone copy ${RCLONE_CONFIG_NAME}:${BUCKET_NAME}/data.ms.snapshot /meilisearch-on-koyeb/snapshots
/usr/bin/supervisord -c /etc/supervisord.conf