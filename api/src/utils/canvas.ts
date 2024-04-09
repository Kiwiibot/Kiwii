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

  wrapText(ctx: SKRSContext2D, text: string, maxWidth: number) {
    if (ctx.measureText(text).width < maxWidth) return [text];
    if (ctx.measureText("W").width > maxWidth) return null;
    const words = text.split(" ");
    const lines = [];
    let line = "";

    while (words.length > 0) {
      let split = false;

      while (ctx.measureText(words[0]).width >= maxWidth) {
        const temp = words[0];
        words[0] = temp.slice(0, -1);
        if (split) {
          words[1] = `${temp.slice(-1)}${words[1]}`;
        } else {
          split = true;
          words.splice(1, 0, temp.slice(-1));
        }
      }

      if (ctx.measureText(`${line}${words[0]}`).width < maxWidth) {
        line += `${words.shift()} `;
      } else {
        lines.push(line.trim());
        line = "";
      }

      if (words.length === 0) lines.push(line.trim());
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
