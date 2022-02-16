load('api_config.js');
load('api_gpio.js');
load('api_mqtt.js');
load('api_pwm.js');
load('api_timer.js');
load('api_adc.js');


// Device identifier given by Google Cloud IoT Core
let device_id = Cfg.get('device.id');

// Topic to receive configuration
let config_topic = '/devices/' + device_id + '/config';

// Topic to publish state
let state_topic = '/devices/' + device_id + '/state';

// Topic to publish sensor-data
let sensor_data_topic = '/devices/' + device_id + '/events';

//PWM settings
let min_duty = 0.05;
let max_duty = 0.1;
let pwm_freq = 50;

/* list of all pins
0 - not used
1 - Digital output (LED)
2 - PWM output (Servo)
3 - Analog input (Sensor)
*/
let pins = [0, // 0
			0,0,0,0,0,0,0,0,0,0, // 1-10
			0,0,0,0,0,0,0,2,0,0, // 11-20
			1,1,1,0,0,0,0,0,0,0, // 21-30
			0,0,0,3,0,0,0,0,0 // 31-39
			];

//ADC1 pins(Analog to digital converter - channel 1) - for sensors
let ADC1_pins = [32,33,34,35,36,39];

//ADC2 pins(Analog to digital converter - channel 2) 
let ADC2_pins = [0,2,4,12,13,14,15,25,26,27];

//DAC pins (Digital to analog pins)
let DAC_pins = [25,26];

//General perpose pins (input + output) - for LEDs and servo engines
let general_pins = [16,17,18,19,21,22,23,25,26,27,32,33];

//time interval for the sensor's timer 
let time_interval = 10000;

//timers list
let timers_list = [];

// set default values on boot
for(let i=0; i<pins.length; ++i) {
	if(pins[i]===1) {
		print("pin", i, "set to MODE_OUTPUT");
		GPIO.set_mode(i, GPIO.MODE_OUTPUT);
		print("pin", i, "is 0");
		GPIO.write(i, 0);
	}else if(pins[i]===2){
		print("pin", i, "PWM");
		PWM.set(i, pwm_freq, min_duty);
	}else if(pins[i]===3){
		print("pin", i, "ADC");
	}
}

print("Started with DeviceID: " + device_id);
print("Listening for configuration on: " + config_topic + " topic");


//handles the configuration received from the cloud and reports state back to the cloud
MQTT.sub(config_topic, function(conn, topic, msg) {
	
	print("Received a new configuration");
	
	//parsing the message and checking whether it's valid 
	if(msg !== ""){
		let obj = JSON.parse(msg) || {};
		print("Configuraiton: ", obj);
		if(!obj.devices) {
			print('"devices" property is missing from configuration JSON');
			return;
		}
		for(let j=0; j < obj.devices.length; ++j){
			if(!obj.devices[j].name) {
				print('"name" property is missing from configuration JSON');
				return;
			}	
			if(!obj.devices[j].type) {
				print('"type" property is missing from configuration JSON');
				return;
			}
			if(!obj.devices[j].pins) {
				print('"pins" property is missing from configuration JSON');
				return;
			}
			for(let k=0; k < obj.devices[j].pins.length; ++k){
				if(!obj.devices[j].pins[k].name) {
					print('"pin.name" property is missing from configuration JSON');
					return;
				}
			}
		}
		print("Succeed");
		
		// create a copy of pins into all_pins
		let all_pins = [];
		for(let i=0; i<pins.length; ++i) {
			all_pins[i] = pins[i];
		}
	
		//builds the state to report and update the new cofig we received
		let state = {
			devices: []
		};
		//Devices
		for(let j=0; j<obj.devices.length; ++j){
			state.devices[j] = {
				name: obj.devices[j].name,
				active: obj.devices[j].active,
				type: obj.devices[j].type,
				pins: []
			};
			//Device's pins
			for(let i=0; i<obj.devices[j].pins.length; ++i) {
			
				// pin object
				let pin = obj.devices[j].pins[i];
				print("pin", pin.number, "is", pin.value);

				all_pins[pin.number] = 0; // it means we checked it
				if(pins[pin.number] === 1){
					GPIO.write(pin.number, pin.value);
				}
				else if(pins[pin.number] === 2){
					let res = min_duty +(pin.value /180.0) * (max_duty - min_duty);
					print("result: " ,res);
					print("pin: " ,pin.number);
					PWM.set(pin.number, pwm_freq, res);
				}
				
				else if(pins[pin.number] === 3){
					//checking if we want to deactivate the sensor
					if(obj.devices[j].active === 0){
						for(let z=0; z<timers_list.length; z++){
							if(timers_list[z].timer_pin_number === pin.number){
								Timer.del(timers_list[z].timer_id);
								print("Timer deleted");
								timers_list.splice(z,1);
								break;
							}
						}
					}
					
					else{
						//it means we want the sensor to be active
						let found =0;
						for(let z=0; z<timers_list.length; z++){
							if(timers_list[z].timer_pin_number === pin.number){
								found = 1;
								print("sensor already active: pin", pin.number);
								break;
							}
						}
						
						if(found === 0){
							//it means we need to activate the sensor
							print("pin", pin.number, "ADC");
							ADC.enable(pin.number);
							let sensor_attributes = {
								name: obj.devices[j].name,
								pin: pin.number
							};
							let timer = Timer.set(time_interval, Timer.REPEAT, function(sensor_attributes) {
								let read_value = ADC.read(sensor_attributes.pin);
								print("read value:", read_value);
								let now = Timer.now();
								let formatted_time = Timer.fmt("%FT%TZ", now);
								//prepare data to report
								let sensor_data = {
									name: sensor_attributes.name,
									data: []
								};
								sensor_data.data[0] = {
									time: formatted_time,
									value: read_value
								};
								let publish_message = JSON.stringify(sensor_data);
								print("Publishing sensor data to ", sensor_data_topic, "topic with the following message:", publish_message);
								MQTT.pub(sensor_data_topic, publish_message, 0);
							}, sensor_attributes);
							
							//save the timer id so we can stop it in the future
							timers_list.push({
								timer_pin_number: pin.number,
								timer_id: timer
							});
						}
					}
				}
				
				state.devices[j].pins.push({
					name: pin.name,
					number: pin.number,
					value: pin.value
				});
			}
		}
		
		// set defualts to unused/removed pins
		for(let i=0; i<all_pins.length; ++i) {
			if(all_pins[i]) {
				if(pins[i] === 1){
					GPIO.write(i, 0);
					print("pin", i, "is 0");
				}
				else if(pins[i] === 2){
					PWM.set(i, pwm_freq, min_duty);
					print("pin", i, "is PWM");
				}
				else if(pins[i] === 3){
					for(let z=0; z<timers_list.length; z++){
						if(timers_list[z].timer_pin_number === i){
							Timer.del(timers_list[z].timer_id);
							print("Timer deleted");
							timers_list.splice(z,1);
							break;
						}
					}
				}
			}
		}
	
		// publish state
		let publish_message = JSON.stringify(state);
		print("Publishing state to ", state_topic, "topic with the following message:", publish_message);
		MQTT.pub(state_topic, publish_message, 1);
		
	}
	else{
		let empty_state = {
			devices: []
		};
		let publish_message = JSON.stringify(empty_state);
		print("Publishing state to ", state_topic, "topic with the following message:", publish_message);
		MQTT.pub(state_topic, publish_message, 1);
	}
}, null);

print("finish");
