import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import * as iot from "@google-cloud/iot";
const client = new iot.v1.DeviceManagerClient();

admin.initializeApp();

// On config change -> send to IoT core
exports.configUpdate = functions.region(functions.config().iot.core.region).firestore.document("board-configs/{boardId}")
    .onWrite(
        async (change: functions.Change<admin.firestore.DocumentSnapshot>, context?: functions.EventContext) => {
          if (context) {
            console.log(context.params.boardId);

            const data = change.after.data()
            const config = data!.config

            const formattedName = client.devicePath(process.env.GCLOUD_PROJECT!, functions.config().iot.core.region, functions.config().iot.core.registry, context.params.boardId);
            const dataValue = Buffer.from(JSON.stringify(config)).toString("base64");

            return client.modifyCloudToDeviceConfig({ 
            	name: formattedName,
            	binaryData: dataValue
            });

          } else {
            throw (Error("no context from trigger"));
          }
        }
    );

// on state update -> update DB
exports.stateUpdate = functions.region(functions.config().iot.core.region).pubsub.topic(functions.config().iot.core.topic).onPublish(async (message: functions.pubsub.Message) => {

    const boardId = message.attributes.deviceId;
    await admin.firestore().collection('boards').doc(boardId).update({
      "state": message.json
    })
  });

// on pending -> check device
exports.pendingUpdate = functions.region(functions.config().iot.core.region).firestore.document("pending/{device}").onWrite(async(change, context) => {

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

    if (deviceDoc.exists) throw new Error(`${deviceId} is already registered to another user`);

    // Verify device exists in IoT Core
    const result = await getDevice(deviceId);

    // Verify the device public key
    verifyDeviceKey(pending, result.credentials[0].publicKey!.key!.trim());

    const batch = admin.firestore().batch();

    // Insert valid device for the requested owner
    const device = {
      id: pending!.serial_number,
      owner: pending!.owner,
    };

    batch.set(deviceRef, device);

        // Generate a default configuration
    const configRef = admin.firestore().doc(`board-configs/${deviceId}`);
    const config = {
      owner: pending!.owner,
      value: []
    };
    batch.set(configRef, config);

    // Remove the pending device entry
    batch.delete(change.after.ref);

    await batch.commit();
    console.log(`Added device ${deviceId} for user ${pending!.owner}`);
  } catch (error) {
    // Device does not exist in IoT Core or key doesn't match
    console.error('Unable to register new device', error);
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

