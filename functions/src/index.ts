import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import * as iot from "@google-cloud/iot";
const client = new iot.v1.DeviceManagerClient();

admin.initializeApp();

// On config change -> send to IoT core
exports.configUpdate = functions.region(functions.config().iot.core.region).firestore.document("board-configs/{boardId}")
    .onWrite(
        async (change: functions.Change<admin.firestore.DocumentSnapshot>, context: functions.EventContext) => {

          const boardId = context.params.boardId;

          if(!change.after.exists) {
            console.log(`The configuration of board ${boardId} has been deleted`);
            return;
          }

          console.log(`Sending a config update to board ${boardId}`);

          const data = change.after.data()
          const config = {
            "devices": data!.devices
          };

          const formattedName = client.devicePath(process.env.GCLOUD_PROJECT!, functions.config().iot.core.region, functions.config().iot.core.registry, boardId);
          const dataValue = Buffer.from(JSON.stringify(config)).toString("base64");

          return client.modifyCloudToDeviceConfig({
          	name: formattedName,
          	binaryData: dataValue
          });
        }
);

// on state update -> update DB
exports.stateUpdate = functions.region(functions.config().iot.core.region).pubsub.topic(functions.config().iot.core.topic).onPublish(async (message: functions.pubsub.Message) => {

    const boardId = message.attributes.deviceId;
    await admin.firestore().collection('boards').doc(boardId).update({
      "devices": message.json.devices
    });
});

// on sensor data -> update DB
exports.sensorDataUpdate = functions.region(functions.config().iot.core.region).pubsub.topic(functions.config().iot.core.sensor_topic).onPublish(async (message: functions.pubsub.Message) => {

    const boardId = message.attributes.deviceId;
    const sensor_data = message.json.data;
    const sensor_name = message.json.name;

    console.log(`Received data from "${sensor_name}" sensor of "${boardId}" board`);
    var devices = await (await admin.firestore().collection('sensors').doc(boardId).get()).get('devices');

    var i;
    for(i=0; i<devices.length; ++i) {
      if(devices[i].name == sensor_name) {
        devices[i].data = devices[i].data.concat(sensor_data).slice(-10); // keep 10 values
        break;
      }
    }

    if(i == devices.length) {
      devices.push({
        "data": sensor_data,
        "name": sensor_name
      });
    }

    await admin.firestore().collection('sensors').doc(boardId).update({
      "devices": devices
    });
});

// on pending -> check device
exports.pendingUpdate = functions.region(functions.config().iot.core.region).firestore.document("pending/{device}").onWrite(async(change: functions.Change<admin.firestore.DocumentSnapshot>, context: functions.EventContext) => {

  const deviceId = context.params.device;

  // Verify this is either a create or update
  if (!change.after.exists) {
    console.log(`Pending device removed for ${deviceId}`);
    return;
  }

  console.log(`Pending device created for ${deviceId}`);
  const pending = change.after.data();

  try {
    // Verify device does NOT already exist in Firestore
    const deviceRef = admin.firestore().doc(`boards/${deviceId}`);
    const deviceDoc = await deviceRef.get();

    if (deviceDoc.exists) {
      throw new Error(`${deviceId} is already registered to another user`);
    }

    // Verify device exists in IoT Core
    const result = await getDevice(deviceId);

    // Verify the device public key
    verifyDeviceKey(pending, result.credentials[0].publicKey!.key!.trim());

    const batch = admin.firestore().batch();

    // Insert valid device for the requested owner
    const device = {
      id: pending!.serial_number,
      owner: pending!.owner,
      devices: []
    };

    batch.set(deviceRef, device);

    // Generate a default configuration
    const configRef = admin.firestore().doc(`board-configs/${deviceId}`);
    const config = {
      id: pending!.serial_number,
      owner: pending!.owner,
      devices: []
    };
    batch.set(configRef, config);


    // Generate a default sensors document
    const sensorsRef = admin.firestore().doc(`sensors/${deviceId}`);
    const sensors = {
      id: pending!.serial_number,
      owner: pending!.owner,
      devices: []
    };
    batch.set(sensorsRef, sensors);

    // Remove the pending device entry
    batch.delete(change.after.ref);

    await batch.commit();
    console.log(`Added device ${deviceId} for user ${pending!.owner}`);
  } catch (error) {
    // Device does not exist in IoT Core or key doesn't match
    console.error('Unable to register new device', error);
    change.after.ref.delete();
  }

});

/**
 * Return a Promise to obtain the device from Cloud IoT Core
 */
function getDevice(deviceId: any): Promise<any> {
  return new Promise(async (resolve: any, reject: any) => {

    const projectId = await client.getProjectId();

    const devicePath = client.devicePath(
      projectId,
      functions.config().cloudiot.region,
      functions.config().cloudiot.registry,
      deviceId
    );

    const [response] = await client.getDevice({
      name: devicePath,
    });

    resolve(response);

  });
}

/**
 * Validate that the public key provided by the pending device matches
 * the key currently stored in IoT Core for that device id.
 *
 * Method throws an error if the keys do not match.
 */
function verifyDeviceKey(pendingDevice: any, deviceKey: string) {
  // Convert the pending key into PEM format
  const chunks = pendingDevice.public_key.match(/(.{1,64})/g);
  chunks.unshift('-----BEGIN PUBLIC KEY-----');
  chunks.push('-----END PUBLIC KEY-----');
  const pendingKey = chunks.join('\n');

  if (deviceKey !== pendingKey) throw new Error(`Public Key Mismatch:\nExpected: ${deviceKey}\nReceived: ${pendingKey}`);
}

