import express from "express";
import bodyParser from "body-parser";
import { kv } from "@vercel/kv";
import { merkleTreeFromTwitterHandles } from "../helpers/twitterMerkle";
import ViteExpress from "vite-express";
import "dotenv/config";

const app = express();

app.get("/api/merkle_trees", async (req, res) => {
  const handle = req.query.handle;
  if (!handle) {
    return res.status(400).json({ error: "missing required fields" });
  }

  const roots = await kv.smembers("handle_to_root_" + handle);
  if (roots.length === 0) {
    return res.status(200).json({});
  }
  console.log(`Found ${roots.length} roots for ${handle}`);
  const trees = await kv.hmget("root_to_merkle_tree", ...roots);
  return res.status(200).json(trees);
});

app.post("/api/merkle_trees", bodyParser.json(), async (req, res) => {
  const { name, handles } = req.body;
  if (!name || !handles) {
    return res.status(400).json({ error: "missing required fields" });
  }
  if (
    typeof name !== "string" ||
    !Array.isArray(handles) ||
    handles.some((handle) => typeof handle !== "string")
  ) {
    return res.status(400).json({ error: "invalid types" });
  }
  if (new Set(handles).size !== handles.length) {
    return res.status(400).json({ error: "handles must be unique" });
  }
  if (
    !name.match(/^[a-zA-Z0-9 ]+$/) ||
    handles.some((handle) => !handle.match(/^[a-zA-Z0-9_-]+$/))
  ) {
    return res.status(400).json({ error: "invalid characters" });
  }

  const sortedHandles = [...handles].sort();
  const merkleTree = await merkleTreeFromTwitterHandles(sortedHandles);
  const root = merkleTree.root.value.toString();
  console.log(`Computed root ${root} from ${sortedHandles}`);

  await kv.hset("root_to_merkle_tree", {
    [root]: JSON.stringify({ name, handles: sortedHandles }),
  });
  await Promise.all(
    sortedHandles.map((handle) => kv.sadd("handle_to_root_" + handle, root))
  );

  return res.status(200).json({ root });
});

ViteExpress.listen(app, 3000, () =>
  console.log("Server listening at http://localhost:3000")
);
