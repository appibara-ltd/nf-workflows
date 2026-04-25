#!/usr/bin/env node

const { spawnSync, execSync } = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");
const { Command } = require("commander");
const dotenv = require("dotenv");

const callerWorkspace = process.cwd();
const program = new Command();
const fastlaneDir = __dirname;
const fastlaneCwd = path.dirname(fastlaneDir);
const githubRepoPattern = /github\.com[:/]([^/]+\/[^/]+?)(?:\.git)?$/;

function loadDeployEnv() {
  const envPath = path.join(callerWorkspace, ".env.deploy");
  if (!fs.existsSync(envPath)) return;
  dotenv.config({ path: envPath, override: true });
}

function getWorkspaceEnv(options = {}) {
  const execOptions = { cwd: callerWorkspace };
  const remoteOriginUrl = execSync("git config --get remote.origin.url", execOptions)
    .toString()
    .trim();
  const currentBranch = execSync("git rev-parse --abbrev-ref HEAD", execOptions)
    .toString()
    .trim();

  const githubRepositoryMatch = remoteOriginUrl.match(githubRepoPattern)?.[1];
  const buildType = options.production ? "PROD" : "DEV";

  return {
    ...process.env,
    BEFORE_ALL: process.env[`BEFORE_ALL_${buildType}`],
    SCHEME: process.env[`SCHEME_${buildType}`],
    WORKSPACE_NAME: process.env[`WORKSPACE_NAME_${buildType}`],
    APP_IDENTIFIER: process.env[`APP_IDENTIFIER_${buildType}`],
    FIREBASE_IOS_APP_ID: process.env[`FIREBASE_IOS_APP_ID_${buildType}`],
    BUILD_ENVIRONMENT: options.production ? "production" : "development",
    FIREBASE_CREDENTIALS: process.env[`FIREBASE_CREDENTIALS_${buildType}`],
    FIREBASE_ANDROID_APP_ID: process.env[`FIREBASE_ANDROID_APP_ID_${buildType}`],
    GITHUB_REF_NAME: process.env.GITHUB_REF_NAME || currentBranch,
    GITHUB_REPOSITORY: process.env.GITHUB_REPOSITORY || githubRepositoryMatch,
    GITHUB_WORKSPACE: process.env.GITHUB_WORKSPACE || callerWorkspace,
    WORKSPACE_PATH: process.env.WORKSPACE_PATH || `${callerWorkspace}/ios`,
    ANDROID_PROJECT_PATH: process.env.ANDROID_PROJECT_PATH || `${callerWorkspace}/android`,
    BUNDLE_GEMFILE: process.env.BUNDLE_GEMFILE || path.join(fastlaneDir, "Gemfile"),
    BUNDLE_PATH: process.env.BUNDLE_PATH || path.join(callerWorkspace, "vendor", "bundle"),
    BUNDLE_FORCE_RUBY_PLATFORM: process.env.BUNDLE_FORCE_RUBY_PLATFORM || "true",
    FASTLANE_FASTFILE: path.join(fastlaneDir, "Fastfile")
  };
}

function run(command, args, env) {
  const result = spawnSync(command, args, { cwd: fastlaneCwd, stdio: "inherit", env, });
  if (result.error) throw result.error;
  if (typeof result.status === "number" && result.status !== 0) process.exit(result.status);
}

function installBundle(env) {
  run("bundle", ["install"], env);
}

function runFastlane(fastlaneArgs, env) {
  if (fastlaneArgs.length === 0) {
    program.error(
      "Fastlane arguments are required. Example: actions ios adhoc",
    );
  }

  run("bundle", ["exec", "fastlane", ...fastlaneArgs], env);
}

function execute(fastlaneArgs, commandOrOptions) {
  const env = getWorkspaceEnv(commandOrOptions);
  installBundle(env);
  if (env.BEFORE_ALL && commandOrOptions.clean) {
    execSync(env.BEFORE_ALL, { cwd: callerWorkspace, stdio: "inherit", env });
  }
  runFastlane(fastlaneArgs, env);
}

program
  .name("actions")
  .description("Install Fastlane gems and run bundle exec fastlane")
  .option("-p, --production", "use _PROD env vars")
  .option("-c, --clean", "run beforeall to clean start")
  .argument("[fastlaneArgs...]", "arguments passed to fastlane, e.g. ios adhoc")
  .action(execute);

program
  .command("install")
  .description(
    "Run bundle install with workflow-compatible bundler environment",
  )
  .action(() => {
    installBundle(getWorkspaceEnv());
  });

program
  .command("run")
  .description("Run bundle install, then bundle exec fastlane")
  .option("-p, --production", "use _PROD env vars")
  .option("-c, --clean", "run beforeall to clean start")
  .argument("[fastlaneArgs...]", "arguments passed to fastlane")
  .action(execute);

function main() {
  loadDeployEnv();
  program.parse();
}

main();