pragma circom 2.1.5;

include "./helpers/utils.circom";
include "./twitter.circom";
include "./merkle.circom";

template MerkleEmailVerify(max_header_bytes, max_body_bytes, n, k, pack_size, expose_from, expose_to, merkle_levels) {
    signal input in_padded[max_header_bytes]; // prehashed email data, includes up to 512 + 64? bytes of padding pre SHA256, and padded with lots of 0s at end after the length
    signal input modulus[k]; // rsa pubkey, verified with smart contract + DNSSEC proof. split up into k parts of n bits each.
    signal input signature[k]; // rsa signature. split up into k parts of n bits each.
    signal input in_len_padded_bytes; // length of in email data including the padding, which will inform the sha256 block length
    signal input address;    // Identity commitment variables
    signal input body_hash_idx;
    signal input precomputed_sha[32];
    signal input in_body_padded[max_body_bytes];
    signal input in_body_len_padded_bytes;
    signal input twitter_username_idx;

    component emailVerify = EmailVerify(max_header_bytes, max_body_bytes, n, k, pack_size, expose_from, expose_to);
    emailVerify.in_padded <== in_padded;
    emailVerify.modulus <== modulus;
    emailVerify.signature <== signature;
    emailVerify.in_len_padded_bytes <== in_len_padded_bytes;
    emailVerify.address <== address;
    emailVerify.body_hash_idx <== body_hash_idx;
    emailVerify.precomputed_sha <== precomputed_sha;
    emailVerify.in_body_padded <== in_body_padded;
    emailVerify.in_body_len_padded_bytes <== in_body_len_padded_bytes;
    emailVerify.twitter_username_idx <== twitter_username_idx;

    var max_twitter_len = 21;
    var max_twitter_packed_bytes = count_packed(max_twitter_len, pack_size); // ceil(max_num_bytes / 7)
    signal revealed_twitter_packed[max_twitter_packed_bytes] <== emailVerify.reveal_twitter_packed;
    signal input twitter_packed[max_twitter_packed_bytes];
    // We could have used revealed_twitter_packed in merkle verify
    // but passing in twitter_packed helps sanity check
    twitter_packed === revealed_twitter_packed;

    signal input merkle_root;
    signal input merkle_path_elements[merkle_levels];
    signal input merkle_path_indices[merkle_levels];
    MerkleVerify(max_twitter_len, pack_size, merkle_levels)(twitter_packed, merkle_root, merkle_path_elements, merkle_path_indices);
}

// In circom, all output signals of the main component are public (and cannot be made private), the input signals of the main component are private if not stated otherwise using the keyword public as above. The rest of signals are all private and cannot be made public.
// This makes modulus, address and merkle_root public. hash(signature) can optionally be made public, but is not recommended since it allows the mailserver to trace who the offender is.

// Args:
// * max_header_bytes = 1024 is the max number of bytes in the header
// * max_body_bytes = 1536 is the max number of bytes in the body after precomputed slice
// * n = 121 is the number of bits in each chunk of the modulus (RSA parameter)
// * k = 17 is the number of chunks in the modulus (RSA parameter)
// * pack_size = 7 is the number of bytes that can fit into a 255ish bit signal (can increase later)
// * expose_from = 0 is whether to expose the from email address
// * expose_to = 0 is whether to expose the to email (not recommended)
// * merkle_levels = 5 is the number of levels of merkle tree
component main { public [ modulus, address, merkle_root ] } = MerkleEmailVerify(1024, 1536, 121, 17, 7, 0, 0, 5);
