# app.py
import falcon
from controllers import ControllersResource
from next import NextResource

app = application = falcon.App()
app.add_route("/controllers", ControllersResource())
app.add_route("/next", NextResource())
