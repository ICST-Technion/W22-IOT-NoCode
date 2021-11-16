from google.cloud import iot_v1
from google.protobuf import field_mask_pb2 as gp_field_mask
from google.api_core.exceptions import NotFound
import argparse
from tabulate import tabulate


class IotCloudManager:
    def __init__(self, project_id: str, public_key: str):
        self._cloud_region = 'europe-west1'
        self._registry_id = 'IOT-devices'
        self._device_id = 'LED_RGB'
        self._project_id = project_id
        self._public_key = public_key
        self._client = iot_v1.DeviceManagerClient()
        self._parent = self._client.common_location_path(self._project_id, self._cloud_region)
        self._registry_path = self._client.registry_path(self._project_id, self._cloud_region, self._registry_id)
        self._device_path = self._client.device_path(self._project_id, self._cloud_region, self._registry_id,
                                                     self._device_id)

        self._public_key_data = None

        with open(self._public_key) as f:
            self._public_key_data = f.read()

    def _is_registry_exist(self):
        try:
            self._client.get_device_registry({
                "name": self._registry_path
            })
        except NotFound:
            return False
        else:
            return True

    def _is_device_exist(self):
        try:
            self._client.get_device(request={"name": self._device_path})
        except NotFound:
            return False
        else:
            return True

    def _create_registry(self):

        self._client.create_device_registry(
            request={"parent": self._parent, "device_registry": {
                "id": self._registry_id,
            }}
        )

        print(f"{self._registry_id} registry is created")

    def _create_device(self):
        self._client.create_device(request={"parent": self._registry_path, "device": {
            "id": self._device_id,
            "credentials": [
                {
                    "public_key": {
                        "format": iot_v1.PublicKeyFormat.RSA_PEM,
                        "key": self._public_key_data,
                    }
                }]
        }})

        print(f"{self._device_id} device is created")

    def init(self):
        print(f"Checking project configuration")

        if not self._is_registry_exist():
            print(f"{self._registry_id} registry is missing, it will be now created")
            self._create_registry()

        if not self._is_device_exist():
            print(f"{self._device_id} is missing, it will be now created")
            self._create_device()


parser = argparse.ArgumentParser()
parser.add_argument('project_id', help='Google cloud project ID')
parser.add_argument('public_key', help='Public key path')
args = parser.parse_args()

client = IotCloudManager(args.project_id, args.public_key)

client.init()
