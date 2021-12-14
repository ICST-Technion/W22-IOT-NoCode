load('api_config.js');
load('api_gpio.js');
load('api_mqtt.js');


let config_topic = '/devices/' + Cfg.get('device.id') + '/config';
let state_topic = '/devices/' + Cfg.get('device.id') + '/state';

let state = {
	pins: []
};

for(let i=0; i<30; ++i) {
	state.pins[i] = 0;
}


print("Started with DeviceID: " + Cfg.get('device.id'));
print("Listening for configuration on: " + config_topic + " topic");

for(let i=21; i<=23; ++i) {  
	print("Setting pin ",i, "to MODE_OUTPUT");
	GPIO.set_mode(i, GPIO.MODE_OUTPUT);
	state.pins[i] = 0;
	GPIO.write(i, 0);
}


MQTT.sub(config_topic, function(conn, topic, msg) {
	
	print("Received a new configuration");

	let obj = JSON.parse(msg) || {};
	
	print("Configuraiton: ", obj);
	
	if(!obj.pins) {
		print('"pins" property is missing fron configuration JSON');
		return;
	}
	
	let new_state = {
		pins: []
	};
	
	// update existing pins
	for(let i=0; i<obj.pins.length; ++i) {
		
		// new state
		let pin = obj.pins[i];
		let found = 0;
		
		print("Updating pin", pin.number, "from", state.pins[pin.number], "to", pin.value);
		state.pins[pin.number] = pin.value;
		GPIO.write(pin.number, pin.value);
		
		new_state.pins.push({
			number: pin.number,
			value: pin.value
		});
		
	}

	// removing unused pins (that existed in state and now do not)
	for(let j=21; j<=23; ++j) {
		
		let state_pin = state.pins[j];
		let found = 0;
		
		for(let i=0; i<obj.pins.length; ++i) {
			let pin_number = obj.pins[i].number;
			
			if(pin_number === j) {
				found = 1;
				break;
			}
		}
		
		if(!found) {
			GPIO.write(j, 0);
			print("Removing pin", j);
		}
	}
	
	state = new_state;
	
	let publish_message = JSON.stringify(state);
	print("Publishing state to ", state_topic, "topic with the following message:", publish_message);
	MQTT.pub(state_topic, publish_message, 1);

}, null);