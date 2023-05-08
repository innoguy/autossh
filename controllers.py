import falcon
import json
from os import path

filename = "controllers.json"
controllers = []

class ControllersResource:
    def on_get(self, req, resp):
        if path.isfile(filename) is False:
            raise Exception("File not found")
        with open(filename) as fp:
            controllers = json.load(fp)
        resp.text = json.dumps(controllers)
        resp.status = falcon.HTTP_OK
        resp.content_type = falcon.MEDIA_JSON

    def on_post(self, req, resp):
        controller = json.load(req.bounded_stream)
        print(controller["name"])
        if path.isfile(filename) is False:
            raise Exception("File not found")
        with open(filename) as fp:
            controllers = json.load(fp)
        error = False
        for c in controllers:
            if c["name"] == controller["name"]:
                error=True
                break
            if c["port"] == controller["port"]:
                error=True
                break
        if ( not error):
            controllers.append(controller)
            with open(filename, 'w') as json_file:
                json.dump(controllers, json_file, indent=4, separators=(',',': ')) 
            resp.text = "Controller added successfully."
            resp.status = falcon.HTTP_OK
            resp.content_type = falcon.MEDIA_TEXT
        else:
            resp.text = "Name or port number already exists."
            resp.status = falcon.HTTP_OK
            resp.content_type = falcon.MEDIA_TEXT