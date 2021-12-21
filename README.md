# Smart home
## Setup Google Iot Core
* Install [gcloud command line tool](https://cloud.google.com/sdk/gcloud/)
* Authenticate with Google Cloud:
	
	`gcloud auth application-default login`
* Create cloud project - choose your unique project name:
	
	` gcloud projects create IOT-project `

	(**IOT-project** is our project name)
* Add permissions for IoT Core (so a cloud function would be able to publish):

	`gcloud projects add-iam-policy-binding IOT-project --member=serviceAccount:cloud-iot@system.gserviceaccount.com --role=roles/pubsub.publisher`

* Set default values for gcloud:

	`gcloud config set project YOUR_PROJECT_ID`
* Create PubSub topic for device data:
	
	`gcloud pubsub topics create iot-topic`

* Create PubSub subscription for device data:
	
	`gcloud pubsub subscriptions create --topic iot-topic iot-subscription`

* Create device registry:
	
	`gcloud iot registries create iot-registry --region europe-west1 --event-notification-config=topic=iot-topic`

## Setup device
* Get project ID of your new project and then run the following command in mos:

	`mos gcp-iot-setup --gcp-project YOUR_PROJECT_ID --gcp-region europe-west1 --gcp-registry iot-registry`


## Some tips when working with Mongoose
* mos build - builds the base javascript engine - should be done only once
* mos flash - sends the engine to the device
* mos gcp-iot-setup - registers the device with Google and sends the certificate to the device
* mos put fs/init.js sends the updated .js code to the device - should be called on each change we want to send
* mos call Sys.Reboot - restarts the device with the updated code
* mos wifi - setups the wifi on the device and reboots it


## Device configuration JSON
The cloud will send configuration updates to the following topic:

`/devices/<device id>/config`

And the device should respond with a corresponding state update to the following topic:

`/devices/<device id>/state`

The configuration is of the following format:

```
config/state = {
	"pins": [... list of pins ...]
}
```

Each pin is of the following format:

```
{
	number: int,
	value: bool
}
```

If a pin is missing from the config JSON it will be turned off on the device.


