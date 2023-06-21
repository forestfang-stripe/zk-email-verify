// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "forge-std/console.sol";
import "./utils/StringUtils.sol";
import "./utils/NFTSVG.sol";
import {Groth16Verifier} from "./Groth16VerifierTwitter.sol";
import "./utils/MailServer.sol";

contract VerifiedTwitterEmail is ERC721Enumerable {
    using Counters for Counters.Counter;
    using StringUtils for *;
    using NFTSVG for *;

    Counters.Counter private tokenCounter;

    uint16 public constant msg_len = 19; // modulues + address + root
    uint16 public constant bytesInPackedBytes = 7; // 7 bytes in a packed item returned from circom
    uint256 public constant rsa_modulus_chunks_len = 17;
    uint256 public constant addressIndexInSignals = rsa_modulus_chunks_len;

    mapping(string => uint256[rsa_modulus_chunks_len]) public verifiedMailserverKeys;
    mapping(uint256 => uint256) public tokenIDToMerkle;
    string constant domain = "twitter.com";
    MailServer mailServer;
    Groth16Verifier public immutable verifier;

    constructor(Groth16Verifier v, MailServer m) ERC721("VerifiedEmail", "VerifiedEmail") {
        verifier = v;
        mailServer = m;
        require(rsa_modulus_chunks_len + 2 == msg_len, "Variable counts are wrong!");
    }

    function tokenDesc(uint256 tokenId) public view returns (string memory) {
        uint256 merkle_root = tokenIDToMerkle[tokenId];
        address address_owner = ownerOf(tokenId);
        string memory result = string(
            abi.encodePacked(StringUtils.toString(address_owner), " is part of Twitter users identified by the merkle tree ", Strings.toHexString(merkle_root))
        );
        return result;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        uint256 merkle_root = tokenIDToMerkle[tokenId];
        address owner = ownerOf(tokenId);
        return NFTSVG.constructAndReturnSVG(Strings.toHexString(merkle_root), tokenId, owner);
    }

    function _domainCheck(uint256[] memory headerSignals) public pure returns (bool) {
        string memory senderBytes = StringUtils.convertPackedBytesToString(headerSignals, 18, bytesInPackedBytes);
        string[2] memory domainStrings = ["verify@twitter.com", "info@twitter.com"];
        return
            StringUtils.stringEq(senderBytes, domainStrings[0]) || StringUtils.stringEq(senderBytes, domainStrings[1]);
        // Usage: require(_domainCheck(senderBytes, domainStrings), "Invalid domain");
    }

    function mint(uint256[2] memory a, uint256[2][2] memory b, uint256[2] memory c, uint256[msg_len] memory signals)
        public
    {
        // TODO no invalid signal check yet, which is fine since the zk proof does it
        // Checks: Verify proof and check signals
        // require(signals[0] == 1337, "invalid signals");

        // Check eth address committed to in proof matches msg.sender, to avoid replayability
        require(address(uint160(signals[addressIndexInSignals])) == msg.sender, "Invalid address");

        // Check from/to email domains are correct [in this case, only from domain is checked]
        // Right now, we just check that any email was received from anyone at Twitter, which is good enough for now
        // We will upload the version with these domain checks soon!
        // require(_domainCheck(headerSignals), "Invalid domain");

        // Verify that the public key for RSA matches the hardcoded one
        for (uint256 i = 0; i < rsa_modulus_chunks_len; i++) {
            require(mailServer.isVerified(domain, i, signals[i]), "Invalid: RSA modulus not matched");
        }
        require(verifier.verifyProof(a, b, c, signals), "Invalid Proof"); // checks effects iteractions, this should come first

        // Effects: Mint token
        uint256 tokenId = tokenCounter.current() + 1;
        tokenIDToMerkle[tokenId] = signals[msg_len - 1];
        _mint(msg.sender, tokenId);
        tokenCounter.increment();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal {
        require(from == address(0), "Cannot transfer - VerifiedEmail is soulbound");
    }
}
