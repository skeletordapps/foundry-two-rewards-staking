// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Staking.sol";
import "../src/interfaces/IStaking.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "forge-std/StdStorage.sol";

contract StakingTest is Test, IStaking {
    using SafeMath for uint256;

    ERC20 public token0;
    ERC20 public token1;
    Staking public staking;

    uint256 arbitrumFork;
    string public ARBITRUM_RPC_URL;

    address public TOKEN0_ADDRESS;
    address public TOKEN1_ADDRESS;

    address internal bob;
    address internal alice;
    address internal john;

    uint256 public token0RewardsToInit = 1_000 ether;
    uint256 public token1RewardsToInit = 1_000 ether;

    event RewardsAdded(uint256 token0Amount, uint256 token1Amount);
    event Staked(address indexed account, uint256 amount);
    event StakeWithdrawn(address indexed account, uint256 amount);
    event RewardsClaimed(
        uint256 timestamp,
        address indexed account,
        uint256 token0Amount,
        uint256 token1Amount
    );

    event RewardsCompounded(
        uint256 timestamp,
        address indexed account,
        uint256 amount
    );

    event FeesWithdrawn(uint256 amount);
    event EmergencyWithdrawnFunds(uint256 amountToken0, uint256 amountToken1);

    function setUp() public {
        ARBITRUM_RPC_URL = vm.envString("ARBITRUM_RPC_URL");

        TOKEN0_ADDRESS = vm.envAddress("LEVI_CONTRACT_ADDRESS");
        TOKEN1_ADDRESS = vm.envAddress("USDC_CONTRACT_ADDRESS");

        arbitrumFork = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(arbitrumFork);

        token0 = ERC20(TOKEN0_ADDRESS);
        token1 = ERC20(TOKEN1_ADDRESS);

        staking = new Staking(TOKEN0_ADDRESS, TOKEN1_ADDRESS);

        bob = vm.addr(3);
        vm.label(bob, "bob");

        alice = vm.addr(5);
        vm.label(alice, "alice");

        john = vm.addr(6);
        vm.label(john, "john");
    }
}
