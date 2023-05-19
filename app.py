# app.py
import falcon
from controllers import ControllersResource
from others import OthersResource
from next import NextResource

app = application = falcon.App()
app.add_route("/controllers", ControllersResource())
app.add_route("/others", OthersResource())
app.add_route("/next", NextResource())
