#!/usr/bin/env node

const { spawnSync, execSync } = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");
const { Command } = require("commander");
const dotenv = require("dotenv");

const program = new Command();
const packageRoot = path.resolve(__dirname, "..", "..");
const fastlaneDir = __dirname;
const fastlaneCwd = path.dirname(fastlaneDir);
const githubRepoPattern = /github\.com[:/]([^/]+\/[^/]+?)(?:\.git)?$/;

function loadDeployEnv() {
  const envPath = path.join(process.cwd(), ".env.deploy");

  if (!fs.existsSync(envPath)) {
    return;
  }

  dotenv.config({
    path: envPath,
    override: false,
  });
}

const callerWorkspace = process.cwd();
function getWorkspaceEnv(options = {}) {
  const remoteOriginUrl = execSync("git config --get remote.origin.url", {
    cwd: callerWorkspace,
  })
    .toString()
    .trim();
  const currentBranch = execSync("git rev-parse --abbrev-ref HEAD", {
    cwd: callerWorkspace,
  })
    .toString()
    .trim();

  const githubRepositoryMatch = remoteOriginUrl.match(githubRepoPattern);
  const scheme = options.production
    ? process.env.SCHEME_PROD || process.env.SCHEME_DEV
    : process.env.SCHEME_DEV;
  const workspaceName = options.production
    ? process.env.WORKSPACE_NAME_PROD || process.env.WORKSPACE_NAME_DEV
    : process.env.WORKSPACE_NAME_DEV;
  const appIdentifier = options.production
    ? process.env.APP_IDENTIFIER_PROD || process.env.APP_IDENTIFIER_DEV
    : process.env.APP_IDENTIFIER_DEV;
  const firebaseIosAppId = options.production
    ? process.env.FIREBASE_IOS_APP_ID_PROD ||
      process.env.FIREBASE_IOS_APP_ID_DEV
    : process.env.FIREBASE_IOS_APP_ID_DEV;
  const firebaseAndroidAppId = options.production
    ? process.env.FIREBASE_ANDROID_APP_ID_PROD ||
      process.env.FIREBASE_ANDROID_APP_ID_DEV
    : process.env.FIREBASE_ANDROID_APP_ID_DEV;
  const firebaseCredentials = options.production
    ? process.env.FIREBASE_CREDENTIALS_PROD ||
      process.env.FIREBASE_CREDENTIALS_DEV
    : process.env.FIREBASE_CREDENTIALS_DEV;

  const env = {
    ...process.env,
    BUILD_ENVIRONMENT: options.production ? "production" : "development",
    APP_IDENTIFIER: appIdentifier,
    FIREBASE_IOS_APP_ID: firebaseIosAppId,
    FIREBASE_ANDROID_APP_ID: firebaseAndroidAppId,
    FIREBASE_CREDENTIALS: firebaseCredentials,
    GITHUB_REF_NAME: process.env.GITHUB_REF_NAME || currentBranch,
    GITHUB_REPOSITORY:
      process.env.GITHUB_REPOSITORY || githubRepositoryMatch?.[1],
    GITHUB_WORKSPACE: process.env.GITHUB_WORKSPACE || callerWorkspace,
    WORKSPACE_PATH: process.env.WORKSPACE_PATH || "/ios",
    ANDROID_PROJECT_PATH: process.env.ANDROID_PROJECT_PATH || "/android",
    SCHEME: scheme,
    WORKSPACE_NAME: workspaceName,
    BUNDLE_GEMFILE:
      process.env.BUNDLE_GEMFILE || path.join(fastlaneDir, "Gemfile"),
    BUNDLE_PATH:
      process.env.BUNDLE_PATH || path.join(packageRoot, "vendor", "bundle"),
    BUNDLE_FORCE_RUBY_PLATFORM:
      process.env.BUNDLE_FORCE_RUBY_PLATFORM || "true",
    FASTLANE_FASTFILE: path.join(fastlaneDir, "Fastfile"),
  };

  return env;
}

loadDeployEnv();

function run(command, args, env) {
  const result = spawnSync(command, args, {
    cwd: fastlaneCwd,
    stdio: "inherit",
    env,
  });

  if (result.error) {
    throw result.error;
  }

  if (typeof result.status === "number" && result.status !== 0) {
    process.exit(result.status);
  }
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
  const beforeAll = commandOrOptions.production
    ? process.env.BEFORE_ALL_PROD || process.env.BEFORE_ALL_DEV
    : process.env.BEFORE_ALL_DEV;
  const env = getWorkspaceEnv(commandOrOptions);
  installBundle(env);
  if (beforeAll && commandOrOptions.clean) {
    execSync(beforeAll, { cwd: callerWorkspace, stdio: "inherit", env });
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

program.parse();
