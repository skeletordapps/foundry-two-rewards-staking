// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/Staking.sol";

contract StakingScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        address _token0 = vm.envAddress("LEVI_CONTRACT_ADDRESS");
        address _token1 = vm.envAddress("USDC_CONTRACT_ADDRESS");

        new Staking(_token0, _token1);
        vm.stopBroadcast();
    }

    function testMock() external {}
}
