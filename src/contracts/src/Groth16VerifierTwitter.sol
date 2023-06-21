// SPDX-License-Identifier: GPL-3.0
/*
    Copyright 2021 0KIMS association.

    This file is generated with [snarkJS](https://github.com/iden3/snarkjs).

    snarkJS is a free software: you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    snarkJS is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
    License for more details.

    You should have received a copy of the GNU General Public License
    along with snarkJS. If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.7.0 <0.9.0;

contract Groth16Verifier {
    // Scalar field size
    uint256 constant r    = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    // Base field size
    uint256 constant q   = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // Verification Key data
    uint256 constant alphax  = 20491192805390485299153009773594534940189261866228447918068658471970481763042;
    uint256 constant alphay  = 9383485363053290200918347156157836566562967994039712273449902621266178545958;
    uint256 constant betax1  = 4252822878758300859123897981450591353533073413197771768651442665752259397132;
    uint256 constant betax2  = 6375614351688725206403948262868962793625744043794305715222011528459656738731;
    uint256 constant betay1  = 21847035105528745403288232691147584728191162732299865338377159692350059136679;
    uint256 constant betay2  = 10505242626370262277552901082094356697409835680220590971873171140371331206856;
    uint256 constant gammax1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant gammax2 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant gammay1 = 4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 constant gammay2 = 8495653923123431417604973247489272438418190587263600148770280649306958101930;
    uint256 constant deltax2 = 7430363570038717529285693076529813970525707625206779316992072157560949842196;
    uint256 constant deltax1 = 8708390504661091960049088526677570529205474402257989616419748746116869374924;
    uint256 constant deltay2 = 10410145604763237339768905652977704967239229211869629763854942290583387680215;
    uint256 constant deltay1 = 7362567275628653417179243031522539542758669341039813606311713582034205816369;


    uint256 constant IC0x = 2268333157572802114543493785852752678534677492185732461771818225088399376883;
    uint256 constant IC0y = 14437890285333745780710893006706768425997602005974458254244098253010948064459;

    uint256 constant IC1x = 19829569246041687030547410289585048631479796267613891644086940383164043073858;
    uint256 constant IC1y = 1846178733930442383281444297034341069119968184024593368107428333654562143889;

    uint256 constant IC2x = 25897753423562255038245963153675503245813430714752849445940058059590890450;
    uint256 constant IC2y = 12888479026834359037690081750669980287231001785939955092320746221501786182200;

    uint256 constant IC3x = 10375256615024683291564372661181654306635135746512555000288676341103382189701;
    uint256 constant IC3y = 11907616767722331431510428774506794821352530096162271556748965719116527548806;

    uint256 constant IC4x = 12772219314421391927842516072021012246175168991415219815602443456343409419208;
    uint256 constant IC4y = 19137885127491175723126888763721780410091779395490599861751872187299540391215;

    uint256 constant IC5x = 20497453153908351148344549870855852114739610319650887802709938491715759068541;
    uint256 constant IC5y = 2535510063291333258979464694153621717187586032547227351564318672217614167530;

    uint256 constant IC6x = 13972828550707234501414242430386901111372910077794924302983950838214441447248;
    uint256 constant IC6y = 18903108295891700169796246599884203205965412222732822258494075699665442375983;

    uint256 constant IC7x = 15968094765576007479785254755194526974133108079028767941695364478469114289683;
    uint256 constant IC7y = 5900231535363520686952087808123080395922840760133822995680620338708470922982;

    uint256 constant IC8x = 20183402531678260484673515213266834507884279793159494269233134861614442597900;
    uint256 constant IC8y = 19585912867796422006902463979597873662736478474354364461876379912568197001991;

    uint256 constant IC9x = 19046225192872862191465052590792099109412073223230540045704339741006717529347;
    uint256 constant IC9y = 3011273773780661019452928960549895748729263502388614388889753431875245431513;

    uint256 constant IC10x = 13813730953467330492906275839221524393360865745950556431870686859656359938449;
    uint256 constant IC10y = 7388487856969842752598603610773842061587352615995949108871795515215054490155;

    uint256 constant IC11x = 21014986220838844726089402870172338139990911285585687443046485851259987210808;
    uint256 constant IC11y = 8171219841879017569365136865425501150877472910218389117033464372030178930273;

    uint256 constant IC12x = 17197458132467326208306279200965225092195294734290905852205124098645467012304;
    uint256 constant IC12y = 15209211927816460439055612782552651054460851060757203823167288380110016095843;

    uint256 constant IC13x = 1407070183405918939726455702547139910328889259184144530681123538661184277264;
    uint256 constant IC13y = 3492140932533270742500530719714496025936598304342546622612075217126567254175;

    uint256 constant IC14x = 13941264194428578858107419429730346570845440572602927308014837068681916114284;
    uint256 constant IC14y = 1183617920677016883325348124462778558789099386145182195127564905086739623983;

    uint256 constant IC15x = 5113858070739695407463288390202377951658302510566998664072768695913285894017;
    uint256 constant IC15y = 7822879034886381070066471263888864669937094124786770777380893249816224637968;

    uint256 constant IC16x = 20736256092085196788710347677135573098325135218320903757619103780997274521913;
    uint256 constant IC16y = 3879152103154348044901463382858724330759044415713608991779623794148431536385;

    uint256 constant IC17x = 8596151799203413793864633048443934772876698310304598775327472806394449542043;
    uint256 constant IC17y = 9798842186408779578655496118969574864268883449761975580170761956751107176931;

    uint256 constant IC18x = 17014146840976210924218544986135217149443822421782272362557949734942449959017;
    uint256 constant IC18y = 8615630497081608647713320053820087273349908477501084984196194462466222395319;

    uint256 constant IC19x = 21721403816741540418182416598182256109105829147730421260835871775208104244508;
    uint256 constant IC19y = 2765084138436502048786679888377013836155810034236612069991258683997683925786;


    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[19] calldata _pubSignals) public view returns (bool) {
        assembly {
            function checkField(v) {
                if iszero(lt(v, q)) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }

            // G1 function to multiply a G1 value(x,y) to value in an address
            function g1_mulAccC(pR, x, y, s) {
                let success
                let mIn := mload(0x40)
                mstore(mIn, x)
                mstore(add(mIn, 32), y)
                mstore(add(mIn, 64), s)

                success := staticcall(sub(gas(), 2000), 7, mIn, 96, mIn, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0, 0x20)
                }

                mstore(add(mIn, 64), mload(pR))
                mstore(add(mIn, 96), mload(add(pR, 32)))

                success := staticcall(sub(gas(), 2000), 6, mIn, 128, pR, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }

            function checkPairing(pA, pB, pC, pubSignals, pMem) -> isOk {
                let _pPairing := add(pMem, pPairing)
                let _pVk := add(pMem, pVk)

                mstore(_pVk, IC0x)
                mstore(add(_pVk, 32), IC0y)

                // Compute the linear combination vk_x

                g1_mulAccC(_pVk, IC1x, IC1y, calldataload(add(pubSignals, 0)))

                g1_mulAccC(_pVk, IC2x, IC2y, calldataload(add(pubSignals, 32)))

                g1_mulAccC(_pVk, IC3x, IC3y, calldataload(add(pubSignals, 64)))

                g1_mulAccC(_pVk, IC4x, IC4y, calldataload(add(pubSignals, 96)))

                g1_mulAccC(_pVk, IC5x, IC5y, calldataload(add(pubSignals, 128)))

                g1_mulAccC(_pVk, IC6x, IC6y, calldataload(add(pubSignals, 160)))

                g1_mulAccC(_pVk, IC7x, IC7y, calldataload(add(pubSignals, 192)))

                g1_mulAccC(_pVk, IC8x, IC8y, calldataload(add(pubSignals, 224)))

                g1_mulAccC(_pVk, IC9x, IC9y, calldataload(add(pubSignals, 256)))

                g1_mulAccC(_pVk, IC10x, IC10y, calldataload(add(pubSignals, 288)))

                g1_mulAccC(_pVk, IC11x, IC11y, calldataload(add(pubSignals, 320)))

                g1_mulAccC(_pVk, IC12x, IC12y, calldataload(add(pubSignals, 352)))

                g1_mulAccC(_pVk, IC13x, IC13y, calldataload(add(pubSignals, 384)))

                g1_mulAccC(_pVk, IC14x, IC14y, calldataload(add(pubSignals, 416)))

                g1_mulAccC(_pVk, IC15x, IC15y, calldataload(add(pubSignals, 448)))

                g1_mulAccC(_pVk, IC16x, IC16y, calldataload(add(pubSignals, 480)))

                g1_mulAccC(_pVk, IC17x, IC17y, calldataload(add(pubSignals, 512)))

                g1_mulAccC(_pVk, IC18x, IC18y, calldataload(add(pubSignals, 544)))

                g1_mulAccC(_pVk, IC19x, IC19y, calldataload(add(pubSignals, 576)))


                // -A
                mstore(_pPairing, calldataload(pA))
                mstore(add(_pPairing, 32), mod(sub(q, calldataload(add(pA, 32))), q))

                // B
                mstore(add(_pPairing, 64), calldataload(pB))
                mstore(add(_pPairing, 96), calldataload(add(pB, 32)))
                mstore(add(_pPairing, 128), calldataload(add(pB, 64)))
                mstore(add(_pPairing, 160), calldataload(add(pB, 96)))

                // alpha1
                mstore(add(_pPairing, 192), alphax)
                mstore(add(_pPairing, 224), alphay)

                // beta2
                mstore(add(_pPairing, 256), betax1)
                mstore(add(_pPairing, 288), betax2)
                mstore(add(_pPairing, 320), betay1)
                mstore(add(_pPairing, 352), betay2)

                // vk_x
                mstore(add(_pPairing, 384), mload(add(pMem, pVk)))
                mstore(add(_pPairing, 416), mload(add(pMem, add(pVk, 32))))


                // gamma2
                mstore(add(_pPairing, 448), gammax1)
                mstore(add(_pPairing, 480), gammax2)
                mstore(add(_pPairing, 512), gammay1)
                mstore(add(_pPairing, 544), gammay2)

                // C
                mstore(add(_pPairing, 576), calldataload(pC))
                mstore(add(_pPairing, 608), calldataload(add(pC, 32)))

                // delta2
                mstore(add(_pPairing, 640), deltax1)
                mstore(add(_pPairing, 672), deltax2)
                mstore(add(_pPairing, 704), deltay1)
                mstore(add(_pPairing, 736), deltay2)


                let success := staticcall(sub(gas(), 2000), 8, _pPairing, 768, _pPairing, 0x20)

                isOk := and(success, mload(_pPairing))
            }

            let pMem := mload(0x40)
            mstore(0x40, add(pMem, pLastMem))

            // Validate that all evaluations ∈ F

            checkField(calldataload(add(_pubSignals, 0)))

            checkField(calldataload(add(_pubSignals, 32)))

            checkField(calldataload(add(_pubSignals, 64)))

            checkField(calldataload(add(_pubSignals, 96)))

            checkField(calldataload(add(_pubSignals, 128)))

            checkField(calldataload(add(_pubSignals, 160)))

            checkField(calldataload(add(_pubSignals, 192)))

            checkField(calldataload(add(_pubSignals, 224)))

            checkField(calldataload(add(_pubSignals, 256)))

            checkField(calldataload(add(_pubSignals, 288)))

            checkField(calldataload(add(_pubSignals, 320)))

            checkField(calldataload(add(_pubSignals, 352)))

            checkField(calldataload(add(_pubSignals, 384)))

            checkField(calldataload(add(_pubSignals, 416)))

            checkField(calldataload(add(_pubSignals, 448)))

            checkField(calldataload(add(_pubSignals, 480)))

            checkField(calldataload(add(_pubSignals, 512)))

            checkField(calldataload(add(_pubSignals, 544)))

            checkField(calldataload(add(_pubSignals, 576)))

            checkField(calldataload(add(_pubSignals, 608)))


            // Validate all evaluations
            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            mstore(0, isValid)
             return(0, 0x20)
         }
     }
 }
