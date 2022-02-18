/**
 * This file implements all cloud of the functions that are required for the project.
 */

import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import * as iot from "@google-cloud/iot";


// Create Google IoT core device manager client
const client = new iot.v1.DeviceManagerClient();

// Initialize Firebase Admin
admin.initializeApp();


/**
 * Triggerd on a configuration update of a specific board in Firestore.
 * When a configuration is being updated, this function sends it directly to the device as an IoT configuration update (as an MQTT message).
 */
exports.configUpdate = functions.region(functions.config().iot.core.region).firestore.document("board-configs/{boardId}")
    .onWrite(
        async (change: functions.Change<admin.firestore.DocumentSnapshot>, context: functions.EventContext) => {

          const boardId = context.params.boardId;

          // Because board deletion also triggers this function, we handle it with the following condition
          if(!change.after.exists) {
            console.log(`The configuration of board ${boardId} has been deleted`);
            return;
          }

          console.log(`Sending a config update to board ${boardId}`);

          // New configuration data
          const data = change.after.data()

          // Relevant configuration for the board
          const config = {
            "devices": data!.devices
          };

          // Get the full IoT-core device path of the board
          const formattedName = client.devicePath(process.env.GCLOUD_PROJECT!, functions.config().iot.core.region, functions.config().iot.core.registry, boardId);

          // Stringify the config and encode it in base64 - as required
          const dataValue = Buffer.from(JSON.stringify(config)).toString("base64");

          // Send the IoT-core configuration though MQTT
          return client.modifyCloudToDeviceConfig({
          	name: formattedName,
          	binaryData: dataValue
          });
        }
);

/**
 * Triggerd on a state update of a specific board in IoT-core.
 */
exports.stateUpdate = functions.region(functions.config().iot.core.region).pubsub.topic(functions.config().iot.core.topic).onPublish(async (message: functions.pubsub.Message) => {

    // Get board ID from the MQTT message attributes
    const boardId = message.attributes.deviceId;

    // Update the relevant board's state document according to the received MQTT state
    await admin.firestore().collection('boards').doc(boardId).update({
      "devices": message.json.devices
    });
});

/**
 * Triggered on a new sensor data (sent to the telemetry MQTT topic).
 * When the sensor data received, the function updates the relevant sensor device's data in the sensors collection
 */
exports.sensorDataUpdate = functions.region(functions.config().iot.core.region).pubsub.topic(functions.config().iot.core.sensor_topic).onPublish(async (message: functions.pubsub.Message) => {

    const boardId = message.attributes.deviceId;
    const sensor_data = message.json.data;
    const sensor_name = message.json.name;

    // Maximum sensor data to keep
    const sensor_data_limit: Number = functions.config().iot.core.sensor_data_limit;

    console.log(`Received data from "${sensor_name}" sensor of "${boardId}" board`);

    // Get all devices of the given board
    var devices = await (await admin.firestore().collection('sensors').doc(boardId).get()).get('devices');

    var i;
    for(i=0; i<devices.length; ++i) {
      if(devices[i].name == sensor_name) {

        // Add the new data to the relevant device and keep only "sensor_data_limit" of them
        devices[i].data = devices[i].data.concat(sensor_data).slice(-sensor_data_limit);
        break;
      }
    }

    // If the deivce does not exists, create it
    if(i == devices.length) {
      devices.push({
        "data": sensor_data,
        "name": sensor_name
      });
    }

    // Update DB
    await admin.firestore().collection('sensors').doc(boardId).update({
      "devices": devices
    });
});

/**
 * Triggered when there is a change in the pending boards collection
 * If a new board added, this function will check if it is registered in IoT core and will vailidate its key.
 * Also it will check if the board isn't owned by another user.
 */
exports.pendingUpdate = functions.region(functions.config().iot.core.region).firestore.document("pending/{device}").onWrite(async(change: functions.Change<admin.firestore.DocumentSnapshot>, context: functions.EventContext) => {

  // Board's ID
  const boardId = context.params.device;

  // If the b oard is removed, do nothing
  if (!change.after.exists) {
    console.log(`Pending board removed for ${boardId}`);
    return;
  }

  console.log(`Pending board created for ${boardId}`);
  const pending = change.after.data();

  try {

    // Verify that the board does NOT already exist in Firestore
    const boardRef = admin.firestore().doc(`boards/${boardId}`);
    const boardDoc = await boardRef.get();

    if (boardDoc.exists) {
      throw new Error(`${boardId} is already registered to another user`);
    }

    // Verify board exists in IoT Core
    const result = await getBoard(boardId);

    // Verify the board's public key
    verifyBoardKey(pending, result.credentials[0].publicKey!.key!.trim());

    const batch = admin.firestore().batch();

    // Insert valid board for the requested owner
    const board = {
      id: pending!.serial_number,
      owner: pending!.owner,
      devices: []
    };

    // Set board
    batch.set(boardRef, board);

    // Set board config
    const configRef = admin.firestore().doc(`board-configs/${boardId}`);
    const config = {
      id: pending!.serial_number,
      owner: pending!.owner,
      devices: []
    };
    batch.set(configRef, config);


    // Set board sensors document
    const sensorsRef = admin.firestore().doc(`sensors/${boardId}`);
    const sensors = {
      id: pending!.serial_number,
      owner: pending!.owner,
      devices: []
    };

    batch.set(sensorsRef, sensors);

    // Remove the pending board entry
    batch.delete(change.after.ref);

    await batch.commit();
    console.log(`Added board ${boardId} for user ${pending!.owner}`);
  } catch (error) {
    // The board does not exist in IoT Core or key doesn't match
    console.error('Unable to register new board', error);
    change.after.ref.delete();
  }

});

/**
 * Return a Promise to obtain the device from Cloud IoT Core
 */
function getBoard(deviceId: any): Promise<any> {
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
function verifyBoardKey(pendingDevice: any, deviceKey: string) {
  // Convert the pending key into PEM format
  const chunks = pendingDevice.public_key.match(/(.{1,64})/g);
  chunks.unshift('-----BEGIN PUBLIC KEY-----');
  chunks.push('-----END PUBLIC KEY-----');
  const pendingKey = chunks.join('\n');

  if (deviceKey !== pendingKey) throw new Error(`Public Key Mismatch:\nExpected: ${deviceKey}\nReceived: ${pendingKey}`);
}

