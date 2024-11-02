import { createCanvas, loadImage } from "@napi-rs/canvas";
import { fonts, images } from "./index.js";
import type { APIRoute } from "astro";

export const GET: APIRoute = async (context) => {
  const imageUrl = context.url.searchParams.get("image");
  const songName = context.url.searchParams.get("songName");
  const artistName = context.url.searchParams.get("artistName");
  let picksName = context.url.searchParams.get("picksName") ?? "Spotify";

  if (imageUrl === null || songName === null || artistName === null) {
    return new Response(
      JSON.stringify({
        errorCode: 400,
        error: "Bad request",
        message: "`image`, `songName`, and `artistName` are required params",
      }),
      { status: 400, headers: { "Content-Type": "application/json" } }
    );
  }
  const base = images.spotifyBaseImage;
  const image = await loadImage(imageUrl);
  const canvas = createCanvas(base.width, base.height);
  const ctx = canvas.getContext("2d");
  ctx.fillStyle = "white";
  ctx.fillRect(0, 0, base.width, base.height);
  const height = 504 / image.width;
  ctx.drawImage(image, 66, 132, 504, height * image.height);
  ctx.drawImage(base, 0, 0);
  ctx.textBaseline = "top";
  ctx.textAlign = "center";
  ctx.font = fonts["Noto-Bold.ttf"]?.toCanvasString(25) ?? "25px sans-serif";
  ctx.fillStyle = "white";
  ctx.fillText(songName, base.width / 2, 685);
  ctx.fillStyle = "#bdbec2";
  ctx.font = fonts["Noto-Regular.ttf"]?.toCanvasString(20) ?? "20px sans-serif";
  ctx.fillText(artistName, base.width / 2, 715);
  ctx.fillText(`${picksName}'s Picks`, base.width / 2, 65);

  return new Response(canvas.toBuffer("image/png"));
};
