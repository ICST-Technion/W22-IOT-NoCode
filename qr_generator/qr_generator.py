import qrcode
import argparse
import json

parser = argparse.ArgumentParser(description='Generates board QR code')
parser.add_argument('serial_number', help="Board's Google-Cloud IOT Core ID")
parser.add_argument('public_key', help="Board's Google-Cloud IOT Core public key")
args = parser.parse_args()


json_obj = {
        "serial_number": args.serial_number,
        "public_key": args.public_key
}

#Creating an instance of qrcode
qr = qrcode.QRCode(
        version=1,
        box_size=10,
        border=5)
qr.add_data(json.dumps(json_obj))
qr.make(fit=True)
img = qr.make_image(fill='black', back_color='white')
img.save('qr.png')