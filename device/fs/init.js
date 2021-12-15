load('api_config.js');
load('api_gpio.js');
load('api_mqtt.js');

// Device identifier given by Google Cloud IoT Core
let device_id = Cfg.get('device.id');

// Topic to receive configuration
let config_topic = '/devices/' + device_id + '/config';

// Topic to publish state
let state_topic = '/devices/' + device_id + '/state';


// list of all pins
let pins = [0, // 0
			0,0,0,0,0,0,0,0,0,0, // 1-10
			0,0,0,0,0,0,0,0,0,0, // 11-20
			1,1,1,0,0,0,0,0,0,0 // 21-30
			];

// set all available pins to MODE_OUTPUT and value to 0
for(let i=0; i<pins.length; ++i) {
	if(pins[i]) {
		print("pin", i, "set to MODE_OUTPUT");
		GPIO.set_mode(i, GPIO.MODE_OUTPUT);
		print("pin", i, "is 0");
		GPIO.write(i, 0);
	}
}

print("Started with DeviceID: " + device_id);
print("Listening for configuration on: " + config_topic + " topic");


MQTT.sub(config_topic, function(conn, topic, msg) {
	
	print("Received a new configuration");

	let obj = JSON.parse(msg) || {};
	
	print("Configuraiton: ", obj);
	
	if(!obj.pins) {
		print('"pins" property is missing from configuration JSON');
		return;
	}
	
	let state = {
		pins: []
	};

	// create a copy of pins into all_pins
	let all_pins = [];
	for(let i=0; i<pins.length; ++i) {
		all_pins[i] = pins[i];
	}
	
	// set pins
	for(let i=0; i<obj.pins.length; ++i) {
		
		// pin object
		let pin = obj.pins[i];
		
		print("pin", pin.number, "is", pin.value);

		all_pins[pin.number] = 0; // it means we checked it

		GPIO.write(pin.number, pin.value);
		
		state.pins.push({
			number: pin.number,
			value: pin.value
		});
	}

	// set all not checked pins to 0
	for(let i=0; i<all_pins.length; ++i) {
		if(all_pins[i]) {
			print("pin", i, "is 0");
			GPIO.write(i, 0);
		}
	}
	
	// publish state
	let publish_message = JSON.stringify(state);
	print("Publishing state to ", state_topic, "topic with the following message:", publish_message);
	MQTT.pub(state_topic, publish_message, 1);

}, null);