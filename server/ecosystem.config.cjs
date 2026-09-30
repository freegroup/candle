// pm2 configuration. The file name must end in ".config.cjs" (or .js), otherwise
// pm2 starts it as a plain script instead of reading it as ecosystem file.
module.exports = {
  apps: [
    {
      name: 'candle-api',
      cwd: __dirname,
      script: 'src/server.ts',
      // explicit: pm2 would pick another interpreter for .ts files; node runs TypeScript itself
      interpreter: 'node',
      node_args: '--env-file=.env',
      max_memory_restart: '300M',
    },
  ],
};
