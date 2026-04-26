#!/usr/bin/env node

import pc from "picocolors";
import { Command } from "commander";
import { loadDeployEnv } from "./scripts/load_deploy_env.mjs";
import { runCommand } from "./scripts/run.mjs";

const program = new Command();

program
  .name("actions")
  .description("Install Fastlane gems and run bundle exec fastlane")
  .option("-p, --production", "use _PROD env vars")
  .argument("[fastlaneArgs...]", "arguments passed to fastlane, e.g. ios adhoc")
  .action(async (args, options) => {
    try {
      await runCommand(args, options);
    } catch (e) {
      program.error(e.message);
    }
  });

loadDeployEnv();
program.parse();

process.on("exit", (code) => {
  if (code === 1) console.log(pc.dim(`👋  ${pc.italic('Exiting...')}`));
});
