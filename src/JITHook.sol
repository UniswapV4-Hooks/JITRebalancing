// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "v4-periphery/src/utils/BaseHook.sol";
import {PoolId} from "v4-core/types/PoolId.sol";
import {StateLibrary} from "v4-core/libraries/StateLibrary.sol";
import {LiquidityAmounts} from "v4-periphery/src/libraries/LiquidityAmounts.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {TickBitmap} from "v4-core/libraries/TickBitmap.sol";
import "v4-core/types/BeforeSwapDelta.sol";
import {NonzeroDeltaCount} from "v4-core/libraries/NonzeroDeltaCount.sol";
contract JITHook is BaseHook {
    using StateLibrary for IPoolManager;
    using LiquidityAmounts for uint160;
    using TickMath for *;
    using TickBitmap for *;
    using BeforeSwapDeltaLibrary for *;
    using NonzeroDeltaCount for *;
    constructor(IPoolManager _manager) BaseHook(_manager) {}

    function getHookPermissions()
        public
        pure
        override
        returns (Hooks.Permissions memory)
    {
        return
            Hooks.Permissions({
                beforeInitialize: false,
                afterInitialize: false,
                beforeAddLiquidity: false,
                afterAddLiquidity: false,
                beforeRemoveLiquidity: false,
                afterRemoveLiquidity: false,
                beforeSwap: true,
                afterSwap: false, // eventually this will be true
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnDelta: false,
                afterSwapReturnDelta: false,
                afterAddLiquidityReturnDelta: false,
                afterRemoveLiquidityReturnDelta: false
            });
    }

    event JITLiquidityDeltas(
        int128 indexed liquidity0,
        int128 indexed liquidity1,
        int128 feesAccrued0,
        int128 feesAccrued1
    );
    function beforeSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        bytes calldata hookData
    )
        external
        override(BaseHook)
        onlyPoolManager
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        //given the swapParams I wnat to know the liquidity to
        // enable the trade
        // Regardless of the sign of amountSpecified I need to get the price
        // to enable the trade, this is done using the stateLibrary
        (uint160 sqrtPriceX96, int24 tick, , ) = poolManager.getSlot0(
            key.toId()
        );
        if (params.zeroForOne) {
            // I am swapping token0 for token1
            // I am specifying amountSpecified= amount0ToBe...:
            if (params.amountSpecified < 0) {
                //      I am specifying the amount0ToBeSold
                uint256 amount0ToBeSold = uint256(-params.amountSpecified);
                // If this is the case
                // because I will be selling amount0ToBeSold to the AMM
                // then the AMM is quoting P_1/0 how much of token1
                // does the AMM give in exchange for amount0ToBeSold
                // This means that, then the amount of reserves of token0
                // will increase and token1 will decrease leading
                // to PRICE GOING DOWN
                // If price goes down the upper bound is the current price
                uint160 sqrtPriceX96UpperBound = sqrtPriceX96;
                // Now the JIT will provide liquidity for the whole trade
                // then he/she sets the sqrtPriceX96UpperBound to the
                // sqrtPriceLimitX96 specified by the trader
                uint160 sqrtPriceX96LowerBound = params.sqrtPriceLimitX96;
                // Finaly I just need th valid tickLower
                // and valid tickUpper for the modifyLiquidityParams

                // Validate the ticks are consistent
                // with the tickSpacing specified on the pool initialization

                (int24 tickLower, int24 tickUpper) = (
                    sqrtPriceX96LowerBound.getTickAtSqrtPrice().compress(
                        key.tickSpacing
                    ) *
                        key.tickSpacing -
                        key.tickSpacing,
                    sqrtPriceX96UpperBound.getTickAtSqrtPrice().compress(
                        key.tickSpacing
                    ) * key.tickSpacing
                );
                // If ticks range on edges they need to take the max and
                //min tick allowed on the pool
                //This is:

                if (tickLower <= TickMath.MIN_TICK) {
                    tickLower = key.tickSpacing.minUsableTick();
                }
                if (tickUpper >= TickMath.MAX_TICK) {
                    tickUpper = key.tickSpacing.maxUsableTick();
                }
                // With this I can get the amount of
                // liquidity received for amount0ToDeposit
                int256 liquidityForTrade = int256(
                    uint256(
                        sqrtPriceX96LowerBound.getLiquidityForAmount0(
                            sqrtPriceX96UpperBound,
                            amount0ToBeSold
                        )
                    )
                );

                (
                    BalanceDelta callerDelta,
                    BalanceDelta feesAccrued
                ) = poolManager.modifyLiquidity(
                        key,
                        ModifyLiquidityParams({
                            tickLower: tickLower,
                            tickUpper: tickUpper,
                            liquidityDelta: liquidityForTrade,
                            salt: 0
                        }),
                        ""
                    );
                emit JITLiquidityDeltas(
                    callerDelta.amount0(),
                    callerDelta.amount1(),
                    feesAccrued.amount0(),
                    feesAccrued.amount1()
                );

                return (
                    IHooks.beforeSwap.selector,
                    toBeforeSwapDelta(int128(0), int128(0)),
                    0
                );
                // There is information that needs to reside on tstorage
                // becuase we need it for the afterSwap to withdraw liquidity
            }
            // if amount0 >0:
            //      I am saying I want to buy
            //      amount0 from the pool and see
            //      what amount1 I need to deposit
        }
    }
}
