// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {SettingsTest} from "../Settings.t.sol";

contract StakingPeriodTest is SettingsTest {
    function test_RevertWhenNotOwnerUpdatingStakingPeriod() public {
        vm.startPrank(bob);
        vm.expectRevert("Ownable: caller is not the owner");
        settings.updateStakingPeriod(block.timestamp + 3 days);
        vm.stopPrank();
    }

    modifier whenIsOwner() {
        _;
    }

    function test_updateStakingPeriod() public whenIsOwner {
        uint256 updatedAt = block.timestamp;
        uint256 newPeriod = 3 days;
        settings.updateStakingPeriod(newPeriod);

        assertEq(
            settings.NEW_END_STAKING_UNIX_TIME(),
            block.timestamp + newPeriod
        );

        vm.expectRevert(Settings_Apply_Not_Available_Yet.selector);
        settings.applyStakingPeriodUpdate();

        vm.warp(block.timestamp + settings.SETTINGS_LOCK_TIME());
        settings.applyStakingPeriodUpdate();

        uint256 period = settings.END_STAKING_UNIX_TIME();

        assertEq(period, newPeriod + updatedAt);
    }
}
