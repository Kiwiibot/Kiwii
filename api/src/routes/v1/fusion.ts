import { createCanvas, loadImage } from "@napi-rs/canvas";

export default async function fusion(imageUrl: string, imageUrl2: string) {
  const data = await fetch(imageUrl);
  const buffer = await data.arrayBuffer();
  const image = await loadImage(Buffer.from(buffer));
  const data2 = await fetch(imageUrl2);
  const buffer2 = await data2.arrayBuffer();
  const image2 = await loadImage(Buffer.from(buffer2));

  const canvas = createCanvas(image.width, image.height);
  const ctx = canvas.getContext("2d");
  ctx.globalAlpha = 0.5;
  ctx.drawImage(image, 0, 0);
  ctx.drawImage(image2, 0, 0, image.width, image.height);

  return canvas.toBuffer("image/png");
}
