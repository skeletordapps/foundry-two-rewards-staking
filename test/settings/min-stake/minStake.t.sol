// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {SettingsTest} from "../Settings.t.sol";

contract MinStakeTest is SettingsTest {
    function test_RevertWhenNotOwnerUpdatingMinStakedToReward() public {
        vm.startPrank(bob);
        vm.expectRevert("Ownable: caller is not the owner");
        settings.updateMinStakedToReward(300 ether);
        vm.stopPrank();
    }

    modifier whenIsOwner() {
        _;
    }

    function test_updateMinStakedToReward() public whenIsOwner {
        uint256 newMin = 300 ether;
        settings.updateMinStakedToReward(newMin);
        assertEq(settings.NEW_MIN_STAKED_TO_REWARD(), newMin);

        vm.expectRevert(Settings_Apply_Not_Available_Yet.selector);
        settings.applyMinStakedToRewardUpdate();

        vm.warp(block.timestamp + settings.SETTINGS_LOCK_TIME());
        settings.applyMinStakedToRewardUpdate();

        uint256 min = settings.MIN_STAKED_TO_REWARD();
        assertEq(min, newMin);
    }
}
