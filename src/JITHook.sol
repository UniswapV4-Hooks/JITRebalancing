// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "v4-periphery/src/utils/BaseHook.sol";
import {PoolId} from "v4-core/types/PoolId.sol";
import {StateLibrary} from "v4-core/libraries/StateLibrary.sol";
import {LiquidityAmounts} from "v4-periphery/src/libraries/LiquidityAmounts.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";

contract JITHook is BaseHook {
    using StateLibrary for IPoolManager;
    using LiquidityAmounts for uint160;
    using TickMath for *;

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
            // I am specifying amount0:
            // if amountSpecified <0:
            //      I am specifying the amount
            //      of token0 I will deposit(sell)
            if (params.amountSpecified < 0) {
                uint256 amount0ToDeposit = uint256(-params.amountSpecified);
                // If this is the case
                // because I will be selling amount0ToDeposit
                // Then the trade can only move the price down
                // then sqrtPricex96 will be the upperBound
                uint160 sqrtPriceX96UpperBound = sqrtPriceX96;
                // therefore the slippage the trader specified
                // is the lower bound
                uint160 sqrtPriceX96LowerBound = params.sqrtPriceLimitX96;
                // With this I can get the amount of
                // liquidity received for amount0ToDeposit
                uint128 liquidityForTrade = sqrtPriceX96LowerBound
                    .getLiquidityForAmount0(
                        sqrtPriceX96UpperBound,
                        amount0ToDeposit
                    );
                // Given this liquidityForTrade I need the
                // equivalent uint256 liquidityDelta that
                // fits on the modifyLiquidityParams
                // How do I go from uint128 liquidity
                // to uint256 liquidityDelta?
                int256 validLiquidityDelta = int256(uint256(liquidityForTrade));
                // Finaly I just need th valid tickLower
                // and valid tickUpper for the modifyLiquidityParams
                (int24 tickLower, int24 tickUpper) = (
                    sqrtPriceX96LowerBound.getTickAtSqrtPrice(),
                    sqrtPriceX96UpperBound.getTickAtSqrtPrice()
                );
                poolManager.modifyLiquidity(
                    key,
                    ModifyLiquidityParams({
                        tickLower: tickLower,
                        tickUpper: tickUpper,
                        liquidityDelta: validLiquidityDelta,
                        salt: 0
                    }),
                    ""
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
