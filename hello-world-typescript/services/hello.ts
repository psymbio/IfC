import { api, HttpContext, bucket, topic } from "@nitric/sdk";

const main = api("main"); // fileApi
const bucketObject = bucket("bucketforifc").allow("read", "write"); // files
const notifyPub = topic("updated").allow("publish");
const notify = topic("updated");

main.get("url", async (ctx) => {
  ctx.res.json({
    url: await bucketObject.file("profile.png").getUploadUrl(),
  });
});

main.get("/hello/:name", async (ctx: HttpContext) => {
  try {
    const { name } = ctx.req.params;
    ctx.res.body = `Hello ${name}`;
    return ctx;
  } catch (error) {
    console.error(error);
    ctx.res.body = { message: "Internal Server Error" };
    ctx.res.status = 500;
    return ctx;
  }
});

bucketObject.on("write", "", async (ctx) => {
  await notifyPub.publish({
    status: "updated",
    name: `${ctx.req.key}`,
  });
});

notify.subscribe(async (ctx) => {
  console.log(`File was written or updated ${ctx.req.data}`);
});

export default main;