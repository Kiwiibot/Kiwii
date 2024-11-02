import { createCanvas, loadImage } from "@napi-rs/canvas";
import type { APIRoute } from "astro";

export const GET: APIRoute = async (context) => {
  const imageUrl = context.url.searchParams.get("image");
  const imageUrl2 = context.url.searchParams.get("image2");

  if (imageUrl == null || imageUrl2 == null) {
    return new Response(
      JSON.stringify({
        errorCode: 400,
        error: "Bad request",
        message: "`image` and `image2` are required params",
      }),
      { status: 400, headers: { "Content-Type": "application/json" } }
    );
  }

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

  return new Response(canvas.toBuffer("image/png"));
}
