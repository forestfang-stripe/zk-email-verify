pragma circom 2.1.5;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "./helpers/utils.circom";
include "./helpers/merkle_tree.circom";

template MerkleVerify(max_twitter_len, pack_size, merkle_levels) {
    var max_twitter_packed_bytes = count_packed(max_twitter_len, pack_size); // ceil(max_num_bytes / 7)
    signal input twitter_packed[max_twitter_packed_bytes];

    // collapse arbitrary twitter username into a 255bit hash
    signal twitter_hashed <== Poseidon(max_twitter_packed_bytes)(twitter_packed);

    signal input merkle_root;
    signal input merkle_path_elements[merkle_levels];
    signal input merkle_path_indices[merkle_levels];

    // verify merkle inclusion of hashed twitter username
    signal computed_root <== MerkleTreeChecker(merkle_levels)(twitter_hashed, merkle_path_elements, merkle_path_indices);
    merkle_root === computed_root;
}

// In circom, all output signals of the main component are public (and cannot be made private), the input signals of the main component are private if not stated otherwise using the keyword public as above. The rest of signals are all private and cannot be made public.
// This makes modulus and reveal_twitter_packed public. hash(signature) can optionally be made public, but is not recommended since it allows the mailserver to trace who the offender is.

// Args:
// * max_twitter_len = 21 is the number of bytes (ascii characters) for twitter handle
// * pack_size = 7 is the number of bytes that can fit into a 255ish bit signal (can increase later)
// * merkle_levels = 20 is the number of levels of merkle tree
// component main { public [ merkle_root ] } = MerkleVerify(21, 7, 20);
