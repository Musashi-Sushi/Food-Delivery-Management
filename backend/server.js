const http = require("http");
require("dotenv").config();

// Simple DB connect placeholder — replace with your DB module if you have one
// const connectDB = require('./config/db');
// connectDB();

const app = require("./src/app.js");

const normalizePort = (val) => {
  const port = parseInt(val, 10);
  if (isNaN(port)) return val;
  if (port >= 0) return port;
  return false;
};

const port = normalizePort(process.env.PORT || "5000");
app.set("port", port);

const server = http.createServer(app);

server.listen(port, () => {
  console.log(`Server listening on ${port}`);
});

server.on("error", (err) => {
  if (err.syscall !== "listen") throw err;
  const bind = typeof port === "string" ? `Pipe ${port}` : `Port ${port}`;
  switch (err.code) {
    case "EACCES":
      console.error(`${bind} requires elevated privileges`);
      process.exit(1);
      break;
    case "EADDRINUSE":
      console.error(`${bind} is already in use`);
      process.exit(1);
      break;
    default:
      throw err;
  }
});

process.on("unhandledRejection", (reason, promise) => {
  console.error("Unhandled Rejection at:", promise, "reason:", reason);
  // optional: graceful shutdown
});

process.on("uncaughtException", (err) => {
  console.error("Uncaught Exception:", err);
  process.exit(1);
});
