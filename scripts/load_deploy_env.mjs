import path from "node:path";
import fs from "node:fs";
import dotenv from "dotenv";
import pc from "picocolors"

const callerWorkspace = process.cwd();

export function loadDeployEnv() {
  const envPath = path.join(callerWorkspace, ".env.deploy");
  if (!fs.existsSync(envPath)) return;
  dotenv.config({ path: envPath, override: true, quiet: true });
  console.log(pc.green(`⚙️   Loaded env from ${pc.bold(path.relative(process.cwd(), envPath))}`));
}