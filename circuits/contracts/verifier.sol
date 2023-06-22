//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.11;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );

/*
        // Changed by Jordi point
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
*/
    }
    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length,"pairing-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-opcode-failed");
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}
contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );

        vk.beta2 = Pairing.G2Point(
            [4252822878758300859123897981450591353533073413197771768651442665752259397132,
             6375614351688725206403948262868962793625744043794305715222011528459656738731],
            [21847035105528745403288232691147584728191162732299865338377159692350059136679,
             10505242626370262277552901082094356697409835680220590971873171140371331206856]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [8708390504661091960049088526677570529205474402257989616419748746116869374924,
             7430363570038717529285693076529813970525707625206779316992072157560949842196],
            [7362567275628653417179243031522539542758669341039813606311713582034205816369,
             10410145604763237339768905652977704967239229211869629763854942290583387680215]
        );
        vk.IC = new Pairing.G1Point[](20);
        
        vk.IC[0] = Pairing.G1Point( 
            2268333157572802114543493785852752678534677492185732461771818225088399376883,
            14437890285333745780710893006706768425997602005974458254244098253010948064459
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            19829569246041687030547410289585048631479796267613891644086940383164043073858,
            1846178733930442383281444297034341069119968184024593368107428333654562143889
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            25897753423562255038245963153675503245813430714752849445940058059590890450,
            12888479026834359037690081750669980287231001785939955092320746221501786182200
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            10375256615024683291564372661181654306635135746512555000288676341103382189701,
            11907616767722331431510428774506794821352530096162271556748965719116527548806
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            12772219314421391927842516072021012246175168991415219815602443456343409419208,
            19137885127491175723126888763721780410091779395490599861751872187299540391215
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            20497453153908351148344549870855852114739610319650887802709938491715759068541,
            2535510063291333258979464694153621717187586032547227351564318672217614167530
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            13972828550707234501414242430386901111372910077794924302983950838214441447248,
            18903108295891700169796246599884203205965412222732822258494075699665442375983
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            15968094765576007479785254755194526974133108079028767941695364478469114289683,
            5900231535363520686952087808123080395922840760133822995680620338708470922982
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            20183402531678260484673515213266834507884279793159494269233134861614442597900,
            19585912867796422006902463979597873662736478474354364461876379912568197001991
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            19046225192872862191465052590792099109412073223230540045704339741006717529347,
            3011273773780661019452928960549895748729263502388614388889753431875245431513
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            13813730953467330492906275839221524393360865745950556431870686859656359938449,
            7388487856969842752598603610773842061587352615995949108871795515215054490155
        );                                      
        
        vk.IC[11] = Pairing.G1Point( 
            21014986220838844726089402870172338139990911285585687443046485851259987210808,
            8171219841879017569365136865425501150877472910218389117033464372030178930273
        );                                      
        
        vk.IC[12] = Pairing.G1Point( 
            17197458132467326208306279200965225092195294734290905852205124098645467012304,
            15209211927816460439055612782552651054460851060757203823167288380110016095843
        );                                      
        
        vk.IC[13] = Pairing.G1Point( 
            1407070183405918939726455702547139910328889259184144530681123538661184277264,
            3492140932533270742500530719714496025936598304342546622612075217126567254175
        );                                      
        
        vk.IC[14] = Pairing.G1Point( 
            13941264194428578858107419429730346570845440572602927308014837068681916114284,
            1183617920677016883325348124462778558789099386145182195127564905086739623983
        );                                      
        
        vk.IC[15] = Pairing.G1Point( 
            5113858070739695407463288390202377951658302510566998664072768695913285894017,
            7822879034886381070066471263888864669937094124786770777380893249816224637968
        );                                      
        
        vk.IC[16] = Pairing.G1Point( 
            20736256092085196788710347677135573098325135218320903757619103780997274521913,
            3879152103154348044901463382858724330759044415713608991779623794148431536385
        );                                      
        
        vk.IC[17] = Pairing.G1Point( 
            8596151799203413793864633048443934772876698310304598775327472806394449542043,
            9798842186408779578655496118969574864268883449761975580170761956751107176931
        );                                      
        
        vk.IC[18] = Pairing.G1Point( 
            17014146840976210924218544986135217149443822421782272362557949734942449959017,
            8615630497081608647713320053820087273349908477501084984196194462466222395319
        );                                      
        
        vk.IC[19] = Pairing.G1Point( 
            21721403816741540418182416598182256109105829147730421260835871775208104244508,
            2765084138436502048786679888377013836155810034236612069991258683997683925786
        );                                      
        
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd4(
            Pairing.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }
    /// @return r  bool true if proof is valid
    function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[19] memory input
        ) public view returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
