import { packBytesIntoNBytes } from "./binaryFormat";
import { buildPoseidon, buildMimcSponge } from "circomlibjs";
import { MerkleTree } from "./merkle";

export const merkleTreeFromTwitterHandles = async (handles: string[]) => {
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
