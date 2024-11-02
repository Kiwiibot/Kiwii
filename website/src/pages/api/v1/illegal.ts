import { createCanvas, loadImage } from "@napi-rs/canvas";
import frames from "../../../assets/json/illegal.json" assert { type: "json" };
import { GifEncoder } from "@skyra/gifenc";
import path from "path";
import { __dirname, fonts } from "./index.js";
import utils from "~/utils/canvas.js";
import type { APIRoute } from "astro";

export const GET: APIRoute = async (context) => {
  const text = context.url.searchParams.get("text");
  const verb = context.url.searchParams.get("verb") as
    | "is"
    | "are"
    | "am"
    | null ?? "is";

  if (text == null) {
    return new Response(
      JSON.stringify({
        errorCode: 400,
        error: "Bad request",
        message: "`text` is a required param",
      }),
      { status: 400, headers: { "Content-Type": "application/json" } }
    );
  }

  const encoder = new GifEncoder(262, 264);
  const stream = encoder.createReadStream();
  encoder.start();
  encoder.setRepeat(0);
  encoder.setDelay(100);
  encoder.setQuality(200);

  for (const frame of frames) {
    const img = await loadImage(
      path.join(
        __dirname,
        "..",
        "..",
        "..",
        "assets",
        "images",
        "illegal",
        frame.file
      )
    );

    const canvas = createCanvas(img.width, img.height);
    const ctx = canvas.getContext("2d");
    ctx.drawImage(img, 0, 0);
    if (!frame.show) {
      encoder.addFrame(ctx as any);
      continue;
    }
    ctx.textBaseline = "top";
    ctx.font = fonts["Impact.ttf"]?.toCanvasString(20) ?? "20px sans-serif";
    const maxLen = frame.corners[1]![0]! - frame.corners[0]![0]!;

    // ctx.fillText(
    //   `${text.toUpperCase()}\n${verb.toUpperCase()} NOW\nILLEGAL`,
    //   frame.corners[0][0],
    //   frame.corners[0][1],
    //   maxLen,
    // );
    ctx.fillText(
      text.toUpperCase(),
      frame.corners[0]![0]!,
      frame.corners[0]![1]! + 1,
      maxLen
    );
    ctx.fillText(
      `${verb.toUpperCase()} NOW`,
      frame.corners[0]![0]!,
      frame.corners[0]![1]! + 21,
      maxLen
    );
    ctx.fillText(
      "ILLEGAL",
      frame.corners[0]![0]!,
      frame.corners[0]![1]! + 41,
      maxLen
    );
    encoder.addFrame(ctx);
  }
  encoder.finish();
  return new Response(Buffer.concat(await utils.streamToArray(stream)));
};
