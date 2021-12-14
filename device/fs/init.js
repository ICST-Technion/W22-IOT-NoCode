load('api_config.js');
load('api_gpio.js');
load('api_mqtt.js');


let config_topic = '/devices/' + Cfg.get('device.id') + '/config';
let state_topic = '/devices/' + Cfg.get('device.id') + '/state';

let leds = {
	r:{pin:23, state:0}, g:{pin:22, state:0},b:{pin:21, state:0}
};

let dev_id = Cfg.get('device.id');
let led_keys = ["r", "g", "b"];

print("Started with DeviceID: " + dev_id);
print("Listening for configuration on: " + config_topic + " topic");

for(let i=0; i<led_keys.length; ++i) {  
	let led = led_keys[i];
	print("Setting the mode of pin ", leds[led].pin, " (", led, ") to MODE_OUTPUT");
	GPIO.set_mode(leds[led].pin, GPIO.MODE_OUTPUT);
}

MQTT.sub(config_topic, function(conn, topic, msg) {
	
	print("Received a new configuration");

	 let obj = JSON.parse(msg);
	  
	  if(obj) {
		  for(let i=0; i<led_keys.length; ++i) {  
			let led = led_keys[i];

			leds[led].state = obj[led];

			if(leds[led].state) {				
				print("Setting pin ", leds[led].pin, " (", led, ") ON");
			}
			else {
				print("Setting pin ", leds[led].pin, " (", led, ") OFF");
			}
			GPIO.write(leds[led].pin, leds[led].state);
		  }
		  
		  let publish_message = JSON.stringify({
			  r: leds.r.state,
			  g: leds.g.state,
			  b: leds.b.state
		  });
		  
		  print("Publishing state to ", state_topic, "topic with the following message:", publish_message);

		  MQTT.pub(state_topic, publish_message, 1);
	  }
	  else {
		 print("JSON parsing error: " + error);
	  }

}, null);