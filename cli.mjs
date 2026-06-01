#!/usr/bin/env node

import pc from "picocolors";
import { Command } from "commander";
import { loadDeployEnv } from "./scripts/load_deploy_env.mjs";
import { clearBuilds } from "./scripts/clear_builds.mjs";
import { runCommand, runBundle } from "./scripts/run.mjs";
import { setSecrets } from "./scripts/set_secrets.mjs";

const program = new Command();

program
  .name("actions")
  .description("Install Fastlane gems and run bundle exec fastlane")
  .option("-p, --production", "use _PROD env vars")
  .option("--clean", "clean build directories before running fastlane")
  .argument("[fastlaneArgs...]", "arguments passed to fastlane, e.g. ios adhoc")
  .action(async (args, options) => {
    const isAndroid = args.includes("android");

    try {
      loadDeployEnv();
      if (options.clean) await clearBuilds(isAndroid ? 'android' : 'ios');
      await runCommand(args, options);
    } catch (e) {
      program.error(e.message);
    }
  });

program
  .command("clean")
  .description("Clear build directories")
  .option("--platform <type>", "clean build directories for <type>, android/ios/all", "all")
  .action(async (options) => {
    try {
      await clearBuilds(options.platform);
    } catch (e) {
      program.error(e.message);
    }
  });

program
  .command("bundle")
  .description("Run bundler commands directly in the fastlane environment")
  .argument("[bundleArgs...]", "arguments passed to bundle, e.g. install")
  .action(async (bundleArgs) => {
    try {
      loadDeployEnv();
      const options = program.opts();
      await runBundle(bundleArgs, options);
    } catch (e) {
      program.error(e.message);
    }
  });

program
  .command("set-secrets")
  .description("Write secrets from .env.deploy in pwd to the GitHub repository secrets")
  .action(async () => {
    try {
      await setSecrets();
    } catch (e) {
      program.error(e.message);
    }
  });

program.parse();

process.on("exit", (code) => {
  if (code === 1) console.log(pc.dim(`👋  ${pc.italic('Exiting...')}`));
});
