import { kv } from "@vercel/kv";
import type { VercelRequest, VercelResponse } from "@vercel/node";
import { buildPoseidon, buildMimcSponge } from "circomlibjs";

interface Hasher {
  (data: string[]): Promise<BigInt>;
}

// hack to allow bigints to be debugged.
// @ts-ignore
BigInt.prototype.toJSON = function () {
  return this.toString();
};

class JSONTree {
  public root: JSONNode;
  public nodes: JSONNode[];

  constructor(root: JSONNode, nodes: JSONNode[]) {
    this.root = root;
    this.nodes = nodes;
  }
}

// A representation of a node which is safe to be output as JSON (contains no cycles).
class JSONNode {
  public value: BigInt;
  public left?: BigInt;
  public right?: BigInt;
  public parent?: BigInt;

  constructor(value: BigInt, left?: BigInt, right?: BigInt, parent?: BigInt) {
    this.value = value;
    this.left = left;
    this.right = right;
    this.parent = parent;
  }
}

class Node {
  public value: BigInt;
  public left?: Node; // left child
  public right?: Node; // right child
  public parent?: Node; // parent
  public label?: string; // label for leaf nodes

  constructor(value: BigInt, left?: Node, right?: Node, parent?: Node) {
    this.value = value;
    this.left = left;
    this.right = right;
    this.parent = parent;
  }

  public toJSONNode(): JSONNode {
    return new JSONNode(
      this.value,
      this.left?.value,
      this.right?.value,
      this.parent?.value
    );
  }
}

// A public representation of a merkle proof
interface MerkleProof {
  values: BigInt[];
  indexHints: number[]; // 0 if proofVal on left, 1 if proofVal on right
}

// A representation of a merkle tree
class MerkleTree {
  public root: Node;
  public leaves: Node[];
  private hasher: Hasher;
  public levels: number;

  // builds a merkle tree from an existing representation of items.
  constructor(root: Node, leaves: Node[], hasher: Hasher) {
    this.root = root;
    this.leaves = leaves;
    this.hasher = hasher;
    this.levels = Math.log2(leaves.length);
  }

  public static async newFromStringLeaves(
    leaves: string[],
    hasher: Hasher
  ): Promise<MerkleTree> {
    const intVals = leaves.map(async (leaf) => {
      return await hasher([leaf]);
    });

    const resolved = await Promise.all(intVals);

    return this.newFromLeaves(resolved, leaves, hasher);
  }

  public static async newFromLeaves(
    leaves: BigInt[],
    labels: string[],
    hasher: Hasher,
    levels: number = 5
  ): Promise<MerkleTree> {
    console.log(`building new tree of ${levels} levels`);
    const numLeaves = 2 ** levels;
    if (leaves.length > numLeaves)
      throw new Error(
        `too many leaves ${leaves.length} > 2 ** ${levels} (${numLeaves}))`
      );
    const nodes = Array.from(
      { ...leaves, length: numLeaves },
      (x) => new Node(x || 0n)
    );
    labels.forEach((label, i) => {
      nodes[i].label = label;
    });
    const buildResult = await MerkleTree.buildTree(nodes, hasher);
    const root = buildResult[0];

    // pass back to main constructor
    return new MerkleTree(root, nodes, hasher);
  }

  // builds a tree given a level
  private static async buildTree(
    leaves: Node[],
    hasher: Hasher
  ): Promise<Node[]> {
    // we are at the root
    if (leaves.length == 1) return leaves;

    let parents: Node[] = [];

    for (let i = 0; i < leaves.length; i += 2) {
      let l = leaves[i];
      let r = leaves[i + 1];

      let hash = await hasher([l.value.toString(), r.value.toString()]);
      let parent = new Node(hash, l, r);

      l.parent = parent;
      r.parent = parent;
      parents.push(parent);
    }
    return this.buildTree(parents, hasher);
  }

  public async getMerkleProofForString(leafVal: string): Promise<MerkleProof> {
    const intVal = await this.hasher([leafVal]);
    return this.getMerkleProof(intVal);
  }

  public toJSON(): string {
    const tree = new JSONTree(
      this.root.toJSONNode(),
      this.leaves.map((node) => node.toJSONNode())
    );

    return JSON.stringify(tree, null, 4);
  }

  public getMerkleProof(leafVal: BigInt | string): MerkleProof {
    console.log(`getting proof for leaf ${leafVal}`);
    var leaf = MerkleTree.findNode(leafVal, this.leaves);

    if (!leaf) {
      throw new Error("unable to find leaf in tree");
    }

    let proof: MerkleProof = {
      values: new Array<BigInt>(),
      // TODO -- alias this to a nice enum
      indexHints: new Array<number>(),
    };

    while (leaf.value != this.root.value) {
      if (leaf.parent!.left!.value == leaf.value) {
        // Right child
        proof.values.push(leaf.parent!.right!.value);
        proof.indexHints.push(0);
      } else if (leaf.parent!.right!.value == leaf.value) {
        // Left child
        proof.values.push(leaf.parent!.left!.value);
        proof.indexHints.push(1);
      } else {
        throw new Error("unable to finds value in tree");
      }

      // move up in tree.
      leaf = leaf.parent!;
    }

    return proof;
  }

  private static findNode(
    value: BigInt | string,
    nodes: Node[]
  ): Node | undefined {
    return nodes.find((leaf) => leaf.value == value || leaf.label == value);
  }
}

// stringToUint8Array
function stringToBytes(str: string) {
  const encodedText = new TextEncoder().encode(str);
  const toReturn = Uint8Array.from(str, (x) => x.charCodeAt(0));
  //   const buf = Buffer.from(str, "utf8");
  return toReturn;
  // TODO: Check encoding mismatch if the proof doesnt work
  // Note that our custom encoding function maps (239, 191, 189) -> (253)
  // Note that our custom encoding function maps (207, 181) -> (245)
  // throw Error(
  //   "TextEncoder does not match string2bytes function" +
  //     "\n" +
  //     str +
  //     "\n" +
  //     buf +
  //     "\n" +
  //     Uint8Array.from(buf) +
  //     "\n" +
  //     JSON.stringify(encodedText) +
  //     "\n" +
  //     JSON.stringify(toReturn)
  // );
}

function packBytesIntoNBytes(
  messagePaddedRaw: Uint8Array | string,
  n = 7,
  outN = 0
): Array<bigint> {
  const messagePadded: Uint8Array =
    typeof messagePaddedRaw === "string"
      ? stringToBytes(messagePaddedRaw)
      : messagePaddedRaw;
  let output: Array<bigint> = [];
  for (let i = 0; i < messagePadded.length; i++) {
    if (i % n === 0) {
      output.push(0n);
    }
    const j = (i / n) | 0;
    console.assert(
      j === output.length - 1,
      "Not editing the index of the last element -- packing loop invariants bug!"
    );
    output[j] += BigInt(messagePadded[i]) << BigInt((i % n) * 8);
  }
  if (outN > 0) {
    if (output.length > outN) {
      throw new Error("Output array is longer than expected");
    }
    while (output.length < outN) {
      output.push(0n);
    }
  }
  return output;
}

const merkleTreeFromTwitterHandles = async (handles: string[]) => {
  const max_twitter_username_len = 21;
  const pack_size = 7; // 7 bytes to fit 255 bits signal
  const max_twitter_packed_bytes = Math.ceil(
    max_twitter_username_len / pack_size
  );
  const twitter_usernames = [...new Set(handles)].sort();

  const twitter_usernames_packed = twitter_usernames.map((username) => {
    const packed = packBytesIntoNBytes(username);
    if (packed.length > max_twitter_packed_bytes)
      throw new Error(`Username too long ${username}`);
    // pad with zeros
    return packed.concat(
      new Array(max_twitter_packed_bytes - packed.length).fill(0n)
    );
  });
  // console.log(twitter_usernames_packed);
  const poseidon = await buildPoseidon();
  const twitter_usernames_hashed = twitter_usernames_packed.map(
    (username_chunks) => poseidon.F.toString(poseidon(username_chunks))
  );
  // console.log(twitter_usernames_hashed);

  const mimcsponge = await buildMimcSponge();
  return MerkleTree.newFromLeaves(
    twitter_usernames_hashed,
    twitter_usernames,
    async (x: string[]) =>
      BigInt(mimcsponge.F.toString(mimcsponge.multiHash(x.map(BigInt))))
  );
};

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
