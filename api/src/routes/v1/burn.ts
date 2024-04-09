import { createCanvas, loadImage } from "@napi-rs/canvas";
import { GifEncoder } from "@skyra/gifenc";
import utils from "../../utils/canvas.js";

import path from "path";

import { __dirname } from ".";
const framePaths = Array.from({length: 46}, (_, i) => path.join(process.cwd(), "api", "assets", "images", "fire", `frame-${i}.gif`));
const frames = Promise.all(framePaths.map((p) => loadImage(p)));

export default async function burn(imageUrl: string) {
  const imageR = await fetch(imageUrl);
  const buffer = await imageR.arrayBuffer();
  const image = await loadImage(Buffer.from(buffer));
  const canvas = createCanvas(image.width, image.height);
  const ctx = canvas.getContext("2d");
  const encoder = new GifEncoder(image.width, image.height);
  const stream = encoder.createReadStream();
  encoder.start();
  encoder.setRepeat(0);
  encoder.setDelay(10);
  encoder.setQuality(10);

  for (const frame of await frames) {
    const ratio = frame.width / frame.width;
    const height = Math.round(image.width / ratio);
    utils.drawImageWithTint(
      ctx,
      image,
      "#fc671e",
      0,
      0,
      image.width,
      image.height,
    );
    ctx.drawImage(frame, 0, image.height - height, image.width, height);
    encoder.addFrame(ctx as any);
  }
  encoder.finish();
  const buffer2 = await utils.streamToArray(stream);

  return Buffer.concat(buffer2);
}
