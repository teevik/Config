import * as path from "node:path";

export function isPathInside(candidate: string, dir: string): boolean {
  const relative = path.relative(path.resolve(dir), path.resolve(candidate));
  return relative === "" || (!relative.startsWith("..") && !path.isAbsolute(relative));
}
