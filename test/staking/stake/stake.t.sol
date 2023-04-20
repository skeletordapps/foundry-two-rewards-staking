// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {StakingTest} from "../../Staking.t.sol";
import {UtilsTest} from "../utils/utils.t.sol";

/*//////////////////////////////////////////////////////////////////////////
                                  STAKE TESTS
//////////////////////////////////////////////////////////////////////////*/

contract StakeTest is StakingTest, UtilsTest {
    function test_StakeRevertsWhenNotInitialized() public {
        vm.expectRevert(Staking_Not_Initialized.selector);
        staking.stake(0);
    }

    function test_RevertsWhenStakingEnded() public {
        init();
        vm.warp(block.timestamp + staking.END_STAKING_UNIX_TIME() + 40 days);

        vm.expectRevert(Staking_Period_Ended.selector);
        staking.stake(0);
    }

    function test_RevertsWhenStakingAmountIsZero() public {
        init();

        vm.expectRevert(Staking_Insufficient_Amount_To_Stake.selector);
        staking.stake(0);
    }

    function test_RevertsWhenStakeReachMaxLimit() public {
        init();
        token0.approve(staking.owner(), 200_000_000 ether);
        token0.approve(address(staking), 200_000_000 ether);
        deal(TOKEN0_ADDRESS, staking.owner(), 150_000_000 ether);

        vm.expectRevert(Staking_Max_Limit_Reached.selector);
        staking.stake(120_000_000 ether);
    }

    function test_BobCanStake() public {
        init();

        vm.expectEmit(true, true, true, true);
        emit Staked(bob, 500 ether);

        uint256 totalStakedStart = staking.totalStaked();
        (uint256 startBalance, , , , , ) = staking.stakingDetails(bob);
        bobStakes();
        (uint256 endBalance, , , , , ) = staking.stakingDetails(bob);
        uint256 totalStakedEnd = staking.totalStaked();

        assertTrue(endBalance > startBalance);
        assertEq(endBalance, 500 ether);
        assertEq(totalStakedStart + 500 ether, totalStakedEnd);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    FUZZ TESTS
    //////////////////////////////////////////////////////////////////////////*/

    function testFuzz_BobStaking(uint256 amount) public {
        init();

        uint256 totalSupply = token0.totalSupply();
        uint256 maxStakeLimit = staking.MAX_ALLOWED_TO_STAKE();
        vm.assume(amount > 0 && amount < totalSupply && amount < maxStakeLimit);

        deal(TOKEN0_ADDRESS, address(bob), amount + 10 ether);

        vm.startPrank(bob);
        token0.approve(address(staking), amount * 10);
        staking.stake(amount);
        vm.stopPrank();

        (uint256 stakedBalance, , , , , ) = staking.stakingDetails(bob);
        assertEq(stakedBalance, amount);
    }
}
