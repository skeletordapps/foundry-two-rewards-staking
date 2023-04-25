// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {SettingsTest} from "../Settings.t.sol";

contract RewardsPerDay is SettingsTest {
    function test_RevertWhenTryUpdateRewardsBefore24h() public {
        uint256 token0Value = 100 ether;
        uint256 token1Value = 200 ether;

        settings.updateRewardsPerDay(token0Value, token1Value);

        vm.expectRevert(Settings_Apply_Not_Available_Yet.selector);
        settings.applyRewardsUpdate();
    }

    modifier whenIsOwner() {
        _;
    }

    function test_updateRewards() public whenIsOwner {
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
}
