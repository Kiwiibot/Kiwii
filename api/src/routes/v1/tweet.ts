import { TwitterOpenApi } from "twitter-openapi-typescript";
import { readFile } from "fs/promises";
import path from "path";
import { createCanvas, loadImage, SKRSContext2D } from "@napi-rs/canvas";
import { fonts, __dirname } from "./index.js";
import canvasUtils from "../../utils/canvas.js";
import utils from "../../utils/utils.js";
import emojiRegex from "emoji-regex";
import twemoji from "@twemoji/parser";
import { DateTime } from "luxon";

const api = new TwitterOpenApi();

export default async function tweet(
  user: string,
  text: string,
  image?: string,
) {
  const userData = await getUser(user);
  const avatar = await loadImage(userData.avatar);
  const base1 = await loadImage(
    path.join(
      __dirname,
      "..",
      "..",
      "..",
      "assets",
      "images",
      "tweet",
      "bg-1.png",
    ),
  );
  const base2 = await loadImage(
    path.join(
      __dirname,
      "..",
      "..",
      "..",
      "assets",
      "images",
      "tweet",
      "bg-2.png",
    ),
  );

  const canvas = createCanvas(base1.width, base1.height + base2.height);
  const ctx = canvas.getContext("2d");
  ctx.font = fonts["ChirpRegular.ttf"].toCanvasString(23);
  const lines = canvasUtils.wrapText(ctx, text, 710, true);
  const metrics = ctx.measureText(lines.join("\n"));
  const linesLen = metrics.actualBoundingBoxAscent +
    metrics.actualBoundingBoxDescent + 15;
  canvas.height += linesLen;
  let imageHeight = 0;
  ctx.fillStyle = "#15202b";
  ctx.fillRect(0, base1.height, canvas.width, linesLen);
  if (image) {
    const body = await fetch(image).then((res) => res.arrayBuffer());
    const imageData = await loadImage(Buffer.from(body));
    const imageWidth = 740;
    const imageHeightRatio = imageWidth / imageData.width;
    imageHeight = imageData.height * imageHeightRatio;
    const imageCanvas = createCanvas(imageWidth, imageHeight);
    const imageCtx = imageCanvas.getContext("2d");
    canvas.height += imageHeight + 15;
    ctx.fillStyle = "#15202b";
    ctx.fillRect(0, base1.height, canvas.width, linesLen + imageHeight + 15);
    const x = 0;
    const y = 0;
    const radius = 15;
    roundedPath(imageCtx, radius, x, y, imageWidth, imageHeight);
    imageCtx.clip();
    imageCtx.drawImage(imageData, x, y, imageWidth, imageHeight);
    roundedPath(imageCtx, radius, x, y, imageWidth, imageHeight);
    imageCtx.strokeStyle = "#303336";
    imageCtx.lineWidth = 5;
    imageCtx.stroke();
    ctx.drawImage(
      imageCanvas,
      17,
      base1.height + linesLen + 15,
      imageWidth,
      imageHeight,
    );
  }

  const likes = utils.randomRange(
    Math.ceil(userData.followers * 0.0015),
    Math.ceil(userData.followers * 0.002),
  );
  const retweets = utils.randomRange(
    Math.ceil(userData.followers * 0.00015),
    Math.ceil(userData.followers * 0.0002),
  );
  const quotTweets = utils.randomRange(
    Math.ceil(userData.followers * 0.000015),
    Math.ceil(userData.followers * 0.00002),
  );
  const replies = utils.randomRange(
    Math.ceil(userData.followers * 0.000015),
    Math.ceil(userData.followers * 0.00002),
  );
  const bookmarks = utils.randomRange(
    Math.ceil(userData.followers * 0.000015),
    Math.ceil(userData.followers * 0.00002),
  );
  const views = utils.randomRange(
    Math.ceil(userData.followers * 10),
    Math.ceil(userData.followers * 30),
  );

  ctx.drawImage(base1, 0, 0);
  const base2StartY = base1.height + linesLen + (image ? imageHeight + 15 : 0);
  ctx.drawImage(base2, 0, base2StartY);
  ctx.textBaseline = "top";
  ctx.font = fonts["ChirpBold.ttf"].toCanvasString(18);
  ctx.fillStyle = "white";
  ctx.fillText(userData.name, 80, 88);
  const nameLen = ctx.measureText(userData.name).width;
  if (userData.checkType) {
    const verified = await loadImage(
      path.join(
        __dirname,
        "..",
        "..",
        "..",
        "assets",
        "images",
        "tweet",
        `${userData.checkType}.png`,
      ),
    );
    ctx.drawImage(verified, 85 + nameLen + 3, 87, 20, 20);
  }

  if (userData.label) {
    const labelData = await fetch(userData.label).then((res) =>
      res.arrayBuffer()
    );
    const labelImg = await loadImage(Buffer.from(labelData));
    const labelCanvas = createCanvas(24, 24);
    const labelCtx = labelCanvas.getContext("2d");
    roundedPath(labelCtx, 3, 0, 0, 24, 24);
    labelCtx.clip();
    labelCtx.fillStyle = "#303336";
    labelCtx.fillRect(0, 0, 24, 24);
    roundedPath(labelCtx, 3, 2, 2, 20, 20);
    labelCtx.clip();
    labelCtx.drawImage(labelImg, 2, 2, 20, 20);
    ctx.drawImage(labelCanvas, 80 + nameLen + 3 + 20 + 3, 90, 20, 20);
  }

  ctx.font = fonts["ChirpRegular.ttf"].toCanvasString(17);
  ctx.fillStyle = "#71767b";
  ctx.fillText(`@${userData.screenName}`, 80, 113);
  ctx.fillStyle = "white";
  ctx.font = fonts["ChirpRegular.ttf"].toCanvasString(23);
  await fillTextWithEmoji(ctx, text, 17, 160, 710, 26);
  ctx.fillStyle = "#71767b";
  ctx.font = fonts["Noto-Regular.ttf"].toCanvasString(18);
  const time = DateTime.now().toFormat("h:mm a ∙ LLL d, yyyy ∙");
  ctx.fillText(time, 18, base2StartY + 12);
  const timeLen = ctx.measureText(time).width;
  ctx.fillStyle = "white";
  ctx.font = fonts["Noto-Bold.ttf"].toCanvasString(18);
  ctx.fillText(utils.formatNumberK(views), 18 + timeLen + 6, base2StartY + 12);
  const viewsLen = ctx.measureText(utils.formatNumberK(views)).width;
  ctx.fillStyle = "#71767b";
  ctx.font = fonts["Noto-Regular.ttf"].toCanvasString(18);
  ctx.fillText("Views", 18 + timeLen + 6 + viewsLen + 6, base2StartY + 12);
  ctx.font = fonts["Noto-Regular.ttf"].toCanvasString(16);
  ctx.fillText(utils.formatNumberK(replies), 80, base2StartY + 143);
  ctx.fillText(utils.formatNumberK(likes), 503, base2StartY + 143);
  ctx.fillText(
    utils.formatNumberK(retweets + quotTweets),
    296,
    base2StartY + 143,
  );
  // ctx.fillText(utils.formatNumberK(bookmarks), 734, base2StartY + 143);
  let currentLen = 17;
  ctx.fillStyle = "white";
  ctx.font = fonts["Noto-Bold.ttf"].toCanvasString(18);
  ctx.fillText(utils.formatNumberK(retweets), currentLen, base2StartY + 75);
  currentLen += ctx.measureText(utils.formatNumberK(retweets)).width;
  currentLen += 5;
  ctx.fillStyle = "#71767b";
  ctx.font = fonts["Noto-Regular.ttf"].toCanvasString(18);
  ctx.fillText("Reposts", currentLen, base2StartY + 75);
  currentLen += ctx.measureText("Reposts").width;
  currentLen += 10;
  ctx.fillStyle = "white";
  ctx.font = fonts["Noto-Bold.ttf"].toCanvasString(18);
  ctx.fillText(utils.formatNumberK(quotTweets), currentLen, base2StartY + 75);
  currentLen += ctx.measureText(utils.formatNumberK(quotTweets)).width;
  currentLen += 5;
  ctx.fillStyle = "#71767b";
  ctx.font = fonts["Noto-Regular.ttf"].toCanvasString(18);
  ctx.fillText("Quotes", currentLen, base2StartY + 75);
  currentLen += ctx.measureText("Quotes").width;
  currentLen += 10;
  ctx.fillStyle = "white";
  ctx.font = fonts["Noto-Bold.ttf"].toCanvasString(18);
  ctx.fillText(utils.formatNumberK(likes), currentLen, base2StartY + 75);
  currentLen += ctx.measureText(utils.formatNumberK(likes)).width;
  currentLen += 5;
  ctx.fillStyle = "#71767b";
  ctx.font = fonts["Noto-Regular.ttf"].toCanvasString(18);
  ctx.fillText("Likes", currentLen, base2StartY + 75);
  currentLen += ctx.measureText("Likes").width;
  currentLen += 10;
  ctx.fillStyle = "white";
  ctx.font = fonts["Noto-Bold.ttf"].toCanvasString(18);
  ctx.fillText(utils.formatNumberK(bookmarks), currentLen, base2StartY + 75);
  currentLen += ctx.measureText(utils.formatNumberK(bookmarks)).width;
  currentLen += 5;
  ctx.fillStyle = "#71767b";
  ctx.font = fonts["Noto-Regular.ttf"].toCanvasString(18);
  ctx.fillText("Bookmarks", currentLen, base2StartY + 75);
  if (userData.avatarShape === "Circle") {
    ctx.beginPath();
    ctx.arc(17 + 26, 84 + 26, 26, 0, Math.PI * 2);
    ctx.closePath();
    ctx.clip();
  } else {
    roundedPath(ctx, 5, 17, 84, 52, 52);
    ctx.clip();
  }
  ctx.drawImage(avatar, 17, 84, 52, 52);

  return canvas.toBuffer('image/png');
}

function roundedPath(
  ctx: SKRSContext2D,
  radius: number,
  x: number,
  y: number,
  imageWidth: number,
  imageHeight: number,
) {
  ctx.beginPath();
  ctx.moveTo(x + radius, y);
  ctx.lineTo(x + imageWidth - radius, y);
  ctx.quadraticCurveTo(x + imageWidth, y, x + imageWidth, y + radius);
  ctx.lineTo(x + imageWidth, y + imageHeight - radius);
  ctx.quadraticCurveTo(
    x + imageWidth,
    y + imageHeight,
    x + imageWidth - radius,
    y + imageHeight,
  );
  ctx.lineTo(x + radius, y + imageHeight);
  ctx.quadraticCurveTo(x, y + imageHeight, x, y + imageHeight - radius);
  ctx.lineTo(x, y + radius);
  ctx.quadraticCurveTo(x, y, x + radius, y);
  ctx.closePath();
  return ctx;
}

async function getUser(user: string) {
  try {
    const guestClient = await api.getGuestClient();
    const { data } = await guestClient.getUserApi().getUserByScreenName({
      screenName: user,
    });
    const body = data.user!.legacy;
    const avatar = await fetch(body.profileImageUrlHttps).then((res) =>
      res.arrayBuffer()
    );
    let checkType = null;
    if (body.verifiedType === "Business") {
      checkType = "business";
    } else if (body.verifiedType === "Government") {
      checkType = "gov";
    } else if (data.user?.isBlueVerified) {
      checkType = "blue";
    }
    const label = data.user?.affiliatesHighlightedLabel.label?.badge?.url;

    return {
      screenName: body.screenName,
      name: body.name,
      avatar: Buffer.from(avatar),
      avatarShape: data.user?.profileImageShape,
      label,
      checkType,
      followers: body.followersCount,
    };
  } catch (error) {
    const defaultPic = await readFile(
      path.join(process.cwd(), "assets", "images", "tweet", "default.png"),
    );
    return {
      screenName: user,
      name: "Unknown User",
      avatar: defaultPic,
      avatarShape: "Circle",
      label: null,
      checkType: null,
      followers: 5,
      error,
    };
  }
}

async function fillTextWithEmoji(
  ctx: SKRSContext2D,
  text: string,
  x: number,
  y: number,
  maxLineLen: number,
  emojiSize: number,
) {
  const wrapped = canvasUtils.wrapText(ctx, text, maxLineLen, true);
  const emoji = text.match(emojiRegex());
  if (!emoji) {
    ctx.fillText(wrapped.join("\n"), x, y);
    fillHashtags(ctx, wrapped, x, y, emojiSize);
    return ctx;
  }
  let currentY = y;
  for (let currentLine = 0; currentLine < wrapped.length; currentLine++) {
    const line = wrapped[currentLine];
    const lineEmoji = line.match(emojiRegex());
    let currentX = x;
    const metrics = ctx.measureText(line);
    if (!lineEmoji) {
      ctx.fillText(line, x, currentY);
      currentY += metrics.emHeightAscent + metrics.emHeightDescent;
      continue;
    }
    const lineNoEmoji = line.split(emojiRegex());
    for (let i = 0; i < lineNoEmoji.length; i++) {
      const linePart = lineNoEmoji[i];
      ctx.fillText(linePart, currentX, currentY);
      currentX += ctx.measureText(linePart).width;
      const parsedEmoji = twemoji.parse(lineEmoji[i]);
      if (!parsedEmoji.length || !parsedEmoji[0].url) continue;
      const body = await fetch(parsedEmoji[0].url).then((res) => res.arrayBuffer());
      const loadedEmoji = await loadImage(Buffer.from(body));
      loadedEmoji.width = emojiSize;
      loadedEmoji.height = emojiSize;
      ctx.drawImage(loadedEmoji, currentX, currentY, emojiSize, emojiSize);
      currentX += emojiSize;
    }
    currentY += metrics.emHeightAscent + metrics.emHeightDescent;
  }
  fillHashtags(ctx, wrapped, x, y, emojiSize);
  return ctx;
}

function fillHashtags(
  ctx: SKRSContext2D,
  wrappedText: string[],
  x: number,
  y: number,
  emojiSize: number,
) {
  let currentY = y;
  for (const line of wrappedText) {
    const words = line.split(" ");
    for (let i = 0; i < words.length; i++) {
      const word = words[i];
      if (!word.startsWith("#") && !word.startsWith("@")) continue;
      if (word.match(emojiRegex())) continue;
      let preWords = words.slice(0, i).join(" ");
      if (i !== 0) preWords += " ";
      const emoji = preWords.match(emojiRegex());
      let preLen = ctx.measureText(preWords.replace(emojiRegex(), "")).width;
      if (emoji) preLen += emoji.length * emojiSize;
      const oldStyle = ctx.fillStyle;
      ctx.fillStyle = "#1da1f2";
      ctx.fillText(word, x + preLen, currentY);
      ctx.fillStyle = oldStyle;
    }
    const metrics = ctx.measureText(line);
    currentY += metrics.emHeightAscent + metrics.emHeightDescent;
  }
  return ctx;
}
