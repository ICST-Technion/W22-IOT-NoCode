# Smart home
## Setup Google Iot Core
* Install [gcloud command line tool](https://cloud.google.com/sdk/gcloud/)
* Authenticate with Google Cloud:
	
	`gcloud auth application-default login`
* Create cloud project - choose your unique project name:
	
	` gcloud projects create IOT-project `

	(**IOT-project** is our project name)
* Add permissions for IoT Core:

	`gcloud projects add-iam-policy-binding IOT-project --member=serviceAccount:cloud-iot@system.gserviceaccount.com --role=roles/pubsub.publisher`

* Set default values for gcloud:

	`gcloud config set project IOT-project`
* Create PubSub topic for device data:
	
	`gcloud pubsub topics create iot-topic`

* Create PubSub subscription for device data:
	
	`gcloud pubsub subscriptions create --topic iot-topic iot-subscription`

* Create device registry:
	
	`gcloud iot registries create iot-registry --region europe-west1 --event-notification-config=topic=iot-topic`

## Setup device
* Get project ID of your new project:
	
	`gcloud projects list`

* Register device on Google IoT Core. If a device is already registered, this command deletes it, then registers again. Note that this command is using YOUR_PROJECT_ID instead of YOUR_PROJECT_NAME. Take the project ID from the result of your previous command:

	`mos gcp-iot-setup --gcp-project YOUR_PROJECT_ID --gcp-region europe-west1 --gcp-registry iot-registry`