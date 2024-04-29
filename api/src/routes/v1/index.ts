import path from "node:path";
import fs from "node:fs/promises";

import { FastifyPluginCallback } from "fastify";
import { createCanvas, loadImage } from "@napi-rs/canvas";
import fontFinder from "font-finder";

import Font from "../../utils/font.js";

import spotifyNowPlaying from "./spotify-now-playing.js";
import aceAttorney from "./ace-attorney.js";
import achievement from "./achievement.js";
import impostor from "./impostor.js";
import steamNowPlaying from "./steam-now-playing.js";
import triggered from "./triggered.js";
import fusion from "./fusion.js";
import burn from "./burn.js";
import illegal from "./illegal.js";
import sip from "./sip.js";
import tweet from "./tweet.js";

const routes = {
  spotifyNowPlaying: "/spotify-now-playing",
  aceAttorney: "/ace-attorney",
  achievement: "/achievement",
  impostor: "/impostor",
  steamNowPlaying: "/steam-now-playing",
  triggered: "/triggered",
  fusion: "/fusion",
  burn: "/burn",
  illegal: "/illegal",
  sip: "/sip",
  tweet: "/tweet",
};

export const __dirname = path.dirname(new URL(import.meta.url).pathname);

const images = {
  spotifyBaseImage: await loadImage(
    path.join(
      __dirname,
      "..",
      "..",
      "..",
      "assets",
      "images",
      "spotify-now-playing.png",
    ),
  ),
  achievement: await loadImage(
    path.join(
      __dirname,
      "..",
      "..",
      "..",
      "assets",
      "images",
      "achievement.png",
    ),
  ),

  steamNowPlaying: await loadImage(
    path.join(
      __dirname,
      "..",
      "..",
      "..",
      "assets",
      "images",
      "steam-now-playing.png",
    ),
  ),

  steamNowPlayingClassic: await loadImage(
    path.join(
      __dirname,
      "..",
      "..",
      "..",
      "assets",
      "images",
      "steam-now-playing-classic.png",
    ),
  ),

  triggered: await loadImage(
    path.join(
      __dirname,
      "..",
      "..",
      "..",
      "assets",
      "images",
      "triggered.png",
    ),
  ),

  sip: await loadImage(
    path.join(__dirname, "..", "..", "..", "assets", "images", "sip.png"),
  ),
};

export const fonts: Record<string, Font> = {};

async function registerFontsIn(filepath: string) {
  for (const file of await fs.readdir(filepath)) {
    const metadata = await fontFinder.get(path.join(filepath, file));
    const font = new Font(path.join(filepath, file), file, metadata);
    fonts[file] = font;
    font.register();
  }
}

export default (async (app, opts) => {
  await registerFontsIn(
    path.join(__dirname, "..", "..", "..", "assets", "fonts"),
  );

  app.get(routes.spotifyNowPlaying, async (request, reply) => {
    const { imageUrl, songName, artistName, picksName } = request.query as {
      imageUrl?: string;
      songName?: string;
      artistName?: string;
      picksName?: string;
    };
    const { spotifyBaseImage } = images;

    if (!imageUrl || !songName || !artistName) {
      return reply.code(400).send({
        error: "imageUrl, songName and artistName are required",
      });
    }

    const buffer = await spotifyNowPlaying(
      imageUrl,
      songName,
      artistName,
      spotifyBaseImage,
      picksName,
    );

    return reply.header("Content-Type", "image/png").status(200).send(buffer);
  });

  app.get(routes.aceAttorney, async (request, reply) => {
    const { character, quote } = request.query as {
      character?: string;
      quote?: string;
    };

    if (!character || !quote) {
      return reply.code(400).send({
        error: "character and quote are required",
      });
    }

    const buffer = await aceAttorney(character, quote);

    return reply.header("Content-Type", "image/png").status(200).send(buffer);
  });

  app.get(routes.achievement, async (request, reply) => {
    const { text } = request.query as { text?: string };

    if (!text) {
      return reply.code(400).send({
        error: "text is required",
      });
    }

    const buffer = await achievement(text, images.achievement);

    return reply.header("Content-Type", "image/png").status(200).send(buffer);
  });

  app.get(routes.impostor, {
    schema: {
      querystring: {
        type: "object",
        properties: {
          userAvatar: { type: "string" },
          impostor: { type: "boolean" },
          username: { type: "string" },
        },
        required: ["username", "userAvatar"],
      },
    },
  }, async (request, reply) => {
    const { userAvatar: user, impostor: imp, username } = request.query as {
      userAvatar: string;
      username: string;
      impostor?: boolean;
    };

    const userImageR = await fetch(user);
    const userImageB = await userImageR.arrayBuffer();
    const userImage = await loadImage(Buffer.from(userImageB));

    const buffer = await impostor(userImage, username, imp);

    return reply.header("Content-Type", "image/gif").status(200).send(buffer);
  });

  app.route({
    method: "GET",
    url: routes.steamNowPlaying,
    schema: {
      querystring: {
        type: "object",
        properties: {
          gameName: { type: "string" },
          username: { type: "string" },
          imageUrl: { type: "string" },
          classic: { type: "boolean" },
        },
        required: ["gameName", "username", "imageUrl"],
      },
    },
    handler: async (request, reply) => {
      const { gameName, username, imageUrl, classic = false } = request
        .query as {
          gameName: string;
          username: string;
          imageUrl: string;
          classic?: boolean;
        };

      const buffer = await steamNowPlaying(
        !classic ? images.steamNowPlaying : images.steamNowPlayingClassic,
        gameName,
        username,
        imageUrl,
        classic,
      );

      return reply.header("Content-Type", "image/png").status(200).send(buffer);
    },
  });

  app.get(routes.triggered, async (request, reply) => {
    const { imageUrl } = request.query as { imageUrl?: string };

    if (!imageUrl) {
      return reply.code(400).send({
        error: "imageUrl is required",
      });
    }

    const buffer = await triggered(images.triggered, imageUrl);

    return reply.header("Content-Type", "image/gif").status(200).send(buffer);
  });

  app.get(routes.fusion, async (request, reply) => {
    const { imageUrl, imageUrl2 } = request.query as {
      imageUrl?: string;
      imageUrl2?: string;
    };

    if (!imageUrl || !imageUrl2) {
      return reply.code(400).send({
        error: "imageUrl and imageUrl2 are required",
      });
    }

    const buffer = await fusion(imageUrl, imageUrl2);

    return reply.header("Content-Type", "image/png").status(200).send(buffer);
  });

  // Too slow
  // app.get(routes.burn, async (request, reply) => {
  //   const { imageUrl } = request.query as { imageUrl?: string };

  //   if (!imageUrl) {
  //     return reply.code(400).send({
  //       error: "imageUrl is required",
  //     });
  //   }

  //   const buffer = await burn(imageUrl);

  //   return reply.header("Content-Type", "image/gif").status(200).send(buffer);
  // });

  app.get(routes.illegal, async (request, reply) => {
    const { text, verb } = request.query as { text?: string; verb?: string };

    if (!text) {
      return reply.code(400).send({
        error: "text is required",
      });
    }

    const buffer = await illegal(text, verb as "is" | "are" | "am");

    return reply.header("Content-Type", "image/png").status(200).send(buffer);
  });

  app.get(routes.sip, {
    schema: {
      querystring: {
        type: "object",
        properties: {
          imageUrl: { type: "string" },
          direction: {
            // Enum, left or right
            type: "string",
            enum: ["left", "right"],
          },
        },
        required: ["imageUrl", "direction"],
      },
    },
  }, async (request, reply) => {
    const { imageUrl, direction } = request.query as {
      imageUrl: string;
      direction: "left" | "right";
    };

    const buffer = await sip(images.sip, imageUrl, direction);

    return reply.header("Content-Type", "image/png").status(200).send(buffer);
  });

  app.get(routes.tweet, {
    schema: {
      querystring: {
        type: "object",
        properties: {
          imageUrl: { type: "string" },
          user: { type: "string" },
          text: { type: "string" },
        },
        required: ["user", "text"],
      },
    },
  }, async (request, reply) => {
    const { imageUrl, user, text } = request.query as {
      imageUrl?: string;
      user: string;
      text: string;
    };

    const buffer = await tweet(user, text, imageUrl);

    return reply.header("Content-Type", "image/png").status(200).send(buffer);
  });
}) as FastifyPluginCallback;
