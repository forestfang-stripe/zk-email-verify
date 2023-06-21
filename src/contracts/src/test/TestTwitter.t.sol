pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../TwitterEmailHandler.sol";
import "../Groth16VerifierTwitter.sol";

contract TwitterUtilsTest is Test {
    using StringUtils for *;

    address constant VM_ADDR = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D; // Hardcoded address of the VM from foundry

    Groth16Verifier proofVerifier;
    MailServer mailServer;
    VerifiedTwitterEmail testVerifier;

    uint16 public constant packSize = 7;

    function setUp() public {
        proofVerifier = new Groth16Verifier();
        mailServer = new MailServer();
        testVerifier = new VerifiedTwitterEmail(proofVerifier, mailServer);
    }

    // function testMint() public {
    //   testVerifier.mint
    // }

    // Should pass (note that there are extra 0 bytes, which are filtered out but should be noted in audits)
    function testVerifyTestEmail() public {
        uint256[19] memory publicSignals;
        publicSignals[0] = 1634582323953821262989958727173988295;
        publicSignals[1] = 1938094444722442142315201757874145583;
        publicSignals[2] = 375300260153333632727697921604599470;
        publicSignals[3] = 1369658125109277828425429339149824874;
        publicSignals[4] = 1589384595547333389911397650751436647;
        publicSignals[5] = 1428144289938431173655248321840778928;
        publicSignals[6] = 1919508490085653366961918211405731923;
        publicSignals[7] = 2358009612379481320362782200045159837;
        publicSignals[8] = 518833500408858308962881361452944175;
        publicSignals[9] = 1163210548821508924802510293967109414;
        publicSignals[10] = 1361351910698751746280135795885107181;
        publicSignals[11] = 1445969488612593115566934629427756345;
        publicSignals[12] = 2457340995040159831545380614838948388;
        publicSignals[13] = 2612807374136932899648418365680887439;
        publicSignals[14] = 16021263889082005631675788949457422;
        publicSignals[15] = 299744519975649772895460843780023483;
        publicSignals[16] = 3933359104846508935112096715593287;
        publicSignals[17] = 1;
        publicSignals[18] = 9376617365923580708629093735529078576715309969768984753963048704609324066716;

        uint256[2] memory proof_a = [
            17036275991836514463942303852725690430120201992977823714243927172707703059232,
            5788740467176839905084532973099630353707996922095199884927286794244566453582
        ];
        // Note: you need to swap the order of the two elements in each subarray
        uint256[2][2] memory proof_b = [
            [
                15287143513020731669368719667620949322448836849280054065549229570928882382718,
                11226938605034486387883225778551668482739385452007530653916758166564297323420
            ],
            [
                1905174192301045443519159303679032492630016145275438544433096158291379686015,
                14931568601181112501525776363636587119204430455862428302100328429347041333819
            ]
        ];
        uint256[2] memory proof_c = [
            12803402681211172108807650509137791477073622791463495424110546662911814699765,
            16550746774478415796529331886925531167144345513851933157113760460038826495628
        ];

        // Test proof verification
        bool verified = proofVerifier.verifyProof(proof_a, proof_b, proof_c, publicSignals);
        assertEq(verified, true);

        // Test mint after spoofing msg.sender
        Vm vm = Vm(VM_ADDR);
        vm.startPrank(0x0000000000000000000000000000000000000001);
        testVerifier.mint(proof_a, proof_b, proof_c, publicSignals);
        vm.stopPrank();
    }

    function testSVG() public {
        testVerifyTestEmail();
        string memory svgValue = testVerifier.tokenURI(1);
        console.log(svgValue);
        assert(bytes(svgValue).length > 0);
    }

    function testChainID() public view {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        console.log(chainId);
        // Local chain, xdai, goerli, mainnet
        assert(chainId == 31337 || chainId == 100 || chainId == 5 || chainId == 1);
    }
}
