# IOT No Code
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
	
	Go to "Registry details" and under "Cloud Pub/Sub topics" make sure "iot-topic" is your device state topic.
	
* Create PubSub subscription for board's data:

	`gcloud pubsub subscriptions create --topic iot-topic iot-subscription`

* Create PubSub topic for sensor's live data (telemetry):
	
	`gcloud pubsub topics create sensor-data`
	
	Go to "Registry details" and under "Cloud Pub/Sub topics" make sure "sensor-data" is your default telemetry topic.

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
* mos put fs/init.js sends the updated .js code to the device - should be called on each change we want to send. A reboot needs to be done in order to make the device run the new code.
* mos call Sys.Reboot - restarts the device with the updated code
* mos wifi <SSID> <password> - setups the wifi on the device and reboots it. Write your wifi SSID and the password instead if "<SSID>" and "<password>".


## Device configurations JSON
### State update
The cloud will send configuration updates to the following topic:

`/devices/<device id>/config`

And the device should respond with a corresponding state update to the following topic:

`/devices/<device id>/state`

The configuration is in the following format:

```
config/state = {
	"devices": [... list of devices ...]
}
```
Where each device has the following attributes:
```
{
	"name": string,
	"active": 0 or 1,
	"pins": [... list of pins ...],
	"type": string
}
```

And each pin is in the following format:

```
{
	name: string,
	number: int,
	value: 0 or 1
}
```

If a pin is missing from the config JSON it will be turned off on the device.

### Sensors telemetry data updates
Sensors report data in the following format:
```
{
	name: string,
	data: []
}
```	
Where the data is comprised form the following attributes :
```
{
	time: date-"T"-hour-minute-seconds-"Z" (e.g: 2022-02-16T18:04:24Z),
	value: int
}
```
The data is saved in a different collection named "sensors", and the 10 most recent records are stored in the collection.
These records are displayed in a graph in the sensor's screen.

## Create database
Run `gcloud app create --region=europe-west`
And then `gcloud alpha firestore databases create --project=iot-project-b52bb --region=europe-west`

Use `./functions_deploy` script to deploy the functions

## Troubleshoot
### Google sign-in succeed but the app's login proccess gets stuck and the following exception appears in the "run" terminal of android studio:
#### [ERROR:flutter/lib/ui/ui_dart_state.cc(209)] Unhandled Exception: PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10: , null, null)
### Solution:
You need to create a fingerprint in the firebase console. Go to "Project Setting" and click on "Add fingerprint". Create a SHA1 key by using a tool named "Keytool" which is built-in in windows and linux.
In Windows:
Open the CMD, if keytool is not included in your PATH, go to your JAVA folder in either program files or program files (x86). Search for Keytool and change your CMD current directory to this folder. run the following command:
keytool -list -v -alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore
In Linux/UNIX:
run the following command:
keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore
enter the password: "android", copy the SHA1 key and paste it firebase fingerprint.

### Google services.json is missing
### Solution:
You need to download this file from the firebase console. Go to "Project Setting" and click on the button google services.json.
Save this file under the path: ***your project path***\App\android\app


### The esp gets stuck in a loop and emits his dump file to the console
### Solution:
You probably have a compilation error in init.js that made the esp crash. You need to replace it to a stable version, and execute the following commands:
- mos build
- mos flash

### The library you added to init.js does not work
### Solution:
Lets say your tried to inculde adc library by using this command: load('api_adc.js').
Please make sure you also added the url of the library in your mos.yml file:
"- location: https://github.com/mongoose-os-libs/adc"
