// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {StakingTest} from "../../Staking.t.sol";

/*//////////////////////////////////////////////////////////////////////////
                            EMERGENCY WITHDRAW TESTS
//////////////////////////////////////////////////////////////////////////*/

contract CollectFeesTest is StakingTest {
    function test_BobCannotUseEmergencyWithdraw() public {
        vm.startPrank(bob);
        vm.expectRevert("Ownable: caller is not the owner");
        staking.emergencyWithdraw();
        vm.stopPrank();
    }

    function test_OwnerCanUseEmergencyWithdraw() public {
        init();
        bobStakes();
        aliceStakes();

        uint256 contractToken0Balance = token0.balanceOf(address(staking));
        uint256 contractToken1Balance = token1.balanceOf(address(staking));

        uint256 ownerToken0BalanceBefore = token0.balanceOf(staking.owner());
        uint256 ownerToken1BalanceBefore = token1.balanceOf(staking.owner());

        vm.expectEmit(true, true, true, true);
        emit EmergencyWithdrawnFunds(
            contractToken0Balance,
            contractToken1Balance
        );

        staking.emergencyWithdraw();
        uint256 contractToken0BalanceEnd = token0.balanceOf(address(staking));
        uint256 contractToken1BalanceEnd = token1.balanceOf(address(staking));

        uint256 ownerToken0BalanceAfter = token0.balanceOf(staking.owner());
        uint256 ownerToken1BalanceAfter = token1.balanceOf(staking.owner());

        assertTrue(ownerToken0BalanceAfter > ownerToken0BalanceBefore);
        assertEq(contractToken0BalanceEnd, 0);
        assertEq(contractToken1BalanceEnd, 0);
        assertEq(
            ownerToken1BalanceBefore + contractToken1Balance,
            ownerToken1BalanceAfter
        );
        assertEq(staking.totalStaked(), 0);
    }
}
