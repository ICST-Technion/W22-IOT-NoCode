import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import * as iot from "@google-cloud/iot";
const client = new iot.v1.DeviceManagerClient();

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
