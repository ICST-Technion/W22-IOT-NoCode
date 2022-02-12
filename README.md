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
* Create PubSub topic for board's data (state/config):
	
	`gcloud pubsub topics create iot-topic`

* Create PubSub subscription for board's data:
	
	`gcloud pubsub subscriptions create --topic iot-topic iot-subscription`

* Create PubSub topic for sensor's live data (telemetry):
	
	`gcloud pubsub topics create sensor-data`

* Create PubSub subscription for sensor's live data:
	
	`gcloud pubsub subscriptions create --topic sensor-data sensor-data-subscription`

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


## Create database
Run `gcloud app create --region=europe-west`
And then `gcloud alpha firestore databases create --project=iot-project-b52bb --region=europe-west`

Use `./functions_deploy` script to deploy the functions


## Tasks to do
- [x] Send configuration and receive state between IoT core and the ESP32
- [x] Sign-in with Google
- [x] Add device (QR code)
- [ ] Feature: Device window
- [ ] BONUS: Setup device WIFI through Bluethooth (in the "add device" screen)
- [ ] Improvement: Make cloud functions more typed
- [x] BUG: If device already exists, make sure to remove the "pending" records
screen


## Troubleshoot
- Google sign-in succeed but the login proccess to the app gets stuck and the exection:
[ERROR:flutter/lib/ui/ui_dart_state.cc(209)] Unhandled Exception: PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10: , null, null)
appears in the "run" terminal of android studio.
- Solution:
You need to create a fingerprint in the firebase console. Go to "Project Setting" and click on "Add fingerprint". Create a SHA1 key by using a tool named "Keytool" which is built-in in windows and linux.
In Windows:
Open the CMD, if keytool is not included in your PATH, go to your JAVA folder in either program files or program files (x86). Search for Keytool and change your CMD current directory to this folder. run the following command:
keytool -list -v -alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore
In Linux/UNIX:
run the following command:
keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore
enter the password: "android", copy the SHA1 key and paste it firebase fingerprint.

- Google services.json is missing
- Solution: You need to download this file from the firebase console. Go to "Project Setting" and click on the button google services.json.
Save this file under the path: ***your project path***\App\android\app
