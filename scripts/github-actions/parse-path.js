/**
 * @typedef Params
 * @property {typeof import("@actions/core")} core
 * @property {string} path
 *
 * @param {Params} params
 */
function parsePath({ core, path }) {
  const segments = path.split("/");

  if (segments.length !== 3 || segments.includes("")) {
    core.setFailed(
      `Invalid path: "${path}". A valid path must be in the format of "samples/<ModuleFolder>/<ModuleName>".`
    );
  }

  const modulePathSegmentRegex = /^[a-z0-9]+([._-][a-z0-9]+)*$/;
  const moduleFolder = segments[1];
  const moduleName = segments[2];

  if (!modulePathSegmentRegex.test(moduleFolder)) {
    core.setFailed(
      `The module folder "${moduleFolder}" in the path "${path}" is invalid. It must match the regex "${modulePathSegmentRegex}".`
    );
  }

  if (!modulePathSegmentRegex.test(moduleName)) {
    core.setFailed(
      `The module name "${moduleName}" in the path "${path}" is invalid. It must match the regex "${modulePathSegmentRegex}".`
    );
  }

  core.setOutput("module_folder", moduleFolder);
  core.setOutput("module_name", moduleName);
  core.setOutput("module_path", `${moduleFolder}/${moduleName}`);
}

module.exports = parsePath;
