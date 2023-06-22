import { kv } from "@vercel/kv";
import { merkleTreeFromTwitterHandles } from "src/helpers/twitterMerkle";
import type { VercelRequest, VercelResponse } from "@vercel/node";

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method === "GET") {
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
  }

  if (req.method === "POST") {
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
  }

  return res.status(405).json({ error: "method not allowed" });
}
