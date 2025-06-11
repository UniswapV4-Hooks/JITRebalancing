// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import {Test, console} from "forge-std/Test.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import "v4-periphery/src/utils/BaseHook.sol";
import {LiquidityAmounts} from "v4-periphery/src/libraries/LiquidityAmounts.sol";
import "v4-core/types/BalanceDelta.sol";

contract LiquidityForTradeTest is Test {
    using LiquidityAmounts for uint160;
    using BalanceDeltaLibrary for *;
    function setUp() public {}
    // 0xfffffffffff7ba6ae9ebfeb7b60000000000000000041f9b7c82d1631ced1a39
    function testBalanceDelta() external pure {
        BalanceDelta delta = abi.decode(
            hex"fffffffffff7ba6ae9ebfeb7b60000000000000000041f9b7c82d1631ced1a39",
            (BalanceDelta)
        );
        console.log("Delta Amount 0", delta.amount0());
        console.log("Delta Amount 1", delta.amount1());
    }
}
