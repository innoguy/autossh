import falcon
import json
from os import path

filename = "others.json"
others = []

class OthersResource:
    def on_get(self, req, resp):
        if path.isfile(filename) is False:
            raise Exception("File not found")
        with open(filename) as fp:
            others = json.load(fp)
        resp.text = json.dumps(others)
        resp.status = falcon.HTTP_OK
        resp.content_type = falcon.MEDIA_JSON

    def on_post(self, req, resp):
        other = json.load(req.bounded_stream)
        print(other["name"])
        if path.isfile(filename) is False:
            raise Exception("File not found")
        with open(filename) as fp:
            others = json.load(fp)
        error = False
        for c in others:
            if c["name"] == other["name"]:
                error=True
                break
            if c["port"] == other["port"]:
                error=True
                break
        if ( not error):
            others.append(other)
            with open(filename, 'w') as json_file:
                json.dump(others, json_file, indent=4, separators=(',',': ')) 
            resp.text = "Device added successfully."
            resp.status = falcon.HTTP_OK
            resp.content_type = falcon.MEDIA_TEXT
        else:
            resp.text = "Name or port number already exists."
            resp.status = falcon.HTTP_OK
            resp.content_type = falcon.MEDIA_TEXT
