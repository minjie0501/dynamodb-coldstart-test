const DEFAULT_ESBUILD_OPTIONS = {
  bundle: true,
  minify: true,
  keepNames: true,
  sourcemap: "linked",
  platform: "node",
  target: "esnext",
  packagePath: "./package.json",
  packager: "npm",
  exclude: ["fsevents"],
};

module.exports = async ({ options }) => {
  // We are running a local test function?
  const isLocalTesting = !!options.function;
  return isLocalTesting
    ? DEFAULT_ESBUILD_OPTIONS
    : {
        ...DEFAULT_ESBUILD_OPTIONS,
        exclude: ["fsevents", "@aws-sdk/*"],
        format: "esm",
        outputFileExtension: ".mjs",
        banner: {
          js: `
import path from 'path';
import { fileURLToPath } from 'url';
import { createRequire as topLevelCreateRequire } from 'module';
const require = topLevelCreateRequire(import.meta.url);
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
				 `,
        },
      };
};
