// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/Settings.sol";

contract SettingsScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        new Settings();
        vm.stopBroadcast();
    }
}
