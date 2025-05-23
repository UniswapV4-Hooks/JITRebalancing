//SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "v4-core/libraries/StateLibrary.sol";
// 1.1 How many more liquidity providers would have the
// total fee-income associated with this trade ?

abstract contract JITLiquidityManager {
    using StateLibrary for IPoolManager;
    IPoolManager private immutable poolManager;

    constructor(IPoolManager _manager) {
        poolManager = _manager;
    }
    //1.1.1 What is the current spot price?
    //1.1.2 What is the tick index associated with this price?
    function getSqrtPriceX96AndTick(
        PoolId poolId
    ) internal view virtual returns (uint160 sqrtPriceX96, int24 tick) {
        (sqrtPriceX96, tick, , ) = poolManager.getSlot0(poolId);
    }
    //1.1.3 What is the gross liquidity at this tick index?
    // PoolManager.getTickLiquidity(poolId, tick) returns (uint128 liquidityGross, int128 liquidityNet)
    struct PositionKeyOnTick {
        bytes32 positionKey;
        uint128 liquidityOnTick;
    }
    function getPositionKeysOnTick(
        PoolId poolId,
        int24 tick
    ) internal view returns (PositionKeyOnTick[] memory positionKeysOnTick) {
        (uint128 liquidityTick, ) = poolManager.getTickLiquidity(poolId, tick);

        // Given (i, L(i)):
        // How to find all Positions identified by
        // their respective positionKey active at this tick index?
        //===============POST-CONDITION=========
        // sum(positionKeysOnTick.liquidity() = LiquidityTick)
    }

    //1.1.4 Given (i, L(i) ==>
    //=======INVARIANT==========
    // 1.1.4.1 how many lp's are providing liquidity at this tick index?
    //---- 1.1.4.1.1 Provide a mapping of owner -> Position[poolId, tick].liquidity
    // \sum^{#LP's} l(i)_{lp} = L(i)
}
