// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {StakingTest} from "../../Staking.t.sol";

/*//////////////////////////////////////////////////////////////////////////
                                WITHDRAW TESTS
//////////////////////////////////////////////////////////////////////////*/

contract WithdrawTest is StakingTest {
    function test_BobPaysTaxForWithdrawEarlier() public {
        init();
        bobStakes();

        (uint256 balance, , , , , ) = staking.stakingDetails(bob);
        assertEq(balance, 500 ether);

        uint256 token0BalanceStart = token0.balanceOf(bob);

        vm.warp(block.timestamp + 10 hours);

        bobWithdrawal();

        uint256 token0BalanceEnd = token0.balanceOf(bob);

        assertEq(
            token0BalanceStart +
                balance -
                ((balance * staking.WITHDRAW_EARLIER_FEE()) / 100),
            token0BalanceEnd
        );
    }

    function test_RevertsAliceZeroWithdrawalTrial() public {
        init();
        aliceStakes();

        vm.expectRevert(Staking_Withdraw_Amount_Cannot_Be_Zero.selector);
        aliceZeroWithdrawal();
    }

    function test_AliceWithdrawalRevertsWithoutStake() public {
        init();

        vm.expectRevert(Staking_No_Balance_Staked.selector);
        aliceWithdrawal();
    }

    function test_JohnWithdrawRevertsWhenExceedsBalance() public {
        init();
        johnStakes();

        vm.expectRevert(Staking_Amount_Exceeds_Balance.selector);
        johnWithdrawalMoreThanHave();
    }

    function test_BobCanWithdrawWithoutPayingTax() public {
        init();
        bobStakes();

        uint256 totalStakedStart = staking.totalStaked();
        (uint256 balance, , , , , ) = staking.stakingDetails(bob);
        assertEq(balance, 500 ether);

        uint256 token0BalanceStart = token0.balanceOf(bob);

        vm.warp(block.timestamp + staking.WITHDRAW_EARLIER_FEE_LOCK_TIME());

        vm.expectEmit(true, true, true, true);
        emit StakeWithdrawn(bob, 500 ether);

        bobWithdrawal();

        uint256 token0BalanceEnd = token0.balanceOf(bob);
        uint256 totalStakedEnd = staking.totalStaked();

        assertEq(balance + token0BalanceStart, token0BalanceEnd);
        assertEq(totalStakedStart - 500 ether, totalStakedEnd);
    }

    function testJohnCanWithdrawAfterStakingPeriod() public {
        init();
        johnStakes();

        vm.warp(block.timestamp + staking.END_STAKING_UNIX_TIME() + 2 days);

        uint256 token0BalanceBefore = token0.balanceOf(john);
        (uint256 stakedBefore, , , , , ) = staking.stakingDetails(john);

        johnWithdrawal();

        uint256 token0BalanceAfter = token0.balanceOf(john);
        (uint256 stakedAfter, , , , , ) = staking.stakingDetails(john);

        assertEq(token0BalanceBefore + stakedBefore, token0BalanceAfter);
        assertEq(stakedAfter, 0);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    FUZZ TESTS
    //////////////////////////////////////////////////////////////////////////*/

    function testFuzz_BobWithdrawal(uint256 amount, uint256 timestamp) public {
        init();
        vm.assume(
            amount > 0 &&
                amount < token0.totalSupply() &&
                amount < staking.MAX_ALLOWED_TO_STAKE() &&
                timestamp <=
                staking.WITHDRAW_EARLIER_FEE_LOCK_TIME() + block.timestamp
        );

        deal(TOKEN0_ADDRESS, address(bob), amount + 10 ether);

        vm.startPrank(bob);
        token0.approve(address(staking), amount * 10);
        staking.stake(amount);
        vm.stopPrank();

        (uint256 stakedBalance, , , , , ) = staking.stakingDetails(bob);

        assertEq(amount, stakedBalance);

        if (timestamp > block.timestamp) {
            vm.warp(block.timestamp + timestamp);
        } else {
            timestamp = block.timestamp;
        }

        assertTrue(block.timestamp <= timestamp);

        uint256 token0BalanceBefore = token0.balanceOf(bob);

        vm.startPrank(bob);

        staking.withdraw(amount);

        (uint256 stakedBalanceAfter, , , , , ) = staking.stakingDetails(bob);

        vm.stopPrank();

        uint256 token0BalanceAfter = token0.balanceOf(bob);

        assertTrue(token0BalanceBefore < token0BalanceAfter);
        assertEq(stakedBalanceAfter, stakedBalance - amount);

        vm.stopPrank();
    }
}
