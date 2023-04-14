// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Staking.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "forge-std/StdStorage.sol";

contract LeviStakingTest is Test {
    // ERC20 public levi;
    // ERC20 public usdc;
    // LeviStaking public leviStaking;
    // string public ARBITRUM_RPC_URL;
    // address public LEVI_CONTRACT_ADDRESS;
    // address public USDC_CONTRACT_ADDRESS;
    // uint256 arbitrumFork;
    // address internal bob;
    // address internal alice;
    // address internal john;
    // event Staked(address account, uint256 amount);
    // event StakedWithdrawed(address account, uint256 amount);
    // function setUp() public {
    //     ARBITRUM_RPC_URL = vm.envString("ARBITRUM_RPC_URL");
    //     LEVI_CONTRACT_ADDRESS = vm.envAddress("LEVI_CONTRACT_ADDRESS");
    //     USDC_CONTRACT_ADDRESS = vm.envAddress("USDC_CONTRACT_ADDRESS");
    //     arbitrumFork = vm.createFork(ARBITRUM_RPC_URL);
    //     vm.selectFork(arbitrumFork);
    //     levi = ERC20(LEVI_CONTRACT_ADDRESS);
    //     usdc = ERC20(USDC_CONTRACT_ADDRESS);
    //     leviStaking = new LeviStaking();
    //     bob = vm.addr(3);
    //     vm.label(bob, "bob");
    //     alice = vm.addr(5);
    //     vm.label(alice, "alice");
    //     john = vm.addr(6);
    //     vm.label(john, "john");
    // }
    // function initializeStaking() public {
    //     levi.approve(address(leviStaking), 1_000_000 ether);
    //     deal(address(levi), address(this), 10_000 ether);
    //     usdc.approve(address(leviStaking), 1_000_000 ether);
    //     deal(address(usdc), address(this), 10_000 ether);
    //     leviStaking.init();
    // }
    // function bobStakes() public {
    //     vm.startPrank(bob);
    //     levi.approve(address(leviStaking), 600 ether);
    //     deal(address(levi), bob, 600 ether);
    //     leviStaking.stake(500 ether);
    //     vm.stopPrank();
    // }
    // function bobUnstakes() public {
    //     vm.startPrank(bob);
    //     leviStaking.withdrawStaked();
    //     vm.stopPrank();
    // }
    // function aliceStakes() public {
    //     vm.startPrank(alice);
    //     levi.approve(address(leviStaking), 600 ether);
    //     deal(address(levi), alice, 600 ether);
    //     leviStaking.stake(500 ether);
    //     vm.stopPrank();
    // }
    // function aliceUnstakes() public {
    //     vm.startPrank(alice);
    //     leviStaking.withdrawStaked();
    //     vm.stopPrank();
    // }
    // function johnStakes() public {
    //     vm.startPrank(alice);
    //     levi.approve(address(leviStaking), 600 ether);
    //     deal(address(levi), john, 100 ether);
    //     leviStaking.stake(100 ether);
    //     vm.stopPrank();
    // }
    // function johnUnstakes() public {
    //     vm.startPrank(john);
    //     leviStaking.withdrawStaked();
    //     vm.stopPrank();
    // }
    // function test_SuccessfulyConstructed() public {
    //     assertEq(leviStaking.LEVI_TOKEN(), address(levi));
    //     assertEq(leviStaking.totalStaked(), 0);
    // }
    // function test_RevertWhenNotInitialized() public {
    //     vm.expectRevert(LeviStaking_Not_Initialized.selector);
    //     leviStaking.stake(1 ether);
    // }
    // function test_RevertWhenAlreadyInitialized() public {
    //     initializeStaking();
    //     vm.expectRevert(LeviStaking_Already_Initialized.selector);
    //     leviStaking.init();
    // }
    // function test_emitEventWhenStake() public {
    //     initializeStaking();
    //     vm.expectEmit(true, true, true, true);
    //     emit Staked(address(this), 1 ether);
    //     leviStaking.stake(1 ether);
    // }
    // function test_BobCanStake() public {
    //     initializeStaking();
    //     (uint256 stakingBalanceBefore, , ) = leviStaking.stakingDetails(
    //         address(bob)
    //     );
    //     bobStakes();
    //     (uint256 stakingBalanceAfter, , ) = leviStaking.stakingDetails(
    //         address(bob)
    //     );
    //     assertTrue(stakingBalanceAfter > stakingBalanceBefore);
    //     assertTrue(stakingBalanceAfter == 500 ether);
    // }
    // function test_TotalStakedIncreasesAfterStaking() public {
    //     initializeStaking();
    //     bobStakes();
    //     aliceStakes();
    //     uint256 totalStaked = leviStaking.totalStaked();
    //     assertEq(totalStaked, 1_000 ether);
    // }
    // function test_RevertWithdrawWhenBobHasNoStaking() public {
    //     initializeStaking();
    //     vm.prank(bob);
    //     vm.expectRevert();
    //     leviStaking.withdrawStaked();
    // }
    // function test_BobCanWithdraw() public {
    //     initializeStaking();
    //     (uint256 bobBalanceStart, , ) = leviStaking.stakingDetails(bob);
    //     bobStakes();
    //     (uint256 bobBalanceAfterStake, , ) = leviStaking.stakingDetails(bob);
    //     vm.expectEmit(true, true, true, true);
    //     emit StakedWithdrawed(bob, bobBalanceAfterStake);
    //     bobUnstakes();
    //     (uint256 bobBalanceAfterWithdraw, , ) = leviStaking.stakingDetails(bob);
    //     assertEq(bobBalanceStart, bobBalanceAfterWithdraw);
    // }
    // function test_TotalStakedTurnsZeroWhenWithdrawEveryStaking() public {
    //     initializeStaking();
    //     bobStakes();
    //     vm.warp(block.timestamp + 10 days);
    //     vm.startPrank(bob);
    //     leviStaking.withdrawStaked();
    //     vm.stopPrank();
    //     assertEq(leviStaking.totalStaked(), 0);
    // }
    // function test_BobClaimRewards() public {
    //     initializeStaking();
    //     bobStakes();
    //     uint256 leviRewardsBefore = leviStaking.calculateReward(
    //         bob,
    //         YieldType.LEVI
    //     );
    //     uint256 usdcRewardsBefore = leviStaking.calculateReward(
    //         bob,
    //         YieldType.USDC
    //     );
    //     vm.warp(block.timestamp + 100);
    //     uint256 leviRewardsAfter = leviStaking.calculateReward(
    //         bob,
    //         YieldType.LEVI
    //     );
    //     uint256 usdcRewardsAfter = leviStaking.calculateReward(
    //         bob,
    //         YieldType.USDC
    //     );
    //     assertEq(leviRewardsBefore, 0);
    //     assertEq(usdcRewardsBefore, 0);
    //     assertTrue(leviRewardsAfter > leviRewardsBefore);
    //     assertTrue(usdcRewardsAfter > usdcRewardsBefore);
    //     vm.startPrank(bob);
    //     leviStaking.claimRewards();
    //     vm.stopPrank();
    //     uint256 zeroLeviRewards = leviStaking.calculateReward(
    //         bob,
    //         YieldType.LEVI
    //     );
    //     uint256 zeroUSDCRewards = leviStaking.calculateReward(
    //         bob,
    //         YieldType.USDC
    //     );
    //     assertEq(zeroLeviRewards, 0);
    //     assertEq(zeroUSDCRewards, 0);
    // }
    // function test_ActorsRestartStakingAfterWithdraw() public {
    //     initializeStaking();
    //     bobStakes();
    //     aliceStakes();
    //     uint256 totalStakedBefore = leviStaking.totalStaked();
    //     assertEq(totalStakedBefore, 1_000 ether);
    //     bobUnstakes();
    //     aliceUnstakes();
    //     uint256 totalStakedAfterWithdraw = leviStaking.totalStaked();
    //     assertEq(totalStakedAfterWithdraw, 0);
    //     leviStaking.stake(100 ether);
    //     bobStakes();
    //     aliceStakes();
    //     uint256 totalStakedAfterReStake = leviStaking.totalStaked();
    //     assertEq(totalStakedAfterReStake, 1_100 ether);
    // }
    // function test_BobCannotUseEmergencyWithdraw() public {
    //     vm.startPrank(bob);
    //     vm.expectRevert("Ownable: caller is not the owner");
    //     leviStaking.emergencyWithdraw();
    //     vm.stopPrank();
    // }
    // function test_OwnerCanUseEmergencyWithdraw() public {
    //     initializeStaking();
    //     bobStakes();
    //     aliceStakes();
    //     uint256 ownerLeviBalanceBefore = IERC20(levi).balanceOf(address(this));
    //     leviStaking.emergencyWithdraw();
    //     uint256 ownerLeviBalanceAfter = IERC20(levi).balanceOf(address(this));
    //     assertTrue(ownerLeviBalanceAfter > ownerLeviBalanceBefore);
    // }
    // function test_CanSendMoreRewardsToContract() public {
    //     uint256 startBalance = levi.balanceOf(address(leviStaking));
    //     deal(address(levi), address(leviStaking), 100 ether);
    //     uint256 endBalance = levi.balanceOf(address(leviStaking));
    //     assertEq(startBalance + 100 ether, endBalance);
    //     vm.warp(block.timestamp + 30 days);
    //     deal(address(levi), address(leviStaking), endBalance + 100 ether);
    //     uint256 newBalance = levi.balanceOf(address(leviStaking));
    //     assertEq(endBalance + 100 ether, newBalance);
    // }
    // function test_CanUpdateRewards() public {
    //     uint256 leviPerDay = 100 ether;
    //     uint256 usdcPerDay = 200 ether;
    //     leviStaking.updateRewardsPerDay(leviPerDay, usdcPerDay);
    //     uint256 leviPerSecond = leviStaking.LEVI_REWARDS_PER_SECOND();
    //     uint256 usdcPerSecond = leviStaking.USDC_REWARDS_PER_SECOND();
    //     assertEq(leviPerSecond, leviPerDay / 86400);
    //     assertEq(usdcPerSecond, usdcPerDay / 86400);
    // }
    // function testFuzz_BobStaking(uint256 amount) public {
    //     initializeStaking();
    //     uint256 totalSupply = levi.totalSupply();
    //     vm.assume(amount < totalSupply);
    //     deal(address(levi), address(bob), amount + 10 ether);
    //     vm.startPrank(bob);
    //     levi.approve(address(leviStaking), amount * 10);
    //     leviStaking.stake(amount);
    //     vm.stopPrank();
    // }
    // function testFuzz_BobWithdrawing(uint256 amount) public {
    //     vm.assume(amount > 0);
    //     initializeStaking();
    //     uint256 totalSupply = levi.totalSupply();
    //     vm.assume(amount < totalSupply);
    //     deal(address(levi), address(bob), amount);
    //     uint256 totalStakedBefore = leviStaking.totalStaked();
    //     vm.startPrank(bob);
    //     levi.approve(address(leviStaking), amount * 10);
    //     leviStaking.stake(amount);
    //     uint256 totalStakedAfter = leviStaking.totalStaked();
    //     vm.warp(block.timestamp + 10 days);
    //     leviStaking.withdrawStaked();
    //     uint256 totalStakedEnd = leviStaking.totalStaked();
    //     assertEq(totalStakedAfter, amount);
    //     assertEq(totalStakedBefore, totalStakedEnd);
    //     vm.stopPrank();
    // }
}
