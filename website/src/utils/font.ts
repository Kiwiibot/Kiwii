import { GlobalFonts } from "@napi-rs/canvas";

const weights = {
  100: "thin",
  200: "extraLight",
  300: "light",
  400: "normal",
  500: "medium",
  600: "semiBold",
  700: "bold",
  800: "extraBold",
  900: "heavy",
  950: "extraBlack",
};
const fallbacks = ["Symbola", "Noto-CJK"];

export default class Font {
  public name: string;
  public style: string;
  public weight: string;
  public type: string;
  public registered: boolean;
  public fallbacks: string[];
  public constructor(
    public path: string,
    public filename: string,
    public metadata: {
      style: string;
      weight: number | string;
      type: string;
      name: string;
    },
  ) {
    this.name = metadata.name || filename;
    this.style = metadata.style === "regular"
      ? "normal"
      : metadata.style || "normal";
    //@ts-expect-error
    this.weight = weights[metadata.weight] || metadata.weight || "normal";
    this.type = metadata.type;
    this.registered = false;
    this.fallbacks = fallbacks.filter((fallback) =>
      fallback !== this.filenameNoExt
    );
  }

  register() {
    if (this.registered) return null;
    this.registered = true;
    return GlobalFonts.registerFromPath(this.path, this.filenameNoExt);
  }

  public toCanvasString(size: number, shouldDoFallback = true) {
    const shouldFall = shouldDoFallback ? `, ${this.fallbacks.join(", ")}` : "";

    // Return the font string, for skia-canvas
    return `${this.weight} ${this.style} ${size}px ${this.filenameNoExt}${shouldFall}`
  }

  get filenameNoExt() {
    return this.filename.replace(/(\.(otf|ttf))$/, "");
  }

  get isFallback() {
    return fallbacks.includes(this.filenameNoExt);
  }
}
