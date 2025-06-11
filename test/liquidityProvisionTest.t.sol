// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {PoolId} from "v4-core/types/PoolId.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {LiquidityAmounts} from "v4-periphery/src/libraries/LiquidityAmounts.sol";
import {SqrtPriceMath} from "v4-core/libraries/SqrtPriceMath.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import "v4-core/types/PoolOperation.sol";
import "v4-core/types/BalanceDelta.sol";

contract liquidityProvisionTest is Test, Deployers {
    using LiquidityAmounts for *;
    using SqrtPriceMath for *;
    using TickMath for *;
    using BalanceDeltaLibrary for BalanceDelta;

    // I want to initializ a pool where the
    // initial price is P_Y/X = 0.5 = 1/2
    // then I want to know what is the tick
    // associated with that price to get
    // the current tick

    function setUp() public {
        // first we deploy the poolManager
        // and the routers
        deployFreshManagerAndRouters();
        // then we deploy the currencies
        // that will be on the pool
        deployMintAndApprove2Currencies();
        // finally I deploy a pool and get the keys
        (key, ) = initPool(
            currency0,
            currency1,
            IHooks(address(0)),
            3000, // fee = 0.03 %
            SQRT_PRICE_1_2
        );
    }

    function test__addingLiquidity() public returns (uint160 maxSqrtPrice) {
        // Pool(Tx, Ty) = (P_Y/X =1/2, f = 0.03)
        //Now I want to provide liquidity around
        // (0.25, 1.15)
        // for this I need the equivalent
        // (sqrtPricex96(0.25), sqrtPricex96(1.15))
        // Q(0.25)_96 = sqrt(0.25)*2^96
        uint160 sqrtPrice0_25x96 = uint160(39614081257132168796771975168);
        // Q(1.15)_96 = sqrt(1.15)*2^96
        uint160 sqrtPrice1_15x96 = uint160(84962738866485956534991847424);

        // The reserves I want to provide as liquidity
        // are R_X = 200, R_Y = 760
        uint256 addedReserveX = 200;
        uint256 addedReserveY = 760;
        uint128 PLP_liquidity_200_760 = SQRT_PRICE_1_2.getLiquidityForAmounts(
            sqrtPrice0_25x96,
            sqrtPrice1_15x96,
            addedReserveX,
            addedReserveY
        );
        // Let's provide the liquidity here
        BalanceDelta liquidityDelta = modifyLiquidityRouter.modifyLiquidity(
            key,
            ModifyLiquidityParams({
                tickLower: sqrtPrice0_25x96.getTickAtSqrtPrice(),
                tickUpper: sqrtPrice1_15x96.getTickAtSqrtPrice(),
                liquidityDelta: int256(uint256(PLP_liquidity_200_760)),
                salt: 0
            }),
            ZERO_BYTES
        );
        int128 liquidityX = liquidityDelta.amount0();
        int128 liquidityY = liquidityDelta.amount1();
        console.log("liquidityX", uint256(uint128(liquidityX)));
        console.log("liquidityY", uint256(uint128(liquidityY)));
        //Now a trader wants to see how much
        //knowing the PLP_liquidity, and the price range
        // current price , as well as swap fee
        // A trader wants to know if depositing amountXIn = 150
        // what is the lower bound of the sqrtPriceMax that
        // he will be willing to pay
        uint256 amountX = 150;
        maxSqrtPrice = SQRT_PRICE_1_2.getNextSqrtPriceFromAmount0RoundingUp(
            PLP_liquidity_200_760,
            amountX,
            true
        );
    }

    // function test__swapMaxSlippage() external pure {
    //     uint160 maxSqrtPrice = helperMaxSwapExecutionPrice();
    //     console.log("Max Slippage cost", uint256(maxSqrtPrice));
    // }
}
