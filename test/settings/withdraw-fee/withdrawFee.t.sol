// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {SettingsTest} from "../Settings.t.sol";

contract WithdrawFeeTest is SettingsTest {
    function test_RevertUpdateWithdrawEarlierFeeWhenFeeIsOutLimits() public {
        vm.expectRevert(Settings_Range_Not_Allowed.selector);
        settings.updateWithdrawEarlierFee(6);
    }

    modifier whenIsBetweenLimits() {
        _;
    }

    function test_RevertWhenNotOwnerUpdatingWithdrawEarlierFee()
        public
        whenIsBetweenLimits
    {
        vm.startPrank(bob);
        vm.expectRevert("Ownable: caller is not the owner");
        settings.updateWithdrawEarlierFee(4);
        vm.stopPrank();
    }

    modifier whenIsOwner() {
        _;
    }

    function test_updateWithdrawEarlierFee()
        public
        whenIsBetweenLimits
        whenIsOwner
    {
        uint256 newFee = 4;
        settings.updateWithdrawEarlierFee(newFee);
        assertEq(settings.NEW_WITHDRAW_EARLIER_FEE(), newFee);

        vm.expectRevert(Settings_Apply_Not_Available_Yet.selector);
        settings.applyWithdrawEarlierFeeUpdate();

        vm.warp(block.timestamp + settings.SETTINGS_LOCK_TIME());
        settings.applyWithdrawEarlierFeeUpdate();

        uint256 fee = settings.WITHDRAW_EARLIER_FEE();
        assertEq(fee, newFee);
    }
}
