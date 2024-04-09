import path from "path";

import { GifEncoder } from "@skyra/gifenc";
import { createCanvas, Image, loadImage } from "@napi-rs/canvas";
import { fonts, __dirname } from "./index.js";
import utils from "../../utils/canvas.js";

export default async function impostor(
  avatar: Image,
  user: string,
  impostor?: boolean,
) {
  if (!impostor) {
    impostor = Math.random() < 0.5;
  }

  const text = `${user} was${impostor ? "" : "n't"} An Impostor.`;
  const encoder = new GifEncoder(320, 180);
  const canvas = createCanvas(320, 180);
  const ctx = canvas.getContext("2d");
  ctx.textAlign = "center";
  ctx.textBaseline = "middle";
  ctx.fillStyle = "white";
  ctx.font = fonts["Noto-Regular.ttf"]?.toCanvasString(18);
  const stream = encoder.createReadStream();
  encoder.start();
  encoder.setRepeat(0);
  encoder.setDelay(100);
  encoder.setQuality(200);
  for (let i = 0; i < 52; i++) {
    const frameID = `frame_${i.toString().padStart(2, "0")}.gif`;
    const frame = await loadImage(
      path.join(
        __dirname,
        "..",
        "..",
        "..",
        "assets",
        "images",
        "eject",
        frameID,
      ),
    );
    ctx.drawImage(frame, 0, 0);
    if (i <= 17) {
      const x = ((320 / 15) * i) - 50;
      const y = (frame.height / 2) - 25;
      const rotation = (360 / 15) * i;
      const angle = rotation * (Math.PI / 180);
      const originX = x + 25;
      const originY = y + 25;
      ctx.translate(originX, originY);
      ctx.rotate(-angle);
      ctx.translate(-originX, -originY);
      ctx.drawImage(avatar, x, y, 50, 50);
      ctx.translate(originX, originY);
      ctx.rotate(angle);
      ctx.translate(-originX, -originY);
    }
    if (i > 17) {
      if (i <= 27) {
        const letters = Math.ceil(((text.length / 10) * (i - 17)) + 1);
        const toDraw = text.slice(0, letters + 1);
        ctx.fillText(toDraw, frame.width / 2, frame.height / 2, 300);
      } else {
        ctx.fillText(text, frame.width / 2, frame.height / 2, 300);
      }
    }
    encoder.addFrame(ctx as any);
  }
  encoder.finish();
  const buffer = await utils.streamToArray(stream);

  return buffer;
}
