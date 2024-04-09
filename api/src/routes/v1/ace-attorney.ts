import path from "node:path";

import { createCanvas, loadImage } from "@napi-rs/canvas";

import { __dirname, fonts } from "./index.js";

import utils from "../../utils/canvas.js";

export const characters = {
  phoenix: ["phoenix", "wright", "naruhodo", "ryuuichi", "ryu", "nick"],
  edgeworth: ["miles", "edgeworth", "mitsurugi", "reiji", "edgey"],
  godot: ["godot", "diego", "armando", "souryuu", "soryu", "kaminogi"],
  apollo: ["apollo", "justice", "odoroki", "housuke", "hosuke"],
};

export default async function aceAttorney(character: string, quote: string) {
  let file;
  for (const [id, arr] of Object.entries(characters)) {
    if (!arr.includes(character.toLowerCase())) continue;
    file = id;
    break;
  }

  const base = await loadImage(
    path.join(
      __dirname,
      "..",
      "..",
      "..",
      "assets",
      "images",
      "ace-attorney",
      `${file}.png`,
    ),
  );

  const canvas = createCanvas(base.width, base.height);
  const ctx = canvas.getContext("2d");
  ctx.drawImage(base, 0, 0);
  ctx.font = fonts["Ace-Attorney.ttf"]?.toCanvasString(14);
  ctx.fillStyle = "white";
  ctx.textBaseline = "top";
  ctx.fillText(
    character.substring(0, 1).toUpperCase() + character.substring(1),
    6,
    176,
  );
  const t = utils.wrapText(ctx, quote, 242) ?? [""];
  const text = t.length > 5 ? `${t.slice(0, 5).join("\n")}...` : t.join("\n");
  ctx.fillText(text, 7, 199);

  return canvas.toBuffer("image/png");
}
