import { createCanvas, loadImage } from "@napi-rs/canvas";
import { fonts, images } from "./index.js";
import type { APIRoute } from "astro";

export const GET: APIRoute = async (context) => {
  const imageUrl = context.url.searchParams.get("image");
  const gameName = context.url.searchParams.get("gameName");
  const username = context.url.searchParams.get("username");
  const classic = context.url.searchParams.get("classic") === "true";

  if (gameName === null || username === null || imageUrl === null) {
    return new Response(
      JSON.stringify({
        errorCode: 400,
        error: "Bad request",
        message: "`gameName`, `username`, and `imageUrl` are required params",
      }),
      { status: 400, headers: { "Content-Type": "application/json" } }
    );
  }

  const base = classic ? images.steamNowPlayingClassic : images.steamNowPlaying;

  if (!classic) {
    const image = await loadImage(imageUrl);
    const canvas = createCanvas(base.width, base.height);
    const ctx = canvas.getContext("2d");
    ctx.drawImage(base, 0, 0);
    ctx.drawImage(image, 26, 26, 41, 42);
    ctx.fillStyle = "#90b93c";
    ctx.font =
      fonts["Noto-Regular.ttf"]?.toCanvasString(14) ?? "14px sans-serif";
    ctx.fillText(username, 80, 34);
    ctx.fillText(gameName, 80, 70);

    return new Response(canvas.toBuffer("image/png"));
  }
  const image = await loadImage(imageUrl);
  const canvas = createCanvas(base.width, base.height);
  const ctx = canvas.getContext("2d");
  ctx.drawImage(base, 0, 0);
  ctx.drawImage(image, 21, 21, 32, 32);
  ctx.fillStyle = "#90b93c";
  ctx.font = fonts["Noto-Regular.ttf"]?.toCanvasString(10) ?? "10px sans-serif";
  ctx.fillText(username, 63, 26);
  ctx.fillText(gameName, 63, 54);

  return new Response(canvas.toBuffer("image/png"));
};
