// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {StakingTest} from "../Staking.t.sol";
import {UtilsTest} from "../utils/utils.t.sol";

/*//////////////////////////////////////////////////////////////////////////
                                  INIT TESTS
//////////////////////////////////////////////////////////////////////////*/

contract InitTest is StakingTest, UtilsTest {
    function test_SuccessfulyConstructed() public {
        assertEq(staking.TOKEN0(), address(token0));
        assertEq(staking.totalStaked(), 0);
    }

    function test_InitRevertsWhenNotOwner() public {
        vm.prank(bob);
        vm.expectRevert("Ownable: caller is not the owner");
        staking.init(0, 0, 0);
    }

    function test_InitStaking() public {
        vm.expectEmit(true, true, true, true);
        emit RewardsAdded(token0RewardsToInit, token1RewardsToInit);

        init();

        assertTrue(staking.END_STAKING_UNIX_TIME() >= 30 days);
        assertEq(staking.totalStaked(), 1_000 ether);
    }

    function test_InitRevertsWhenAlreadyInitialized() public {
        init();
        vm.expectRevert(Staking_Already_Initialized.selector);
        staking.init(0, 0, 0);
    }
}
