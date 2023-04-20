// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {StakingTest} from "../../Staking.t.sol";
import {UtilsTest} from "../utils/utils.t.sol";

/*//////////////////////////////////////////////////////////////////////////
                            CHECKING REWARDS TESTS
//////////////////////////////////////////////////////////////////////////*/

contract CheckRewardsTest is StakingTest, UtilsTest {
    function test_AliceCannotAccumulateRewards() public {
        init();
        aliceStakes();

        (
            uint256 balance,
            uint256 token0Accumulator,
            uint256 token1Accumulator,
            ,
            ,

        ) = staking.stakingDetails(alice);

        assertTrue(balance < staking.MIN_STAKED_TO_REWARD());
        assertEq(balance, 100 ether);
        assertEq(token0Accumulator, 0);
        assertEq(token1Accumulator, 0);
    }

    function test_JonhStartsAccumulatingRewards() public {
        init();
        vm.warp(block.timestamp + 2 days);

        johnStakes();

        (
            uint256 balance,
            uint256 token0Accumulator,
            uint256 token1Accumulator,
            ,
            ,

        ) = staking.stakingDetails(john);

        assertEq(balance, 700 ether);

        assertTrue(balance > staking.MIN_STAKED_TO_REWARD());
        assertTrue(token0Accumulator > 0);
        assertTrue(token1Accumulator > 0);

        vm.warp(block.timestamp + 3 days);

        uint256 token0Rewards = staking.calculateReward(john, YieldType.TOKEN0);
        uint256 token1Rewards = staking.calculateReward(john, YieldType.TOKEN1);
        assertTrue(token0Rewards > 0);
        assertTrue(token1Rewards > 0);
    }
}
