// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {StakingTest} from "../../Staking.t.sol";

/*//////////////////////////////////////////////////////////////////////////
                            COLLECTING FEES TESTS
//////////////////////////////////////////////////////////////////////////*/

contract CollectFeesTest is StakingTest {
    function test_EarlierWithdrawalsGeneratesFees() public {
        init();

        uint256 collectedFeesStart = staking.collectedFees();
        generateFeesFromEarlierWithdrawals();
        uint256 collectedFeesEnd = staking.collectedFees();

        assertTrue(collectedFeesEnd > collectedFeesStart);
    }

    function test_BobCannotClaimCollectedFees() public {
        init();

        generateFeesFromEarlierWithdrawals();

        vm.startPrank(bob);
        vm.expectRevert("Ownable: caller is not the owner");
        staking.collectFees();
    }

    function test_ownerCanClaimCollectedFees() public {
        init();

        generateFeesFromEarlierWithdrawals();

        uint256 contractFeesStart = staking.collectedFees();
        uint256 ownerToken0BalanceStart = token0.balanceOf(staking.owner());

        vm.expectEmit(true, true, true, true);
        emit FeesWithdrawn(contractFeesStart);

        staking.collectFees();

        uint256 contractFeesEnd = staking.collectedFees();
        uint256 ownerToken0BalanceEnd = token0.balanceOf(staking.owner());

        assertTrue(contractFeesStart > 0 && contractFeesEnd == 0);
        assertTrue(ownerToken0BalanceStart == 0 && ownerToken0BalanceEnd > 0);
        assertEq(ownerToken0BalanceEnd, contractFeesStart);
    }
}
