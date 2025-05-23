//SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

// The manager of all asset manager is an  ERC-6909
// ERC-4626 Is the accountant  (asset manager) of one asset balance among all its pools

// The balance of token X owned by this contract represents
// the maximum portion of each token available for JIT transactions
// at some point in time

// ==================SERVICES=======================

// ================QUERIES=================
// About the asset managed:

//=====Give the address of the asset managed ====

// function asset() returns (address) -- X.address

//=====Give me the total balance of the asset managed====

// function totalAssets() returns (uint256) -- this.X.totalBalance

//=============COMMANDS=====================
// EIP: Mints a calculated number of vault shares to
// receiver by depositing an exact number
// of underlying asset tokens, specified by user.

// function deposit(uint256 X, address pi)
// --> returns (uint256 Xpi )

// EIP: Mints exact number of vault shares to receiver,
// as specified by user, by calculating number
// of required shares of underlying asset.

// function mint(uint256 X.pi, address pi)
// --> returns (uint256 X)

// Then if we want each Liquidity Pool to have its own
// dedicated portion of a budget X

//p1 -> (X, Y)
//p2 -> (X, Z) --> pi.X-> Xpi
//p3 -> (X, R)

// Then dX -> for all i dXpi
// dX > dlmX --> deposit(dlmX) --> dX' > dX

// One can implement a custom matyh formula
// to determine f: X --> Xpi

// {
//         "name": "Vault Manager",
//         "services": [
//             {
//                 "name": "manageDeposits",
//                 "Triggering Events": [
//                     { "name": "LP deposit request" }
//                 ],
//                 "Delivered Services": [
//                     { "name": "Accept and record LP deposits" }
//                 ],
//                 "Assumptions": [
//                     { "name": "LPs interact via approved interface" }
//                 ]
//             },
//             {
//                 "name": "manageWithdrawals",
//                 "Triggering Events": [
//                     { "name": "LP withdrawal request" }
//                 ],
//                 "Delivered Services": [
//                     { "name": "Process and record LP withdrawals" }
//                 ],
//                 "Assumptions": [
//                     { "name": "Sufficient liquidity is available" }
//                 ]
//             }
//         ]
//     }

// Considering the above.

// Assuming after beforeSwap() we know the size of the trade
// we will be providing JIT liquidity for
// Then given this amount we must do the following:

// -----> hook.modifyLiquidity(rx, tikcs Where trrade will move)

import {IERC6909} from "forge-std/interfaces/IERC6909.sol";
import "v4-periphery/src/utils/BaseHook.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import "./types/Inventories.sol";
import "./JITLiquidityManager.sol";
abstract contract JITLiquidityRouter is IERC6909, BaseHook {
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
                afterSwap: true,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnDelta: false,
                afterSwapReturnDelta: false,
                afterAddLiquidityReturnDelta: false,
                afterRemoveLiquidityReturnDelta: false
            });
    }
    /// @notice The hook called before a swap
    /// @param sender The initial msg.sender for the swap call
    /// @param key The key for the pool
    /// @param params The parameters for the swap
    /// @param hookData Arbitrary data handed into the PoolManager by the swapper to be be passed on to the hook
    /// @return bytes4 The function selector for the hook
    /// @return BeforeSwapDelta The hook's delta in specified and unspecified currencies. Positive: the hook is owed/took currency, negative: the hook owes/sent currency
    /// @return uint24 Optionally override the lp fee, only used if three conditions are met: 1. the Pool has a dynamic fee, 2. the value's 2nd highest bit is set (23rd bit, 0x400000), and 3. the value is less than or equal to the maximum fee (1 million)
    // function beforeSwap(
    //     address sender,
    //     PoolKey calldata key,
    //     SwapParams calldata params,
    //     bytes calldata hookData
    // ) external returns (bytes4, BeforeSwapDelta, uint24) {
    //     // 1. How much fee-revenue would enabling this trade give me?
    //     // THIS IS TO BE ASKED TO THE LiquidityFeeRevenueManager
    //     // - 1.2 Given this amount of liquidity providers what will be my portion of the fee-revenue?
    //     // - 1.3 Calculate the optimal amount of liquidity to provide
    //     // --- 1.3.1 Find rx* -> max f*rx*
    //     // Assuming we have rx* we do:
    //     // ----> rx = ERC4626.withdraw(rx = rx*, receiver = hook, owner = PoolManager)
    //     // -----> X.approve(hook, rx)
    // }

    // /// @notice The hook called after a swap
    // /// @param sender The initial msg.sender for the swap call
    // /// @param key The key for the pool
    // /// @param params The parameters for the swap
    // /// @param delta The amount owed to the caller (positive) or owed to the pool (negative)
    // /// @param hookData Arbitrary data handed into the PoolManager by the swapper to be be passed on to the hook
    // /// @return bytes4 The function selector for the hook
    // /// @return int128 The hook's delta in unspecified currency. Positive: the hook is owed/took currency, negative: the hook owes/sent currency
    // function afterSwap(
    //     address sender,
    //     PoolKey calldata key,
    //     SwapParams calldata params,
    //     BalanceDelta delta,
    //     bytes calldata hookData
    // ) external returns (bytes4, int128);
}
