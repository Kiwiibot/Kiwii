import { createCanvas, loadImage, Image } from "@napi-rs/canvas";
import { fonts } from "./index.js";

export default async function achievement(text: string, base: Image) {
    const canvas = createCanvas(base.width, base.height);
    const ctx = canvas.getContext("2d");
    ctx.drawImage(base, 0, 0);
    ctx.font = fonts["Minecraftia.ttf"]?.toCanvasString(17);
    ctx.fillStyle = "#ffff00";
    ctx.fillText('Achievement Get!', 60, 40);
    ctx.fillStyle = "white";
    ctx.fillText(text, 60, 60);

    return canvas.toBuffer("image/png");
}