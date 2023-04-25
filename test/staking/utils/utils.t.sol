//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import {StakingTest} from "../Staking.t.sol";

/*//////////////////////////////////////////////////////////////////////////
                                HELPER FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

contract UtilsTest is StakingTest {
    function init() public {
        token0.approve(address(staking), 5_000 ether);
        deal(TOKEN0_ADDRESS, staking.owner(), 2_000 ether);

        token1.approve(address(staking), 5_000 ether);
        deal(TOKEN1_ADDRESS, staking.owner(), 2_000 ether);

        staking.init(1_000 ether, token0RewardsToInit, token1RewardsToInit);
    }

    function bobStakes() public {
        vm.startPrank(bob);
        token0.approve(address(staking), 600 ether);
        deal(TOKEN0_ADDRESS, bob, 600 ether);
        staking.stake(500 ether);
        vm.stopPrank();
    }

    function bobWithdrawal() public {
        vm.startPrank(bob);
        staking.withdraw(500 ether);
        vm.stopPrank();
    }

    function bobClaimsRewardsWithNoOptions() public {
        vm.startPrank(bob);
        staking.claimRewards(false, false, false);
        vm.stopPrank();
    }

    function bobClaimsToken0AndToken1Rewards() public {
        vm.startPrank(bob);
        staking.claimRewards(true, true, false);
        vm.stopPrank();
    }

    function aliceStakes() public {
        vm.startPrank(alice);
        token0.approve(address(staking), 600 ether);
        deal(TOKEN0_ADDRESS, alice, 600 ether);
        staking.stake(100 ether);
        vm.stopPrank();
    }

    function aliceZeroWithdrawal() public {
        vm.startPrank(alice);
        staking.withdraw(0);
        vm.stopPrank();
    }

    function aliceWithdrawal() public {
        vm.startPrank(alice);
        staking.withdraw(100 ether);
        vm.stopPrank();
    }

    function johnStakes() public {
        vm.startPrank(john);

        token0.approve(address(staking), 1_000 ether);
        token0.approve(staking.owner(), 1_000 ether);

        deal(TOKEN0_ADDRESS, john, 1_000 ether);
        staking.stake(700 ether);

        vm.stopPrank();
    }

    function johnCompoundsRewards() public {
        vm.startPrank(john);
        staking.claimRewards(false, false, true);
        vm.stopPrank();
    }

    function johnWithdrawalMoreThanHave() public {
        vm.startPrank(john);
        staking.withdraw(800 ether);
        vm.stopPrank();
    }

    function johnWithdrawal() public {
        vm.startPrank(john);
        staking.withdraw(700 ether);
        vm.stopPrank();
    }

    function generateFeesFromEarlierWithdrawals() public {
        bobStakes();
        aliceStakes();
        johnStakes();

        vm.warp(block.timestamp + 10 hours);

        bobWithdrawal();
        aliceWithdrawal();
        johnWithdrawal();
    }

    function testMock() external {}
}
