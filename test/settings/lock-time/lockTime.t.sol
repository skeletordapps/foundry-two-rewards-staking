// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {SettingsTest} from "../../Settings.t.sol";

contract LockTimeTest is SettingsTest {
    function test_RevertUpdateSettingsLockTimeWhenTimeIsOutLimits() public {
        vm.expectRevert(Settings_Range_Not_Allowed.selector);
        settings.updateSettingsLockTime(48 hours);
    }

    function test_RevertWhenNotOwnerUpdatingSettingsLockTime() public {
        vm.startPrank(bob);
        vm.expectRevert("Ownable: caller is not the owner");
        settings.updateSettingsLockTime(12 hours);
        vm.stopPrank();
    }

    function test_OwnerCanUpdateSeetingsLockTime() public {
        uint256 newTime = 12 hours;
        settings.updateSettingsLockTime(newTime);
        assertEq(settings.NEW_SETTINGS_LOCK_TIME(), newTime);

        vm.expectRevert(Settings_Apply_Not_Available_Yet.selector);
        settings.applySettingsLockTimeUpdate();

        vm.warp(block.timestamp + settings.SETTINGS_LOCK_TIME());
        settings.applySettingsLockTimeUpdate();

        uint256 lockTime = settings.SETTINGS_LOCK_TIME();
        assertEq(lockTime, newTime);
    }
}
