// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import "../src/JITHook.sol";

contract JITHookTest is Test, Deployers {
    // I need to test that the event for liquidity provision is emmited
    // I need to test that the passive liquidity remains invariant
    // after the trade
    // I need to test how much fee revenue was acquired by th JIT
    // I need to test that the PLP's did not get any fee revenue
}
