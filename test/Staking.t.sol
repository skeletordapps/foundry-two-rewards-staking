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

    /*//////////////////////////////////////////////////////////////////////////
                                    HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function init() public {
        token0.approve(address(staking), 5_000 ether);
        deal(TOKEN0_ADDRESS, staking.owner(), 2_000 ether);

        token1.approve(address(staking), 5_000 ether);
        deal(TOKEN1_ADDRESS, staking.owner(), 2_000 ether);

        staking.init(1_000 ether, token0RewardsToInit, token1RewardsToInit);

        // staking.updateStakingPeriod(365 days);
        // vm.warp(block.timestamp + staking.SETTINGS_LOCK_TIME());
        // staking.applyStakingPeriodUpdate();
    }

    function bobStakes() public {
        vm.startPrank(bob);
        token0.approve(address(staking), 600 ether);
        deal(TOKEN0_ADDRESS, bob, 600 ether);
        staking.stake(500 ether);
        vm.stopPrank();
    }

    function bobWithdrawal() public {
        vm.startPrank(bob);
        staking.withdraw(500 ether);
        vm.stopPrank();
    }

    function bobClaimsRewardsWithNoOptions() public {
        vm.startPrank(bob);
        staking.claimRewards(false, false, false);
        vm.stopPrank();
    }

    function bobClaimsToken0AndToken1Rewards() public {
        vm.startPrank(bob);
        staking.claimRewards(true, true, false);
        vm.stopPrank();
    }

    function aliceStakes() public {
        vm.startPrank(alice);
        token0.approve(address(staking), 600 ether);
        deal(TOKEN0_ADDRESS, alice, 600 ether);
        staking.stake(100 ether);
        vm.stopPrank();
    }

    function aliceZeroWithdrawal() public {
        vm.startPrank(alice);
        staking.withdraw(0);
        vm.stopPrank();
    }

    function aliceWithdrawal() public {
        vm.startPrank(alice);
        staking.withdraw(100 ether);
        vm.stopPrank();
    }

    function johnStakes() public {
        vm.startPrank(john);

        token0.approve(address(staking), 1_000 ether);
        token0.approve(staking.owner(), 1_000 ether);

        deal(TOKEN0_ADDRESS, john, 1_000 ether);
        staking.stake(700 ether);

        vm.stopPrank();
    }

    function johnCompoundsRewards() public {
        vm.startPrank(john);
        staking.claimRewards(false, false, true);
        vm.stopPrank();
    }

    function johnWithdrawalMoreThanHave() public {
        vm.startPrank(john);
        staking.withdraw(800 ether);
        vm.stopPrank();
    }

    function johnWithdrawal() public {
        vm.startPrank(john);
        staking.withdraw(700 ether);
        vm.stopPrank();
    }

    function generateFeesFromEarlierWithdrawals() public {
        bobStakes();
        aliceStakes();
        johnStakes();

        vm.warp(block.timestamp + 10 hours);

        bobWithdrawal();
        aliceWithdrawal();
        johnWithdrawal();
    }
}
