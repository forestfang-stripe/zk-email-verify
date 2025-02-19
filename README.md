# ZK Email Verify

**WIP: This tech is extremely tricky to use and very much a work in progress, and we do not recommend use in any production application right now. This is both due to unaudited code, and several theoretical gotchas such as lack of nullifiers, no signed bcc’s, non-nested reply signatures, upgradability of DNS, and hash sizings. None of these affect our current Twitter MVP usecase, but are not generally guaranteed. If you have a possible usecase, we are happy to help brainstorm if your trust assumptions are in fact correct!**

If you're interested in building a project with zk email or would like to contribute, [dm us](https://twitter.com/yush_g/)! Get up to date on our broad progress on the [higher level org readme](https://github.com/zkemail). While this circom code is complete, it is quite slow client side (see benchmarks below), and we are working quite hard to put up a secure, ultrafast version with halo2 by Q2 2023. We are also hoping to release a broader SDK so it will be very easy to put up new zk email applications.

## MVP App

The application is located at https://zkemail.xyz. It only works on Chrome/Brave/Arc (or other Chromium-based browsers) due to download limits on other browsers. To understand the construction more, read [our blog post here](https://blog.aayushg.com/posts/zkemail).

The documentation for the app is located at https://zkemail.xyz/docs (WIP). Made by [@yush_g](https://twitter.com/yush_g) and [@sampriti0](https://twitter.com/sampriti0) at [@0xparc](https://twitter.com/0xparc), dm if interested in usage or building next generation primitives like this. This is very much a work in progress, and we invite folks to contribute, or contact us for interesting projects that can be built on top of the tech! We are especially prioritizing optimizing circuits, making our end-to-end demo more efficient and on-chain, and an SDK/CLI.

### Local website

To run the frontend with existing circuits (there is no backend or server), enable Node 16 (with nvm) and run:

```bash
yarn start
```

If the frontend shows an error on fullProve line, run this and rerun

```bash
yarn add snarkjs@https://github.com/sampritipanda/snarkjs.git#fef81fc51d17a734637555c6edbd585ecda02d9e
```

### Getting email headers

In Outlook, turn on plain text mode. Copy paste the 'full email details' into the textbox on the (only client side!) webpage.

In gmail, download original message then copy paste the contents into the textbox.

## Development Instructions

This will let you build new zkeys from source.

### Filetree Description

```bash
circuits/ # groth16 zk circuits
    contracts/ # Auto-gen verifier
    example/ # Example proofs, publics, and private witnesses
    inputs/ # Test inputs for example witness generation for compilation
        input_email_domain.json # Standard input for from/to mit.edu domain matching, for use with circuit without body checks
        input_email_packed.json # Same as above but has useless packed input -- is private so irrelevant, this file could be deleted.
    main/ # Legacy RSA code
    regexes/ # Generated regexes
    helpers/ # Common helper circom circuits imported in email circuits
    scripts/ # Run snarkjs ceremony to generate zkey with yarn compile
dizkus-scripts/
    *.sh # Scripts to compile the chunked keys on a remote server
    *.circom # Final circom file that imports from the circuits
    sample_input.json # Generated by running generate_input.ts on an email file, or by asking Aayush for one
docs/
src/
    circuits/  # Has vkey
    contracts/ # Run foundry commands from this folder
        src/   # Note that these are untested WIPs. Need to decrease calldata to be able to work on chain.
            emailHandlerBase.sol # Build new verifiers by forking this
            twitterEmailHandler.sol # Verifies Twitter usernames and issues a badge
            domainEmailHandler.sol # Verifies email domain and issues a badge
        lib/ # Foundry libraries
    helpers/ # Shared JS/TS helpers for both input generation + frontend
    pages/   # Frontend
    scripts/
        fast-sha256.ts # SHA 256 helper that we use for partial SHA
        generate_input.ts # Helper to convert email into circuit input
public/ # Should contain vkey/wasm, but we end up fetching those from AWS server instead
    docs/
    logos
    vkey
    wasm
```

### Regex to Circom

See regex_to_circom/README.md for usage instructions.

### Email Circuit Build Steps

#### Build

Install rust/circom2 via the following steps, according to: https://docs.circom.io/getting-started/installation/

```bash
curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh # Install rust if don't already have
source "$HOME/.cargo/env" # Also rust installation step

git clone https://github.com/iden3/circom.git
sudo apt update
sudo apt-get install nlohmann-json3-dev libgmp-dev nasm # Ubuntu packages needed for C-based witness generator
sudo apt install build-essential # Ubuntu
brew install nlohmann-json gmp nasm # OSX
cd circom
cargo build --release
cargo install --path circom
```

Inside `zk-email-verify` folder, do

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash # If don't have npm
. ~/.nvm/nvm.sh # If don't have npm
nvm install 16 # If don't have node 16
nvm use 16 # If not using node 16
sudo npm i -g yarn # If don't have yarn (may need to remove sudo)
yarn install # If this fails, delete yarn.lock and try again
```

To get the ptau, do (note that you only need the 22 file right now)

```bash
wget https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_22.ptau
mv powersOfTau28_hez_final_22.ptau circuits/powersOfTau28_hez_final_22.ptau

wget https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_21.ptau
# shasum pot21_final.ptau: e0ef07ede5c01b1f7ddabb14b60c0b740b357f70
mv powersOfTau28_hez_final_21.ptau circuits/powersOfTau28_hez_final_21.ptau
```

<!-- Previously snarkjs@git+https://github.com/vb7401/snarkjs.git#fae4fe381bdad2da13eee71010dfe477fc694ac1 -->
<!-- Now -> yarn add https://github.com/vb7401/snarkjs/commits/chunk_zkey_gen -->

#### Zkey Creation

Put the email into ...\*.eml. Edit the constant filename at the top of generate_input.ts to import that file, then use the output of running that file as the input file (you may need to rename it). You'll need this for both zkey and verifier generation.

To create a chunked zkey for in-browser proving, run the following on a high CPU computer:

```bash
yarn add snarkjs@git+https://github.com/vb7401/snarkjs.git#24981febe8826b6ab76ae4d76cf7f9142919d2b8 # Swap to chunked generation version for browser, leave this line out for serverside proofs onluy
cd dizkus-scripts/
cp entropy.env.example entropy.env
```

Fill out the env via random characters into the values for entropy1 and entropy2, and hexadecimal characters into the beacon. These scripts will compile and test your zkey for you, and generate a normal zkey with for an on chain verifier or server side prover, with the same entropy as the chunked one. If you only want the chunked one, use ./3_gen_chunk_zkey.sh in place of the generation.

```bash
./1_compile.sh && ./2_gen_wtns.sh && ./3_gen_both_zkeys.sh && ./4_gen_vkey.sh && ./5_gen_proof.sh
```

#### Server-side Prover: Rapidsnark Setup (Optional)

If you want to run a fast server side prover, install rapidsnark and test proofgen:

```bash
cd ../../
git clone https://github.com/iden3/rapidsnark
cd rapidsnark
npm install
git submodule init
git submodule update
npx task createFieldSources
```

You're supposed to run `npx task buildPistache` next, but that errored, so I had to manually build the pistache lib first:

```bash
cd depends/pistache
sudo apt-get install meson ninja-build
meson setup build --buildtype=release
ninja -C build
sudo ninja -C build install
sudo ldconfig
cd ../..
```

Then, from rapidsnark/ I could run

```bash
npx task buildProverServer
```

And from zk-email-verify, convert your proof params to a rapidsnark friendly version, generating the C-based witness generator and rapidsnark prover. To target to the AWS autoprover, go to the Makefile and manually replace the `CFLAGS=-std=c++11 -O3 -I.` line with (targeted to g4dn.xlarge and g5.xlarge, tuned to g5.xlarge):

```bash
cd ../zk-email-verify/dizkus-scripts
./6_gen_proof_rapidsnark.sh
```

To compile a non-chunked zkey for server-side use only,

```bash
yarn compile-all
```

#### Uploading to AWS

To upload zkeys to an s3 box on AWS, change bucket_name in upload_to_s3.py and run:

```bash
sudo apt install awscli # Ubuntu
brew install awscli # Mac

aws configure # Only needs to be run once
pip3 install boto3
python3 upload_to_s3.py
yarn add snarkjs@https://github.com/sampritipanda/snarkjs.git#fef81fc51d17a734637555c6edbd585ecda02d9e # Revert to frontend version
```

If you want to upload different files, you can parameterize the script as well:

```bash
python3 dizkus-scripts/upload_to_s3.py --dirs ~/zk-email-verify/build/email/email_js/ --bucket_name zkemail-zkey-chunks --prefix email.wasm
```

Note that there's no .zkeya file, only .zkeyb ... .zkeyk. The script will automatically zip into .tar.gz files and load into s3 bucket.

#### Recompile Frontend (Important!)

We use a fork of [zkp.ts](https://github.com/personaelabs/heyanon/blob/main/lib/zkp.ts) to load these keys into localforage. In the browser, to read off of localforage, you have to use this fork when running the frontend locally/in prod. THIS IS VERY IMPORTANT -- WRONG SNARKJS FORKS CAUSE THE MOST ERRORS.

```bash
yarn install snarkjs@git+https://github.com/vb7401/snarkjs.git#53e86631b5e409e5bd30300611b495ca469503bc
```

Manually copy paste the modulus in the resulting generated file into solidity verified mailserver keys.

Change s3 address in the frontend to your bucket.

### Really Large Circuits

If your circuit ends up being > 20M constraints, you will need to follow [these guidelines](https://hackmd.io/V-7Aal05Tiy-ozmzTGBYPA?view#Compilation-and-proving) to compile it.

### Compiling Subcircuits

If you want to compile subcircuits instead of the whole thing, you can use the following:

If you want to generate a new email/set of inputs, edit the src/constants.ts file with your constants.
In generate_input.ts, change the circuitType variable inside to match what circom file you are running, then run

```bash
npm install typescript ts-node -g
# uncomment do_generate function call at end of file
# go to tsconfig.json and change esnext to CommonJS
# if weird things dont work with this and yarn start, go go node_modules/react-scripts/config/webpack.config.ts and add/cut `target: 'node',` after like 793 after `node:`.
npx tsc --moduleResolution node --target esnext src/scripts/generate_input.ts
```

which will autowrite input\_<circuitName>.json to the inputs folder.

To do the steps in https://github.com/iden3/snarkjs#7-prepare-phase-2 automatically, do

```
yarn compile email true
```

and you can swap `email` for `sha` or `rsa` or any other circuit name that matches your generate_input type.

and when the circuit doesn't change,

```bash
yarn compile email true skip-r1cswasm
```

and when the zkey also doesn't change,

```bash
yarn compile email true skip-r1cswasm skip-zkey
```

### Contract Deployment

Follow the instructions in `src/contracts/README.md`.

### Production

For production, make sure to set a beacon in .env.

Note that this leaks the number of characters in the username of someone who sent you an email, iff the first field in the email serialization format is from (effectively irrelevant).

### Testing

To constraint count, do

```bash
cd circuits
node --max-old-space-size=614400 ./../node_modules/.bin/snarkjs r1cs info email.r1cs
```

To test solidity,

```bash
cp node_modules/forge-std src/contracts/lib/forge-std
cd src/contracts
forge test
```

To deploy contracts, look at src/contracts/README.md.

## Performance

### Constraint breakdown

|          Operation          | Constraint # |
| :-------------------------: | :----------: |
|     SHA of email header     |   506,670    |
|    RSA signature verify     |   149,251    |
|      DKIM header regex      |   736,553    |
|       Body hash regex       |   617,597    |
|        SHA body hash        |   760,142    |
|    Twitter handle regex     |   328,044    |
| Packing output for solidity |    16,800    |
|      Total constraints      |  3,115,057   |

| Function | % of constraints |
| :------: | ---------------- |
|  Regex   | 54.00 %          |
| SHA hash | 40.67 %          |
|   RSA    | 4.79 %           |
| Packing  | 0.54 %           |

### Optimization plan

The current circom version is too expensive for any widely deployed in-browser use case, even with a plethora of tricks (chunked zkeys, single threaded proof gen for lower memory, compressing zkey and decompressing locally, etc.).

Short term ways to improve the performance would be to replace the regex checks with substring checks for everything except the email header, where we need regex (as far as we can tell) to correctly parse the "from" or "to" email from the header.

Looking more long term, we are actively using Halo2 and Nova to speed up the most expensive operations of regex and SHA. As hash functions and regex DFA traversal are repeated operations, they are a great fit for Nova's folding methods to compress repeated computation into a constant sized folded instance. But to actually use Nova to fold expensive operations outside of Halo2/Groth16, we need to verify the folded instance is valid inside the circuit for zero-knowledge and to link it to the rest of the computation. We also are attempting to use the lookup feature of Halo2 to precompute the entire table of possible regex state transitions, and just looking up that all of the transitions made are valid ones in the table instead of expensively checking each state! This idea is due to Sora Suegami, explained in more detail here: https://hackmd.io/@SoraSuegami/Hy9dWgT8i.

The current set `of remaining tasks and potential final states is documented in the following DAG, please reach out if any of the projects seem interesting!

![Optimization plan](public/zk_email_optim.jpg)

### General guidelines

Just RSA + SHA (without masking or regex proofs) for arbitrary message length <= 512 bytes is 402,802 constraints, and the zkey took 42 minutes to generate on an intel mac.

RSA + SHA + Regex + Masking with up to 1024 byte message lengths is 1,392,219 constraints, and the chunked zkey took 9 + 15 + 15 + 2 minutes to generate on a machine with 32 cores.

The full email header circuit above with the 7-byte packing into signals is 1,408,571 constraints, with 163 public signals, and the verifier script fits in the 24kb contract limit.

The full email header and body check circuit, with 7-byte packing and final public output compression, is **3,115,057 constraints**, with 21 public signals. zkey size was originally 1.75GB, and with tar.gz compression it is now 982 MB.

In the browser, on a 2019 Intel Mac on Chrome, proving uses 7.3/8 cores. zk-gen takes 384 s, groth16 prove takes 375 s, and witness calculation takes 9 s.

For baremetal, proof generation time on 16 CPUs took 97 seconds. Generating zkey 0 took 17 minutes. zkey 1 and zkey 2 each took 5 minutes. r1cs + wasm generation took 5 minutes. Witness generation took 16 seconds. cpp generation of witness gen file (from script 6) took 210 minutes -- this is only useful for server side proving.

### Scrubbing Sensitive Files

```bash
brew install git-filter-repo
git filter-repo --replace-text <(echo "0x000000000000000000000000000000000000000000000000000000000abcdef")
git filter-repo --path mit_msg.eml --invert-paths
git remote add origin https://github.com/zk-email-verify/zk-email-verify
ls
git push --set-upstream origin main --force
```

## Regexes we compiled

Test these on cyberzhg's toolbox modified at [zkregex.com/min_dfa](https://zkregex.com/min_dfa). The regex to get out the from/to emails is:

```
// '(\r\n|\x80)(to|from):([A-Za-z0-9 _."@-]+<)?[a-zA-Z0-9_.-]+@[a-zA-Z0-9_.]+>?\r\n';
// let regex = '(\r\n|\x80)(to|from):((a|b|c|d|e|f|g|h|i|j|k|l|m|n|o|p|q|r|s|t|u|v|w|x|y|z|A|B|C|D|E|F|G|H|I|J|K|L|M|N|O|P|Q|R|S|T|U|V|W|X|Y|Z|0|1|2|3|4|5|6|7|8|9| |_|.|"|@|-)+<)?(a|b|c|d|e|f|g|h|i|j|k|l|m|n|o|p|q|r|s|t|u|v|w|x|y|z|A|B|C|D|E|F|G|H|I|J|K|L|M|N|O|P|Q|R|S|T|U|V|W|X|Y|Z|0|1|2|3|4|5|6|7|8|9|_|.|-)+@(a|b|c|d|e|f|g|h|i|j|k|l|m|n|o|p|q|r|s|t|u|v|w|x|y|z|A|B|C|D|E|F|G|H|I|J|K|L|M|N|O|P|Q|R|S|T|U|V|W|X|Y|Z|0|1|2|3|4|5|6|7|8|9|_|.|-)+>?\r\n';
```

The regex to get out the body hash is:

```
const key_chars = '(a|b|c|d|e|f|g|h|i|j|k|l|m|n|o|p|q|r|s|t|u|v|w|x|y|z)';
const catch_all = '(0|1|2|3|4|5|6|7|8|9|a|b|c|d|e|f|g|h|i|j|k|l|m|n|o|p|q|r|s|t|u|v|w|x|y|z|A|B|C|D|E|F|G|H|I|J|K|L|M|N|O|P|Q|R|S|T|U|V|W|X|Y|Z|!|"|#|$|%|&|\'|\\(|\\)|\\*|\\+|,|-|.|/|:|;|<|=|>|\\?|@|[|\\\\|]|^|_|`|{|\\||}|~| |\t|\n|\r|\x0b|\x0c)';
const catch_all_without_semicolon = '(0|1|2|3|4|5|6|7|8|9|a|b|c|d|e|f|g|h|i|j|k|l|m|n|o|p|q|r|s|t|u|v|w|x|y|z|A|B|C|D|E|F|G|H|I|J|K|L|M|N|O|P|Q|R|S|T|U|V|W|X|Y|Z|!|"|#|$|%|&|\'|\\(|\\)|\\*|\\+|,|-|.|/|:|<|=|>|\\?|@|[|\\\\|]|^|_|`|{|\\||}|~| |\t|\n|\r|\x0b|\x0c)';
const base_64 = '(a|b|c|d|e|f|g|h|i|j|k|l|m|n|o|p|q|r|s|t|u|v|w|x|y|z|A|B|C|D|E|F|G|H|I|J|K|L|M|N|O|P|Q|R|S|T|U|V|W|X|Y|Z|0|1|2|3|4|5|6|7|8|9|\\+|/|=)';

let regex = `\r\ndkim-signature:(${key_chars}=${catch_all_without_semicolon}+; )+bh=${base_64}+; `;
```

The regex for Twitter is:

```
const word_char = '(a|b|c|d|e|f|g|h|i|j|k|l|m|n|o|p|q|r|s|t|u|v|w|x|y|z|A|B|C|D|E|F|G|H|I|J|K|L|M|N|O|P|Q|R|S|T|U|V|W|X|Y|Z|0|1|2|3|4|5|6|7|8|9|_)';
let regex = `email was meant for @${word_char}+`;
```

To understand these better, use https://cyberzhg.github.io/toolbox/ and use the 3 regex tools for visualization of the min-DFA state.

## FAQ/Possible Errors

### Can you provide an example header for me to understand what exactly is signed?

We are hijacking DKIM signatures in order to verify parts of emails, which can be verified on chain via succinct zero knowledge proofs. Here is an example of the final, canoncalized actual header string that is signed by google.com's public key:

`to:"zkemailverify@gmail.com" <zkemailverify@gmail.com>\r\nsubject:test email\r\nmessage-id:<CAOmXgjU78_L7d-H7Wqf2qph=-uED3Kw6NEU2PzSP6jiUH0Bb+Q@mail.gmail.com>\r\ndate:Fri, 24 Mar 2023 13:02:10 +0700\r\nfrom:ZK Email <zkemailverify2@gmail.com>\r\nmime-version:1.0\r\ndkim-signature:v=1; a=rsa-sha256; c=relaxed/relaxed; d=gmail.com; s=20210112; t=1679637743; h=to:subject:message-id:date:from:mime-version:from:to:cc:subject :date:message-id:reply-to; bh=gCRK/FdzAYnMHic55yb00uF8AHZ/3HvyLVQJbWQ2T8o=; b=`

Thus, we can extract whatever information we want out of here via regex, including to/from/body hash! We can do the same for an email body.

### I'm having issues with the intricacies of the SHA hashing. How do I understand the function better?

Use https://sha256algorithm.com/ as an explainer! It's a great visualization of what is going on, and our code should match what is going on there.

### I'm having trouble with regex or base64 understanding. How do I understand that better?

Use https://cyberzhg.github.io/toolbox/ to experiment with conversions to/from base64 and to/from DFAs and NFAs.

### What are the differences between generating proofs (snarkjs.groth16.fullprove) on the client vs. on a server?

If the server is generating the proof, it has to have the private input. We want people to own their own data, so client side proving is the most secure both privacy and anonymity wise. There are fancier solutions (MPC, FHE, recursive proofs etc), but those are still in the research stage.

### “Cannot resolve module ‘fs’”

Fixed by downgrading react-scripts version.

### TypeError: Cannot read properties of undefined (reading 'toString')

This is the full error:

```
zk-email-verify/src/scripts/generateinput.ts:182
const = result.results[0].publicKey.toString();
                                    ^
TypeError: Cannot read properties of undefined (reading 'toString')
```

You need to have internet connection while running dkim verification locally, in order to fetch the public key. If you have internet connection, make sure you downloaded the email with the headers: you should see a DKIM section in the file. DKIM verifiction may also fail after the public keys rotate, though this has not been confirmed.

### How do I lookup the RSA pubkey for a domain?

Use [easydmarc.com/tools/dkim-lookup?domain=twitter.com](https://easydmarc.com/tools/dkim-lookup?domain=twitter.com).

### DKIM parsing/public key errors with generate_input.ts

```
Writing to file...
/Users/aayushgupta/Documents/.projects.nosync/zk-email-verify/src/scripts/generate_input.ts:190
        throw new Error(`No public key found on generate_inputs result ${JSON.stringify(result)}`);
```

Depending on the "info" error at the end of the email, you probably need to go through src/helpers/dkim/\*.js and replace some ".replace" functions with ".replaceAll" instead (likely tools.js), and also potentially strip some quotes.

### No available storage method found.

If when using snarkjs, you see this:

```
[ERROR] snarkJS: Error: No available storage method found. [full path]
/node_modules/localforage/dist/localforage.js:2762:25
```

Rerun with this:
`yarn add snarkjs@git+https://github.com/vb7401/snarkjs.git#24981febe8826b6ab76ae4d76cf7f9142919d2b8`

### I'm trying to edit the circuits, and running into the error 'Non-quadratic constraints are not allowed!'

The line number of this error is usually arbitrary. Make sure you are not mixing signals and variables anywhere: signals can only be assigned once, and assigned to other signals (not variables), and cannot be used as parameters in control flow like for, if, array indexing, etc. You can get versions of these by using components like isEqual, lessThan, and quinSelector, respectively.

### Where do I get the public key for the signature?

Usually, this will be hosted on DNS server of some consistent URL under the parent organization. You can try to get it from a .pem file, but that is usually a fraught effort since the encoding of such files varies a lot, is idiosyncratic, and hard to parse. The easiest way is to just extract it from the RSA signature itself (like our generate_input.ts file), and just verify that it matches the parent organization.

### How can I trust that you verify the correct public key?

You can see the decomposed public key in our Solidity verifier, and you can auto-check this against the mailserver URL. This prevents the code from falling victim to DNS spoofing attacks. We don't have mailserver key rotations figured out right now, but we expect that can be done trustlessly via DNSSEC (though not widely enabled) or via deploying another contract.

### How do I get a Verifier.sol file that matches my chunked zkeys?

You should be able to put in identical randomness on both the chunked zkey fork and the regular zkey generation fork in the beacon and Powers of Tau phase 2, to be able to get the same zkey in both a chunked and non-chunked form. You can then run compile.js, or if you prefer the individual line, just `node --max-old-space-size=614400 ${snarkJSPath} zkey export solidityverifier ${cwd}/circuits/${circuitNamePrimary}/keys/circuit_final.zkey ${cwd}/circuits/contracts/verifier.sol`, where you edit the path variables to be your preferred ones.

The chunked file utils will automatically search for circuit_final.zkeyb from this command line call if you are using the chunked zkey fork (you'll know you have that fork, if you have a file called chunkFileUtils in snarkJS).

### How do I deal with all of these snarkJS forks?

Apologies, this part is some messy legacy code from previous projects. You use vivekab's fork for keygeneration, sampritipanda's fork for chunked zkey checking on the frontend, and the original snarkjs@latest to get rid of chunking entirely (but you'll need to edit frontend code to not do that). You can do something like `./node_modules/bin/snarkjs' inside your repo, and it'll run the snarkjs command built from the fork you're using instead of the global one.

### How do I build my own frontend but plug in your ZK parsing?

zkp.ts is the key file that calls the important proving functions. You should be able to just call the exported functions from there, along with setting up your own s3 bucket and setting the constants at the top.

### What is the licensing on this technology?

Everything we write is MIT licensed. Note that circom and circomlib is GPL. Broadly we are pro permissive open source usage with attribution! We hope that those who derive profit from this, contribute that money altruistically back to this technology and open source public good.

## To-Do

- Make a general method to get formatted signatures and bodies from all email clients
- Make versions for different size RSA keys
- Add ENS DNSSEC code (possibly SNARKed), so anyone can add a website's RSA key via DNS record
- Design the NFT/POAP to have the user's domain/verified identity on it and display SVG properly on opensea
- Make a testnet faucet as a PoC for Sybil resistance and to get developers interested
- Dynamically tradeoff between gzip (2x faster decompression) and xz (30% smaller file size): https://www.rootusers.com/gzip-vs-bzip2-vs-xz-performance-comparison/ based on internet speed (i.e. minimize download time + unzip time)
- Fix these circom bugs from `circom email.circom --inspect`:
  - warning[CA02]: In template "Base64Decode(32)": Subcomponent input/output signal bits_out[10][2].out does not appear in any constraint of the father component
  - warning[CA01]: In template "TwitterResetRegex(1536)": Local signal states[1536][0] does not appear in any constraint
  - warning[CA02]: In template "EmailVerify(1024,1536,121,17,7)": Subcomponent input/output signal dkim_header_regex.reveal[0] does not appear in any constraint of the father component
  - warning[CA02]: In template "RSAVerify65537(121,17)": Array of subcomponent input/output signals signatureRangeCheck[13].out contains a total of 121 signals that do not appear in any constraint of the father component
    = For example: signatureRangeCheck[13].out[0], signatureRangeCheck[13].out[100].
  - warning[CA02]: In template "LessThan(8)": Array of subcomponent input/output signals n2b.out contains a total of 8 signals that do not appear in any constraint of the father component
    = For example: n2b.out[0], n2b.out[1].
  - warning[CA01]: In template "DKIMHeaderRegex(1024)": Local signal states[1025][0] does not appear in any constraint
  - warning[CA01]: In template "Bytes2Packed(7)": Array of local signals in_prefix_sum contains a total of 8 signals that do not appear in any constraint
    = For example: in_prefix_sum[0], in_prefix_sum[1].
  - warning[CA01]: In template "Bytes2Packed(7)": Array of local signals pow2 contains a total of 8 signals that do not appear in any constraint
    = For example: pow2[0], pow2[1].
- Enable parsing of emails via tagged-dfa/lookahead/lookbehinds in all cases where 1) from:email [rare, only gcal] and 2) from:<email> and 3) from:text <email>
- Fix it so only a recent email after deploy cutoff can be used to send money
