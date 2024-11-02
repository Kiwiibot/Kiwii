const utils = {
  randomRange(min: number, max: number): number {
    return Math.floor(Math.random() * (max - min + 1)) + min;
  },

  formatNumberK(bytes: number, decimals: number = 2): string {
    if (bytes == 0) {
      return "0 Bytes";
    }

    const k = 1024;
    const dm = decimals < 0 ? 0 : decimals;
    const sizes = ["Bytes", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];

    const i = Math.floor(Math.log(bytes) / Math.log(k));

    return `${(bytes / k ** i).toFixed(dm)} ${sizes[i]}`;
  },
};

console.log(utils.formatNumberK(1024 * 1024 * 1024 * 1024));

export default utils;
