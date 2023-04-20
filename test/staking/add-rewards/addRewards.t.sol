// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {StakingTest} from "../../Staking.t.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

/*//////////////////////////////////////////////////////////////////////////
                                    ADD REWARDS TESTS
//////////////////////////////////////////////////////////////////////////*/

contract CollectFeesTest is StakingTest {
    function test_addRewards() public {
        uint256 token0Amount = 100 ether;
        uint256 token1Amount = 200 ether;

        // Approve the contract to spend the required amount of tokens
        IERC20(TOKEN0_ADDRESS).approve(address(this), token0Amount);
        IERC20(TOKEN1_ADDRESS).approve(address(this), token1Amount);
        IERC20(TOKEN0_ADDRESS).approve(address(staking), token0Amount);
        IERC20(TOKEN1_ADDRESS).approve(address(staking), token1Amount);

        deal(TOKEN0_ADDRESS, address(this), token0Amount);
        deal(TOKEN1_ADDRESS, address(this), token1Amount);
        deal(TOKEN0_ADDRESS, address(staking), token0Amount);
        deal(TOKEN1_ADDRESS, address(staking), token1Amount);

        uint256 token0Balance = token0.balanceOf(address(staking));
        uint256 token1Balance = token1.balanceOf(address(staking));

        // Call the `addRewards` function
        staking.addRewards(token0Amount, token1Amount);

        uint256 token0BalanceAfter = token0.balanceOf(address(staking));
        uint256 token1BalanceAfter = token1.balanceOf(address(staking));

        // Verify that the rewards have been added
        assert(token0Balance + token0Amount == token0BalanceAfter);
        assert(token1Balance + token1Amount == token1BalanceAfter);
    }
}
