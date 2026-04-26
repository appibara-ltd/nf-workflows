import { spawn } from "node:child_process";

export function registerProcessSignals(cleanupFn) {
  process.on('exit', cleanupFn);
  process.on('SIGINT', cleanupFn);
  process.on('SIGTERM', cleanupFn);

  return () => {
    process.removeListener('exit', cleanupFn);
    process.removeListener('SIGINT', cleanupFn);
    process.removeListener('SIGTERM', cleanupFn);
  };
}

export async function spawnProcess(command, args, options = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, options);

    const killChild = () => {
      if (!child.killed) child.kill('SIGTERM');
    };

    const cleanupListeners = registerProcessSignals(killChild);

    child.on('error', (err) => {
      cleanupListeners();
      reject(err);
    });

    child.on('exit', (code) => {
      cleanupListeners();
      resolve(code);
    });
  });
}
