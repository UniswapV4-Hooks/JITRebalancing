# JIT Rebalancing

> **Assumption:** All trades are transactional, then all trades are going to be fullfiled by the JIT liquidity .

- For our first iteration we will assume the trader is swapping through Uniswap V4
trading curve.


If trader  specifies $\Delta X$ and the current price is $P_{Y/X}$ what is the amount of liquidity that fullfilles the trade
```solidity
struct SwapParams {
    bool zeroForOne;
    int256 amountSpecified;
    uint160 sqrtPriceLimitX96;
}

function beforeSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        bytes calldata hookData
    )
    external
    virtual
    onlyPoolManager
    returns (bytes4, BeforeSwapDelta, uint24 dynamicFee){
            function beforeSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata params, bytes calldata hookData)
        external
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        // define the amount of tokens to be used in the JIT position
        (uint128 amount0, uint128 amount1) = _jitAmounts(key, params);

        // create JIT position
        (,, uint128 liquidity) = _createPosition(key, params, amount0, amount1, hookData);
        _storeLiquidity(liquidity);

        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }
}
    
/// @notice Defines the amount of tokens to be used in the JIT position
/// @dev No tokens should be transferred into the PoolManager by this function. The afterSwap implementation, will handle token flows
/// @param swapParams the swap params passed in during swap
/// @return amount0 the amount of currency0 to be used for JIT position
/// @return amount1 the amount of currency1 to be used for JIT position
function _jitAmounts(PoolKey calldata key, IPoolManager.SwapParams calldata swapParams)
    internal
    virtual
    returns (uint128, uint128);

```
