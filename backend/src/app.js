const express = require("express");
const morgan = require("morgan");
const helmet = require("helmet");
const cors = require("cors");
const cookieParser = require("cookie-parser");

const app = express();

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
if (process.env.NODE_ENV !== "production") app.use(morgan("dev"));

// Simple health check
app.get("/health", (req, res) => res.json({ status: "ok" }));

// Example API routes (replace with routers split into modules)
const restaurants = [
  { id: 1, name: "Pasta Palace" },
  { id: 2, name: "Curry Corner" },
];

app.get("/api/restaurants", (req, res) => {
  res.json(restaurants);
});

app.get("/api/restaurants/:id", (req, res) => {
  const found = restaurants.find((r) => r.id === parseInt(req.params.id));
  if (!found) return res.status(404).json({ message: "Not found" });
  res.json(found);
});

// Simple orders endpoint (in-memory example)
let orders = [];
app.post("/api/orders", (req, res) => {
  const { customer, items } = req.body;
  if (!customer || !Array.isArray(items) || items.length === 0) {
    return res.status(400).json({ message: "Invalid order payload" });
  }
  const order = {
    id: orders.length + 1,
    customer,
    items,
    status: "pending",
    createdAt: new Date(),
  };
  orders.push(order);
  res.status(201).json(order);
});

// 404 handler
app.use((req, res, next) => {
  res.status(404).json({ message: "Not Found" });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err);
  res
    .status(err.status || 500)
    .json({ message: err.message || "Internal Server Error" });
});

module.exports = app;
