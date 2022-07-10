#/bin/sh

if [[ ! -z "${WRITE_INSTANCE}" ]]; then
  echo "Syncing local meilisearch snapshot to remote bucket..."
  rclone copy /meilisearch-on-koyeb/snapshots/data.ms.snapshot ${RCLONE_CONFIG_NAME}:${BUCKET_NAME}
else 
  /meilisearch-on-koyeb/koyeb --token ${KOYEB_TOKEN} service redeploy ${KOYEB_APP_SERVICE_SLUG}
fi