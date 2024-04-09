import { createCanvas, Image, loadImage } from "@napi-rs/canvas";
import { fonts } from "./index.js";

export default async function spotifyNowPlaying(
  imageUrl: string,
  songName: string,
  artistName: string,
  base: Image,
  picksName?: string,
) {
  picksName ??= "Spotify";
  const data = await fetch(imageUrl);
  const buffer = await data.arrayBuffer();
  const image = await loadImage(Buffer.from(buffer));
  const canvas = createCanvas(base.width, base.height);
  const ctx = canvas.getContext("2d");
  ctx.fillStyle = "white";
  ctx.fillRect(0, 0, base.width, base.height);
  const height = 504 / image.width;
  ctx.drawImage(image, 66, 132, 504, height * image.height);
  ctx.drawImage(base, 0, 0);
  ctx.textBaseline = "top";
  ctx.textAlign = "center";
  ctx.font = fonts["Noto-Bold.ttf"]?.toCanvasString(25);
  ctx.fillStyle = "white";
  ctx.fillText(songName, base.width / 2, 685);
  ctx.fillStyle = "#bdbec2";
  ctx.font = fonts["Noto-Regular.ttf"]?.toCanvasString(20);
  ctx.fillText(artistName, base.width / 2, 715);
  ctx.fillText(`${picksName}'s Picks`, base.width / 2, 65);

  return canvas.toBuffer("image/png");
}
