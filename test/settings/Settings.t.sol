// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/Settings.sol";

contract SettingsTest is Test, ISettings {
    Settings public settings;
    address internal bob;

    function setUp() public {
        settings = new Settings();

        bob = vm.addr(3);
        vm.label(bob, "bob");
    }

    function testMock() external {}
}
