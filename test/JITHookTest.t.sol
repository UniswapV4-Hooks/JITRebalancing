// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import "../src/JITHook.sol";
import {SqrtPriceMath} from "v4-core/libraries/SqrtPriceMath.sol";
import {PoolSwapTest} from "v4-core/test/PoolSwapTest.sol";

contract JITHookTest is Test, Deployers {
    using SqrtPriceMath for uint160;
    using StateLibrary for IPoolManager;
    using TickBitmap for *;
    using NonzeroDeltaCount for *;
    // I need to test that the event for liquidity provision is emmited
    // I need to test that the passive liquidity remains invariant
    // after the trade
    // I need to test how much fee revenue was acquired by th JIT
    // I need to test that the PLP's did not get any fee revenue

    // We need to add as state variable our hook

    JITHook private jitHook;
    //Let us set our test enviroment first,
    function setUp() public {
        //1. We need to deploy fresh manager and routers
        deployFreshManagerAndRouters();
        deployMintAndApprove2Currencies();

        address jitHookAddress = address(uint160(Hooks.BEFORE_SWAP_FLAG));
        deployCodeTo("JITHook.sol", abi.encode(manager), jitHookAddress);
        jitHook = JITHook(jitHookAddress);
        (key, ) = initPool(
            currency0,
            currency1,
            IHooks(jitHookAddress),
            3000,
            SQRT_PRICE_1_2
        );

        // We deploy a pool with
        // the following params
        // (P_Y/X = 1/2, f = 0.03, tickSpacing = 60, hook = JITHook)
        // Notice at this point we have:

        // The pool does not have any liquidity (a.k.a no PLP)
        // The pool initialParams are
        // (P_Y/X = 1/2, f = 0.03, tickSpacing = 60, hook = JITHook)
    }

    // And let us assume that we hill be optimal
    // on calculating its max acceptable excecution price
    function test__ShouldAddPLPLiquidity() public {
        bool zeroForOne = true;
        int256 amountSpecified = -int256(100);
        uint256 amountIn = uint256(-amountSpecified);
        int24 tickOffset = int24(3);
        (
            uint160 sqrtPriceX96,
            int24 tick,
            uint24 unused1,
            uint24 unused2
        ) = manager.getSlot0(key.toId());
        int24 validTick = tick.compress(key.tickSpacing) * key.tickSpacing;
        //With the current tick I can provide and tickOffset
        // I can determine the tickRange since the key holds
        // the tickSpacing, then:
        int24 tickLower = (validTick - (tickOffset * key.tickSpacing)).compress(
            key.tickSpacing
        ) * key.tickSpacing;
        int24 tickUpper = (tick + (tickOffset * key.tickSpacing)).compress(
            key.tickSpacing
        ) * key.tickSpacing;
        modifyLiquidityRouter.modifyLiquidity(
            key,
            ModifyLiquidityParams({
                tickLower: tickLower,
                tickUpper: tickUpper,
                liquidityDelta: 1e30,
                salt: 0
            }),
            ZERO_BYTES
        );
        uint128 liquidity = manager.getLiquidity(key.toId());
        assertEq(liquidity, 1e30);
    }
    // I need to test that although there is no passive
    // liquidity on the pool, a swapper can still do a trade
    // thanks to JIT liquidity
    // This implies that swapRouter is going to call
    // for a zeroForOne, amountSpecifed< 0 and the maxSlippage
    // calculated by the helper and then the trade will be excecuting on beforeSwap
    // thanks to the JIT liquidity
    function test__ShouldFulfillTradeWithJITLiquidity() public {
        test__ShouldAddPLPLiquidity();
        int256 amountSpecified = -1e25;
        BalanceDelta delta = swapRouter.swap(
            key,
            SwapParams({
                zeroForOne: true,
                amountSpecified: amountSpecified,
                sqrtPriceLimitX96: MIN_PRICE_LIMIT
            }),
            PoolSwapTest.TestSettings({
                takeClaims: false,
                settleUsingBurn: false
            }),
            ZERO_BYTES
        );
        console.log("Delta Counts", NonzeroDeltaCount.read());
    }
}
