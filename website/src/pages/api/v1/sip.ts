import { createCanvas, loadImage } from "@napi-rs/canvas";
import type { APIRoute } from "astro";
import { images } from ".";

export const GET: APIRoute = async (context) => {
  const imageUrl = context.url.searchParams.get("image");
  const dir = context.url.searchParams.get("direction");

  const base = images.sip;

  if (imageUrl === null && dir === null) {
    return new Response(
      JSON.stringify({
        errorCode: 400,
        error: "Bad request",
        message: "`image` and `direction` are required params",
      }),
      { status: 400, headers: { "Content-Type": "application/json" } }
    );
  }

  if (dir !== "left" && dir !== "right") {
    return new Response(
      JSON.stringify({
        errorCode: 400,
        error: "Bad request",
        message: "`direction` must be either `left` or `right`",
      }),
      { status: 400, headers: { "Content-Type": "application/json" } }
    );
  }

  const direction = dir as "left" | "right";
  const image = await loadImage(imageUrl!);

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

  return new Response(canvas.toBuffer("image/png"));
};
