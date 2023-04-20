// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {StakingTest} from "../../Staking.t.sol";
import {UtilsTest} from "../utils/utils.t.sol";

/*//////////////////////////////////////////////////////////////////////////
                                CLAIM REWARDS TESTS
//////////////////////////////////////////////////////////////////////////*/

contract ClaimRewardsTest is StakingTest, UtilsTest {
    function setUp() public override {
        super.setUp();
        init();
    }

    function test_CannotClaimWhenHasOptionsSelected() public {
        bobStakes();

        vm.expectRevert(Staking_No_Rewards_Options_Selected.selector);
        bobClaimsRewardsWithNoOptions();
    }

    function test_BobClaimsZeroRewards() public {
        bobStakes();

        vm.expectEmit(true, true, true, true);
        emit RewardsClaimed(block.timestamp, bob, 0, 0);
        bobClaimsToken0AndToken1Rewards();
    }

    function test_BobClaimsBothRewards() public {
        vm.warp(block.timestamp + 1 days);
        johnStakes();

        vm.warp(block.timestamp + 1 days);
        bobStakes();

        vm.warp(block.timestamp + 5 days);

        uint256 bobToken0BalanceBefore = token0.balanceOf(bob);
        uint256 bobToken1BalanceBefore = token1.balanceOf(bob);

        uint256 token0RewardsBefore = staking.calculateReward(
            bob,
            YieldType.TOKEN0
        );
        uint256 token1RewardsBefore = staking.calculateReward(
            bob,
            YieldType.TOKEN1
        );

        vm.expectEmit(true, true, true, true);
        emit RewardsClaimed(block.timestamp, bob, token0RewardsBefore, 0);
        emit RewardsClaimed(block.timestamp, bob, 0, token1RewardsBefore);

        bobClaimsToken0AndToken1Rewards();

        uint256 bobToken0BalanceAfter = token0.balanceOf(bob);
        uint256 bobToken1BalanceAfter = token1.balanceOf(bob);

        uint256 token0RewardsAfter = staking.calculateReward(
            bob,
            YieldType.TOKEN0
        );
        uint256 token1RewardsAfter = staking.calculateReward(
            bob,
            YieldType.TOKEN1
        );

        assertEq(
            bobToken0BalanceBefore + token0RewardsBefore,
            bobToken0BalanceAfter
        );
        assertEq(token0RewardsAfter, 0);

        assertEq(
            bobToken1BalanceBefore + token1RewardsBefore,
            bobToken1BalanceAfter
        );
        assertEq(token1RewardsAfter, 0);
    }

    function test_BobCanClaimRewardsAfterStakingPeriod() public {
        bobStakes();

        vm.warp(block.timestamp + staking.END_STAKING_UNIX_TIME() + 2 days);

        uint256 bobToken0BalanceBefore = token0.balanceOf(bob);
        uint256 bobToken1BalanceBefore = token1.balanceOf(bob);

        uint256 token0RewardsBefore = staking.calculateReward(
            bob,
            YieldType.TOKEN0
        );
        uint256 token1RewardsBefore = staking.calculateReward(
            bob,
            YieldType.TOKEN1
        );

        vm.expectEmit(true, true, true, true);
        emit RewardsClaimed(block.timestamp, bob, token0RewardsBefore, 0);
        emit RewardsClaimed(block.timestamp, bob, 0, token1RewardsBefore);

        bobClaimsToken0AndToken1Rewards();

        uint256 bobToken0BalanceAfter = token0.balanceOf(bob);
        uint256 bobToken1BalanceAfter = token1.balanceOf(bob);

        uint256 token0RewardsAfter = staking.calculateReward(
            bob,
            YieldType.TOKEN0
        );
        uint256 token1RewardsAfter = staking.calculateReward(
            bob,
            YieldType.TOKEN1
        );

        assertEq(
            bobToken0BalanceBefore + token0RewardsBefore,
            bobToken0BalanceAfter
        );
        assertEq(token0RewardsAfter, 0);

        assertEq(
            bobToken1BalanceBefore + token1RewardsBefore,
            bobToken1BalanceAfter
        );
        assertEq(token1RewardsAfter, 0);
    }

    function test_JohnCompoundsRewards() public {
        vm.warp(block.timestamp + 1 days);
        johnStakes();

        vm.warp(block.timestamp + 1 days);
        bobStakes();

        vm.warp(block.timestamp + 5 days);

        uint256 token0RewardsBefore = staking.calculateReward(
            john,
            YieldType.TOKEN0
        );

        (uint256 stakedBalanceBefore, , , , , ) = staking.stakingDetails(john);

        vm.expectEmit(true, true, true, true);
        emit RewardsCompounded(block.timestamp, john, token0RewardsBefore);

        johnCompoundsRewards();

        uint256 token0RewardsAfter = staking.calculateReward(
            john,
            YieldType.TOKEN0
        );

        (uint256 stakedBalanceAfter, , , , , ) = staking.stakingDetails(john);

        assertEq(stakedBalanceBefore + token0RewardsBefore, stakedBalanceAfter);
        assertEq(token0RewardsAfter, 0);
    }

    /*//////////////////////////////////////////////////////////////////////////
                        CLAIM REWARDS AFTER WITHDRAWAL TESTS
    //////////////////////////////////////////////////////////////////////////*/

    function testBobClaimRewardsAfterWithdrawal() public {
        vm.warp(block.timestamp + 10 days);

        bobStakes();

        vm.warp(block.timestamp + 10 days);

        uint256 token0Rewards = staking.calculateReward(bob, YieldType.TOKEN0);
        uint256 token1Rewards = staking.calculateReward(bob, YieldType.TOKEN1);

        bobWithdrawal();

        uint256 token0RewardsAfter = staking.calculateReward(
            bob,
            YieldType.TOKEN0
        );

        uint256 token1RewardsAfter = staking.calculateReward(
            bob,
            YieldType.TOKEN1
        );

        assertEq(token0Rewards, token0RewardsAfter);
        assertEq(token1Rewards, token1RewardsAfter);

        uint256 token0Balance = token0.balanceOf(bob);
        uint256 token1Balance = token1.balanceOf(bob);

        bobClaimsToken0AndToken1Rewards();

        uint256 token0BalanceAfter = token0.balanceOf(bob);
        uint256 token1BalanceAfter = token1.balanceOf(bob);

        assertEq(token0Balance + token0RewardsAfter, token0BalanceAfter);
        assertEq(token1Balance + token1RewardsAfter, token1BalanceAfter);
    }

    function testJohnCompoundRewardsAfterWithdrawal() public {
        vm.warp(block.timestamp + 10 days);
        johnStakes();

        vm.warp(block.timestamp + 100 days);

        uint256 token0Rewards = staking.calculateReward(john, YieldType.TOKEN0);

        johnWithdrawal();

        uint256 token0RewardsAfter = staking.calculateReward(
            john,
            YieldType.TOKEN0
        );

        assertEq(token0Rewards, token0RewardsAfter);

        (uint256 stakingBalance, , , , , ) = staking.stakingDetails(john);

        johnCompoundsRewards();

        (uint256 stakingBalanceAfter, , , , , ) = staking.stakingDetails(john);

        assertEq(stakingBalance + token0RewardsAfter, stakingBalanceAfter);
    }
}
