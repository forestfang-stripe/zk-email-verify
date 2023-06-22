import { RawNodeDatum } from "react-d3-tree";
import { bigintToRedactedString } from "./binaryFormat";

export interface Hasher {
  (data: string[]): Promise<BigInt>;
}

// hack to allow bigints to be debugged.
// @ts-ignore
BigInt.prototype.toJSON = function () {
  return this.toString();
};

export class JSONTree {
  public root: JSONNode;
  public nodes: JSONNode[];

  constructor(root: JSONNode, nodes: JSONNode[]) {
    this.root = root;
    this.nodes = nodes;
  }
}

// A representation of a node which is safe to be output as JSON (contains no cycles).
export class JSONNode {
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

export class Node {
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

  public toD3Datum(highlights: string[]): RawNodeDatum {
    if (!this.left || !this.right) {
      const hit = this.label && highlights.includes(this.label);
      return {
        name: bigintToRedactedString(this.value),
        children: this.label
          ? [{ name: this.label, attributes: { color: hit ? "red" : "" } }]
          : [],
        attributes: {
          color: hit || highlights.includes(this.value.toString()) ? "red" : "",
        },
      };
    }
    return {
      name: bigintToRedactedString(this.value),
      children: [
        this.left.toD3Datum(highlights),
        this.right.toD3Datum(highlights)
      ],
      attributes: {
        color: highlights.includes(this.value.toString()) ? "red" : "",
      },
    }
  }
}

// A public representation of a merkle proof
export interface MerkleProof {
  values: BigInt[];
  indexHints: number[]; // 0 if proofVal on left, 1 if proofVal on right
}

// A representation of a merkle tree
export class MerkleTree {
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
    if (leaves.length > numLeaves) throw new Error(`too many leaves ${leaves.length} > 2 ** ${levels} (${numLeaves}))`);
    const nodes = Array.from({...leaves, length: numLeaves}, (x) => new Node(x||0n));
    labels.forEach((label, i) => { nodes[i].label = label; });
    const buildResult = await MerkleTree.buildTree(nodes, hasher);
    const root = buildResult[0];

    // pass back to main constructor
    return new MerkleTree(root, nodes, hasher);
  }

  // builds a tree given a level
  private static async buildTree(leaves: Node[], hasher: Hasher): Promise<Node[]> {
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

  public toD3Data(highlights: string[]): RawNodeDatum {
    return this.root.toD3Datum( highlights);
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

  private static findNode(value: BigInt | string, nodes: Node[]): Node | undefined {
    return nodes.find((leaf) => leaf.value == value || leaf.label == value);
  }
}