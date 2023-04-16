// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Settings.sol";

contract SettingsTest is Test {
    Settings public settings;
    address internal bob;

    function setUp() public {
        settings = new Settings();

        bob = vm.addr(3);
        vm.label(bob, "bob");
    }

    function test_RevertWhenTryUpdateRewardsBefore24h() public {
        uint256 token0Value = 100 ether;
        uint256 token1Value = 200 ether;

        settings.updateRewardsPerDay(token0Value, token1Value);

        vm.expectRevert(Settings_Apply_Not_Available_Yet.selector);
        settings.applyRewardsUpdate();
    }

    function test_OnlyOwnerCanUpdateRewards() public {
        uint256 token0Value = 100 ether;
        uint256 token1Value = 200 ether;

        vm.startPrank(bob);
        vm.expectRevert("Ownable: caller is not the owner");
        settings.updateRewardsPerDay(token0Value, token1Value);
        vm.stopPrank();

        settings.updateRewardsPerDay(token0Value, token1Value);
        assertEq(settings.NEW_TOKEN0_REWARDS_PER_SECOND(), token0Value / 86400);
        assertEq(settings.NEW_TOKEN1_REWARDS_PER_SECOND(), token1Value / 86400);

        vm.warp(block.timestamp + 30 days);

        vm.startPrank(bob);
        vm.expectRevert("Ownable: caller is not the owner");
        settings.applyRewardsUpdate();
        vm.stopPrank();

        settings.applyRewardsUpdate();
        assertEq(settings.TOKEN0_REWARDS_PER_SECOND(), token0Value / 86400);
        assertEq(settings.TOKEN1_REWARDS_PER_SECOND(), token1Value / 86400);
    }

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

    function test_RevertUpdateWithdrawEarlierLockTimeWhenTimeIsOutLimits()
        public
    {
        vm.expectRevert(Settings_Range_Not_Allowed.selector);
        settings.updateWithdrawEarlierFeeLockTime(8 hours);

        vm.expectRevert(Settings_Range_Not_Allowed.selector);
        settings.updateWithdrawEarlierFeeLockTime(50 hours);
    }

    function test_RevertWhenNotOwnerUpdatingWithdrawEarlierLockTime() public {
        vm.startPrank(bob);
        vm.expectRevert("Ownable: caller is not the owner");
        settings.updateWithdrawEarlierFeeLockTime(12 hours);
        vm.stopPrank();
    }

    function test_OwnerCanUpdateWithdrawEarlierLockTime() public {
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

    function test_RevertUpdateWithdrawEarlierFeeWhenFeeIsOutLimits() public {
        vm.expectRevert(Settings_Range_Not_Allowed.selector);
        settings.updateWithdrawEarlierFee(0);

        vm.expectRevert(Settings_Range_Not_Allowed.selector);
        settings.updateWithdrawEarlierFee(6);
    }

    function test_RevertWhenNotOwnerUpdatingWithdrawEarlierFee() public {
        vm.startPrank(bob);
        vm.expectRevert("Ownable: caller is not the owner");
        settings.updateWithdrawEarlierFee(4);
        vm.stopPrank();
    }

    function test_OwnerCanUpdateWithdrawEarlierFee() public {
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

    function test_RevertWhenNotOwnerUpdatingMinStakedToReward() public {
        vm.startPrank(bob);
        vm.expectRevert("Ownable: caller is not the owner");
        settings.updateMinStakedToReward(300 ether);
        vm.stopPrank();
    }

    function test_OwnerCanUpdateMinStakedToReward() public {
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
