import type { Image, SKRSContext2D } from "@napi-rs/canvas";

export default {
  greyscale(
    ctx: SKRSContext2D,
    x: number,
    y: number,
    width: number,
    height: number,
  ): SKRSContext2D {
    const data = ctx.getImageData(x, y, width, height);

    for (let i = 0; i < data.data.length; i += 4) {
      const brightness = (0.34 * data.data[i]) + (0.5 * data.data[i + 1]) +
        (0.16 * data.data[i + 2]);
      data.data[i] = brightness;
      data.data[i + 1] = brightness;
      data.data[i + 2] = brightness;
    }

    ctx.putImageData(data, x, y);
    return ctx;
  },

  invert(
    ctx: SKRSContext2D,
    x: number,
    y: number,
    width: number,
    height: number,
  ): SKRSContext2D {
    const data = ctx.getImageData(x, y, width, height);

    for (let i = 0; i < data.data.length; i += 4) {
      data.data[i] = 255 - data.data[i];
      data.data[i + 1] = 255 - data.data[i + 1];
      data.data[i + 2] = 255 - data.data[i + 2];
    }

    ctx.putImageData(data, x, y);
    return ctx;
  },

  silhouette(
    ctx: SKRSContext2D,
    x: number,
    y: number,
    width: number,
    height: number,
  ): SKRSContext2D {
    const data = ctx.getImageData(x, y, width, height);

    for (let i = 0; i < data.data.length; i += 4) {
      data.data[i] = 0;
      data.data[i + 1] = 0;
      data.data[i + 2] = 0;
    }

    ctx.putImageData(data, x, y);
    return ctx;
  },

  wrapText(
    ctx: SKRSContext2D,
    text: string,
    maxWidth: number,
    shouldChunk = false,
  ) {
    const lines = [];
    const wordsAndBreaks = text.split("\n");
    for (let i = 0; i < wordsAndBreaks.length; i++) {
      const segment = wordsAndBreaks[i];
      if (segment === "") {
        lines.push("");
        continue;
      }
      const words = segment.split(" ");
      let currentLine = "";
      for (let j = 0; j < words.length; j++) {
        const word = words[j];
        if (ctx.measureText(`${currentLine} ${word}`).width <= maxWidth) {
          currentLine += `${currentLine === "" ? "" : " "}${word}`;
        } else if (ctx.measureText(word).width > maxWidth && shouldChunk) {
          const chunks = [];
          let currentChunk = "";
          for (let k = 0; k < word.length; k++) {
            const char = word[k];
            if (ctx.measureText(`${currentChunk}${char}`).width <= maxWidth) {
              currentChunk += char;
            } else {
              chunks.push(currentChunk);
              currentChunk = char;
            }
          }
          if (currentChunk !== "") {
            chunks.push(currentChunk);
          }
          for (let k = 0; k < chunks.length; k++) {
            if (
              ctx.measureText(`${currentLine} ${chunks[k]}`).width > maxWidth
            ) {
              lines.push(currentLine.trim());
              currentLine = "";
            }
            currentLine += `${currentLine === "" ? "" : " "}${chunks[k]}`;
          }
        } else {
          if (currentLine !== "") lines.push(currentLine.trim());
          currentLine = word;
        }
      }
      if (currentLine !== "") {
        lines.push(currentLine.trim());
      }
    }
    return lines;
  },

  drawImageWithTint(
    ctx: SKRSContext2D,
    image: Image,
    color: string,
    x: number,
    y: number,
    width: number,
    height: number,
  ) {
    const { fillStyle, globalAlpha } = ctx;
    ctx.fillStyle = color;
    ctx.drawImage(image, x, y, width, height);
    ctx.globalAlpha = 0.5;
    ctx.fillRect(x, y, width, height);
    ctx.fillStyle = fillStyle;
    ctx.globalAlpha = globalAlpha;
    return ctx;
  },

  streamToArray(stream: NodeJS.ReadableStream): Promise<Buffer[]> {
    if (!stream.readable) return Promise.resolve([]);

    return new Promise((resolve, reject) => {
      const array: Buffer[] = [];
      function onData(data: Buffer) {
        array.push(data);
      }
      function onEnd(error: Error) {
        if (error) reject(error);
        else resolve(array);
        cleanup();
      }
      function onClose() {
        resolve(array);
        cleanup();
      }

      function cleanup() {
        stream.off("data", onData);
        stream.off("end", onEnd);
        stream.off("error", onEnd);
        stream.off("close", onClose);
      }

      stream.on("data", onData);
      stream.on("end", onEnd);
      stream.on("error", onEnd);
      stream.on("close", onClose);
    });
  },
};
