// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {SettingsTest} from "../../Settings.t.sol";

contract WithdrawLockTimeTest is SettingsTest {
    function test_RevertUpdateWithdrawEarlierLockTimeWhenTimeIsOutLimits()
        public
    {
        vm.expectRevert(Settings_Range_Not_Allowed.selector);
        settings.updateWithdrawEarlierFeeLockTime(8 hours);

        vm.expectRevert(Settings_Range_Not_Allowed.selector);
        settings.updateWithdrawEarlierFeeLockTime(50 hours);
    }

    modifier whenIsBetweenLimits() {
        _;
    }

    function test_RevertWhenNotOwnerUpdatingWithdrawEarlierLockTime()
        public
        whenIsBetweenLimits
    {
        vm.startPrank(bob);
        vm.expectRevert("Ownable: caller is not the owner");
        settings.updateWithdrawEarlierFeeLockTime(12 hours);
        vm.stopPrank();
    }

    modifier onlyOwner() {
        _;
    }

    function test_updateWithdrawEarlierLockTime()
        public
        whenIsBetweenLimits
        onlyOwner
    {
        uint256 newTime = 32 hours;
        settings.updateWithdrawEarlierFeeLockTime(newTime);
        assertEq(settings.NEW_WITHDRAW_EARLIER_FEE_LOCK_TIME(), newTime);

        vm.expectRevert(Settings_Apply_Not_Available_Yet.selector);
        settings.applyWithdrawEarlierFeeLockTimeUpdate();

        vm.warp(block.timestamp + settings.SETTINGS_LOCK_TIME());
        settings.applyWithdrawEarlierFeeLockTimeUpdate();

        uint256 lockTime = settings.WITHDRAW_EARLIER_FEE_LOCK_TIME();
        assertEq(lockTime, newTime);
    }
}
