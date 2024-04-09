import { createCanvas, Image, loadImage } from "@napi-rs/canvas";
import { fonts } from "./index.js";

export default async function steamNowPlaying(
  base: Image,
  gameName: string,
  username: string,
  imageUrl: string,
  classic = false,
) {
  if (!classic) {
    const imageR = await fetch(imageUrl);
    const buffer = await imageR.arrayBuffer();
    const image = await loadImage(Buffer.from(buffer));
    const canvas = createCanvas(base.width, base.height);
    const ctx = canvas.getContext("2d");
    ctx.drawImage(base, 0, 0);
    ctx.drawImage(image, 26, 26, 41, 42);
    ctx.fillStyle = "#90b93c";
    ctx.font = fonts["Noto-Regular.ttf"]?.toCanvasString(14);
    ctx.fillText(username, 80, 34);
    ctx.fillText(gameName, 80, 70);

    return canvas.toBuffer("image/png");
  } else {
    const imageR = await fetch(imageUrl);
    const buffer = await imageR.arrayBuffer();
    const image = await loadImage(Buffer.from(buffer));
    const canvas = createCanvas(base.width, base.height);
    const ctx = canvas.getContext("2d");
    ctx.drawImage(base, 0, 0);
    ctx.drawImage(image, 21, 21, 32, 32);
    ctx.fillStyle = "#90b93c";
    ctx.font = fonts["Noto-Regular.ttf"]?.toCanvasString(10);
    ctx.fillText(username, 63, 26);
    ctx.fillText(gameName, 63, 54);

    return canvas.toBuffer("image/png");
  }
}
