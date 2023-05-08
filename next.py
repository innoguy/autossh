import falcon
import json
from os import path

filename = "controllers.json"
controllers = []

class NextResource:
    def on_get(self, req, resp):
        if path.isfile(filename) is False:
            raise Exception("File not found")
        with open(filename) as fp:
            controllers = json.load(fp)
        maxport=controllers[0]["port"]
        for c in controllers:
            if c["port"] > maxport:
                maxport=c["port"]
        resp.text = str(int(maxport)+1)
        resp.status = falcon.HTTP_OK
        resp.content_type = falcon.MEDIA_JSON
