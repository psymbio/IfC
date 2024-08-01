from uuid import uuid4

from nitric.resources import api, kv, bucket
from nitric.application import Nitric
from nitric.context import HttpContext

# Create an api named public
profile_api = api("public")

# Access profile key value store with permissions
profiles = kv('profiles').allow('get', 'set')

@profile_api.post("/profiles")
async def create_profile(ctx: HttpContext) -> None:
  pid = str(uuid4())
  name = ctx.req.json['name']
  age = ctx.req.json['age']
  hometown = ctx.req.json['homeTown']

  await profiles.set(pid, { 'name': name, 'age': age, 'hometown': hometown} )

  ctx.res.body = { 'msg': f'Profile with id {pid} created.'}

@profile_api.get("/profiles/:id")
async def get_profile(ctx: HttpContext) -> None:
  pid = ctx.req.params['id']
  d = await profiles.get(pid)

  ctx.res.body = f"{d.content}"

@profile_api.delete("/profiles/:id")
async def delete_profiles(ctx: HttpContext) -> None:
  pid = ctx.req.params['id']

  try:
    d = await profiles.delete(pid)
    ctx.res.body = { 'msg': f'Profile with id {pid} deleted.'}
  except:
    ctx.res.status = 404
    ctx.res.body = { 'msg': f'Profile with id {pid} not found.'}
    
Nitric.run()