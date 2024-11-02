import { createCanvas } from "@napi-rs/canvas";
import { fonts, images } from "./index.js";
import type { APIRoute } from "astro";

export const GET: APIRoute = (context) => {
  const text = context.url.searchParams.get("text");

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

  const base = images.achievement;
  const canvas = createCanvas(base.width, base.height);
  const ctx = canvas.getContext("2d");
  ctx.drawImage(base, 0, 0);
  ctx.font = fonts["Minecraftia.ttf"]?.toCanvasString(17) ?? "17px sans-serif";
  ctx.fillStyle = "#ffff00";
  ctx.fillText("Achievement Get!", 60, 40);
  ctx.fillStyle = "white";
  ctx.fillText(text, 60, 60);

  return new Response(canvas.toBuffer("image/png"));
};
