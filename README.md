## About this project

This is an example project that allows running multiple instances of Meilisearch on Koyeb using Meilisearch snapshots to keep instances up-to-date.

To successfully run this project on Koyeb you will need to deploy two services:

- One acting as the write instance: This service will be used to create indexes and documents
- The second Acting as the search instance(s) you can scale horizontally and automatically sync with the snapshots generated from the write instance

The write instance service will create a snapshot of the Meilisearch database at a regular interval and save it to a remote object storage platform using Rclone. In this example, we will use Google Cloud Storage as the object storage platform to save the Meilisearch snapshots.

The search instance(s) service will re-fetch the latest snapshot available at a regular interval and create a new Koyeb deployment of the service to use the latest snapshot version. This allows to get zero-downtime while using the latest snapshots as your current service deployment will stay alive until the new one becomes healthy.

## Deploy the project

We will explain how to deploy this project on Koyeb using the Koyeb CLI. If you don't have the CLI installed yet on your machine, check out the [Koyeb CLI](https://www.koyeb.com/docs/quickstart/koyeb-cli) get started.

In this example, we will use Google Cloud Storage to store the Meilisearch snapshots. We consider you already:

- Created a bucket on Google Cloud Storage
- Created a Service Account with the permissions to read and write into the bucket
- Downloaded the Service Account credentials JSON file

You will also need a Koyeb access token to log in to the Koyeb CLI and to be able to perform the redeploy action on the search instance(s) service. You can create a new one by going to the [API section](https://app.koyeb.com/account/api) of the control panel. Take care to save the token in a secure place, you will need it to deploy the search instance(s) service.


### Create a Koyeb secret to store your Google Cloud Service Account credentials and Koyeb access token

To securely store your Google Cloud Service Account credentials, we will create a new Koyeb secret.
Take care to replace the path and filename of the credentials JSON file with your own.

```bash
cat path/to/your/google-cloud-service-account-credentials.json | koyeb secret create gcs-credentials --value-from-stdin
```

Create another secret to store your Koyeb access token by running

```bash
koyeb secret create koyeb-api-token
```

When you are prompted to add the value, enter your Koyeb access token.

### Create a new Koyeb app

Create a new Koyeb app we will deploy our two Meilisearch services, the write instance and the search instance(s) services.

```bash
koyeb app create my-app
```

> Note: You can replace the `my-app` value with the name you want to use for your app.

### Create a new Koyeb service to run the Meilisearch write instance service

To create the Koyeb service that will act as our Meilisearch write instance, run the following command and
replace values between `<>` with your own values.

```bash
koyeb service create -a my-app \
  meilisearch-write-instance \
  --docker ghcr.io/edouardb/meilisearch-on-koyeb \
  --ports 7700:http \
  --routes /:7700 \
  --env MEILI_SNAPSHOT_INTERVAL_SEC=60 \
  --env MEILI_SCHEDULE_SNAPSHOT=1 \
  --env RCLONE_CONFIG_REMOTE_BUCKET_POLICY_ONLY=true \
  --env RCLONE_CONFIG_REMOTE_TYPE=gcs \
  --env RCLONE_CONFIG_NAME=remote \
  --env WRITE_INSTANCE=true \
  --env RCLONE_CONFIG_REMOTE_SERVICE_ACCOUNT_CREDENTIALS=@gcs-credentials \
  --env BUCKET_NAME=<YOUR_GCS_BUCKET_NAME>
  --env MEILI_MASTER_KEY=<YOUR_MEILISEARCH_MASTER_KEY>
```

- MEILI_SNAPSHOT_INTERVAL_SEC: Defines time interval, in seconds, between each snapshot creation
- MEILI_SCHEDULE_SNAPSHOT: Activate snapshot scheduling
- RCLONE_CONFIG_REMOTE_TYPE: Defines the remote type to use for the snapshots, here `gcs`
- RCLONE_CONFIG_REMOTE_SERVICE_ACCOUNT_CREDENTIALS: Defines the Google Cloud Service Account credentials to use to access the Google Cloud Storage bucket, here set to the Koyeb secret value we created previously `@gcs-credentials`
- BUCKET_NAME: The bucket name Meilisearch snapshots will be stored
- RCLONE_CONFIG_NAME: The name of the Rclone configuration to use, here `remote`
- WRITE_NODE: Indicate to run the container as a write instance. This will create a snapshot of the Meilisearch database at a regular interval and save it to the Google Cloud Storage bucket.
- MEILI_MASTER_KEY: The Meilisearch master key to use to access Meilisearch.

### Create a new Koyeb service to run the search instance(s)

To create the Koyeb service that will act as our Meilisearch search instance(s), run the following command and
replace values between `<>` with your own values.

```bash
koyeb service create -a my-app \
  --name meilisearch-search-instance \
  --docker ghcr.io/edouardb/meilisearch-on-koyeb \
  --ports 7700:http \
  --routes /search:7700 \
  --env RCLONE_CONFIG_REMOTE_BUCKET_POLICY_ONLY=true \
  --env RCLONE_CONFIG_REMOTE_TYPE=gcs \
  --env RCLONE_CONFIG_REMOTE_SERVICE_ACCOUNT_CREDENTIALS=@gcs-credentials \
  --env BUCKET_NAME=meilitest-bucket \
  --env RCLONE_CONFIG_NAME=remote \
  --env KOYEB_TOKEN=@koyeb-api-token \
  --env KOYEB_APP_SERVICE_SLUG=<YOUR_KOYEB_APP_NAME/YOUR_KOYEB_SERVICE_NAME>
  --env MEILI_MASTER_KEY=<YOUR_MEILISEARCH_MASTER_KEY>
```

- RCLONE_CONFIG_REMOTE_TYPE: Defines the remote type to use for the snapshots, here `gcs`
- RCLONE_CONFIG_REMOTE_SERVICE_ACCOUNT_CREDENTIALS: Defines the Google Cloud Service Account credentials to use to access the Google Cloud Storage bucket, here set to the Koyeb secret value we created previously `@gcs-credentials`
- BUCKET_NAME: The bucket name Meilisearch snapshots will be stored
- RCLONE_CONFIG_NAME: The name of the Rclone configuration to use, here `remote`
- KOYEB_TOKEN: The Koyeb token to use to authenticate with the Koyeb API
- KOYEB_APP_SERVICE_SLUG: The slug of the Koyeb app and service to redeploy when a new snapshot is available, here `my-app/meilisearch-search-instance`
- MEILI_MASTER_KEY: The Meilisearch master key to use to access Meilisearch.

## Try it

1. Download `wget https://docs.meilisearch.com/movies.json`

2. Create new index on the write instance

```
curl \
  -X POST 'http://<YOUR_KOYEB_APP>/indexes/movies/documents' \
  -H 'Content-Type: application/json' \
  --data-binary @movies.json
```

3. Go to http://<YOUR_KOYEB_APP>/ you will see your index

4. In a few minutes index will be synced on search instance(s) http://<YOUR_KOYEB_APP>/search


