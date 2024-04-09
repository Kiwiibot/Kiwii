import { createCanvas, Image, loadImage } from "@napi-rs/canvas";

export default async function sip(
  base: Image,
  imageUrl: string,
  direction: "left" | "right",
) {
  const imageR = await fetch(imageUrl);
  const buffer = await imageR.arrayBuffer();
  const image = await loadImage(Buffer.from(buffer));

  const canvas = createCanvas(base.width, base.height);
  const ctx = canvas.getContext("2d");
  ctx.fillRect(0, 0, base.width, base.height);
  if (direction === "right") {
    ctx.translate(base.width, 0);
    ctx.scale(-1, 1);
  }

  ctx.drawImage(image, 0, 0, 512, 512);
  if (direction === "right") {
    ctx.setTransform(1, 0, 0, 1, 0, 0);
  }

  ctx.drawImage(base, 0, 0);

  return canvas.toBuffer("image/png");
}
