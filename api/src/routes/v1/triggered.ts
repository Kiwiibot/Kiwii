import { createCanvas, Image, loadImage } from "@napi-rs/canvas";
import { GifEncoder } from "@skyra/gifenc";
import utils from "../../utils/canvas.js";

const coord1 = [-25, -33, -42, -14];
const coord2 = [-25, -13, -34, -10];

export default async function triggered(base: Image, imageUrl: string) {
  const imageR = await fetch(imageUrl);
  const buffer = await imageR.arrayBuffer();
  const image = await loadImage(Buffer.from(buffer));
  const canvas = createCanvas(base.width, base.width);
  const ctx = canvas.getContext("2d");
  const encoder = new GifEncoder(base.width, base.width);
  ctx.fillStyle = "white";
  ctx.fillRect(0, 0, base.width, base.width);
  const stream = encoder.createReadStream();
  encoder.start();
  encoder.setRepeat(0);
  encoder.setDelay(50);
  encoder.setQuality(200);
  for (let i = 0; i < 4; i++) {
    utils.drawImageWithTint(ctx, image, "red", coord1[i], coord2[i], 300, 300);
    ctx.drawImage(base, 0, 218, 256, 38);
    encoder.addFrame(ctx as any);
  }
  encoder.finish();
  const buffer2 = await utils.streamToArray(stream);
  return Buffer.concat(buffer2);
}
