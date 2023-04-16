// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Staking.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "forge-std/StdStorage.sol";

contract StakingTest is Test {
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

    event Staked(address indexed account, uint256 amount);
    event StakedWithdrawed(address indexed account, uint256 amount);
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

    // ======== HELPER FUNCTIONS ======== //

    function init() public {
        token0.approve(address(staking), 5_000 ether);
        deal(TOKEN0_ADDRESS, staking.owner(), 2_000 ether);

        token1.approve(address(staking), 5_000 ether);
        deal(TOKEN1_ADDRESS, staking.owner(), 2_000 ether);

        staking.init(1_000 ether, 1_000 ether, 1_000 ether);
    }

    function bobStakes() public {
        vm.startPrank(bob);
        token0.approve(address(staking), 600 ether);
        deal(TOKEN0_ADDRESS, bob, 600 ether);
        staking.stake(500 ether);
        vm.stopPrank();
    }

    function bobWithdraw() public {
        vm.startPrank(bob);
        staking.withdraw(500 ether);
        vm.stopPrank();
    }

    function bobClaimRewardsWithNoOptions() public {
        vm.startPrank(bob);
        staking.claimRewards(false, false, false);
        vm.stopPrank();
    }

    function bobClaimToken0AndToken1Rewards() public {
        vm.startPrank(bob);
        staking.claimRewards(true, true, false);
        vm.stopPrank();
    }

    function bobClaimToken0Rewards() public {
        vm.startPrank(bob);
        staking.claimRewards(true, false, false);
        vm.stopPrank();
    }

    function aliceStakes() public {
        vm.startPrank(alice);
        token0.approve(address(staking), 600 ether);
        deal(TOKEN0_ADDRESS, alice, 600 ether);
        staking.stake(100 ether);
        vm.stopPrank();
    }

    function aliceZeroWithdraw() public {
        vm.startPrank(alice);
        staking.withdraw(0);
        vm.stopPrank();
    }

    function aliceWithdraw() public {
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

    function johnCompoundRewards() public {
        vm.startPrank(john);
        staking.claimRewards(false, false, true);
        vm.stopPrank();
    }

    function johnWithdrawMoreThanHave() public {
        vm.startPrank(john);
        staking.withdraw(800 ether);
        vm.stopPrank();
    }

    function johnWithdraw() public {
        vm.startPrank(john);
        staking.withdraw(700 ether);
        vm.stopPrank();
    }

    function generateFeesFromEarlierWithdrawals() public {
        bobStakes();
        aliceStakes();
        johnStakes();

        vm.warp(block.timestamp + 10 hours);

        bobWithdraw();
        aliceWithdraw();
        johnWithdraw();
    }

    // ======== INIT TESTS ======== //

    function test_SuccessfulyConstructed() public {
        assertEq(staking.TOKEN0(), address(token0));
        assertEq(staking.totalStaked(), 0);
    }

    function test_InitRevertsWhenNotOwner() public {
        vm.prank(bob);
        vm.expectRevert("Ownable: caller is not the owner");
        staking.init(0, 0, 0);
    }

    function test_InitStaking() public {
        init();
        assertTrue(
            staking.END_STAKING_UNIX_TIME() >= block.timestamp + 30 days
        );
        assertEq(staking.totalStaked(), 1_000 ether);
    }

    function test_InitRevertsWhenAlreadyInitialized() public {
        init();
        vm.expectRevert(Staking_Already_Initialized.selector);
        staking.init(0, 0, 0);
    }

    // ======== STAKE TESTS ======== //

    function test_StakeRevertsWhenNotInitialized() public {
        vm.expectRevert(Staking_Not_Initialized.selector);
        staking.stake(0);
    }

    function test_RevertsWhenStakingEnded() public {
        init();
        vm.warp(block.timestamp + 40 days);

        vm.expectRevert(Staking_Period_Ended.selector);
        staking.stake(0);
    }

    function test_RevertsWhenStakingAmountIsZero() public {
        init();

        vm.expectRevert(Staking_Insufficient_Amount_To_Stake.selector);
        staking.stake(0);
    }

    function test_RevertsWhenStakeReachMaxLimit() public {
        init();
        token0.approve(staking.owner(), 200_000_000 ether);
        token0.approve(address(staking), 200_000_000 ether);
        deal(TOKEN0_ADDRESS, staking.owner(), 150_000_000 ether);

        vm.expectRevert(Staking_Max_Limit_Reached.selector);
        staking.stake(120_000_000 ether);
    }

    function test_BobCanStake() public {
        init();

        vm.expectEmit(true, true, true, true);
        emit Staked(bob, 500 ether);

        uint256 totalStakedStart = staking.totalStaked();
        (uint256 startBalance, , , ) = staking.stakingDetails(bob);
        bobStakes();
        (uint256 endBalance, , , ) = staking.stakingDetails(bob);
        uint256 totalStakedEnd = staking.totalStaked();

        assertTrue(endBalance > startBalance);
        assertEq(endBalance, 500 ether);
        assertEq(totalStakedStart + 500 ether, totalStakedEnd);
    }

    // ======== CHECKING REWARDS ======== //

    function test_AliceCannotAccumulateRewards() public {
        init();
        aliceStakes();

        (
            uint256 balance,
            uint256 token0Accumulator,
            uint256 token1Accumulator,

        ) = staking.stakingDetails(alice);

        assertTrue(balance < staking.MIN_STAKED_TO_REWARD());
        assertEq(balance, 100 ether);
        assertEq(token0Accumulator, 0);
        assertEq(token1Accumulator, 0);
    }

    function test_JonhStartsAccumulatingRewards() public {
        init();
        vm.warp(block.timestamp + 2 days);

        johnStakes();

        (
            uint256 balance,
            uint256 token0Accumulator,
            uint256 token1Accumulator,

        ) = staking.stakingDetails(john);

        assertEq(balance, 700 ether);

        assertTrue(balance > staking.MIN_STAKED_TO_REWARD());
        assertTrue(token0Accumulator > 0);
        assertTrue(token1Accumulator > 0);

        vm.warp(block.timestamp + 3 days);

        uint256 token0Rewards = staking.calculateReward(john, YieldType.TOKEN0);
        uint256 token1Rewards = staking.calculateReward(john, YieldType.TOKEN1);
        assertTrue(token0Rewards > 0);
        assertTrue(token1Rewards > 0);
    }

    // ======== CLAIM REWARDS ======== //

    function test_CannotClaimWhenHasOptionsSelected() public {
        init();
        bobStakes();

        vm.expectRevert(Staking_No_Rewards_Options_Selected.selector);
        bobClaimRewardsWithNoOptions();
    }

    function test_BobClaimsZeroRewards() public {
        init();
        bobStakes();

        vm.expectEmit(true, true, true, true);
        emit RewardsClaimed(block.timestamp, bob, 0, 0);
        bobClaimToken0AndToken1Rewards();
    }

    function test_BobClaimsBothRewards() public {
        init();

        vm.warp(block.timestamp + 1 days);
        johnStakes();

        vm.warp(block.timestamp + 1 days);
        bobStakes();

        vm.warp(block.timestamp + 5 days);

        uint256 bobToken0BalanceBefore = token0.balanceOf(bob);
        uint256 bobToken1BalanceBefore = token1.balanceOf(bob);

        uint256 token0RewardsBefore = staking.calculateReward(
            bob,
            YieldType.TOKEN0
        );
        uint256 token1RewardsBefore = staking.calculateReward(
            bob,
            YieldType.TOKEN1
        );

        vm.expectEmit(true, true, true, true);
        emit RewardsClaimed(block.timestamp, bob, token0RewardsBefore, 0);
        emit RewardsClaimed(block.timestamp, bob, 0, token1RewardsBefore);

        bobClaimToken0AndToken1Rewards();

        uint256 bobToken0BalanceAfter = token0.balanceOf(bob);
        uint256 bobToken1BalanceAfter = token1.balanceOf(bob);

        uint256 token0RewardsAfter = staking.calculateReward(
            bob,
            YieldType.TOKEN0
        );
        uint256 token1RewardsAfter = staking.calculateReward(
            bob,
            YieldType.TOKEN1
        );

        assertEq(
            bobToken0BalanceBefore + token0RewardsBefore,
            bobToken0BalanceAfter
        );
        assertEq(token0RewardsAfter, 0);

        assertEq(
            bobToken1BalanceBefore + token1RewardsBefore,
            bobToken1BalanceAfter
        );
        assertEq(token1RewardsAfter, 0);
    }

    function test_BobCanClaimRewardsAfterStakingPeriod() public {
        init();

        vm.warp(block.timestamp + 1 days);
        bobStakes();

        vm.warp(block.timestamp + staking.END_STAKING_UNIX_TIME() + 2 days);

        uint256 bobToken0BalanceBefore = token0.balanceOf(bob);
        uint256 bobToken1BalanceBefore = token1.balanceOf(bob);

        uint256 token0RewardsBefore = staking.calculateReward(
            bob,
            YieldType.TOKEN0
        );
        uint256 token1RewardsBefore = staking.calculateReward(
            bob,
            YieldType.TOKEN1
        );

        vm.expectEmit(true, true, true, true);
        emit RewardsClaimed(block.timestamp, bob, token0RewardsBefore, 0);
        emit RewardsClaimed(block.timestamp, bob, 0, token1RewardsBefore);

        bobClaimToken0AndToken1Rewards();

        uint256 bobToken0BalanceAfter = token0.balanceOf(bob);
        uint256 bobToken1BalanceAfter = token1.balanceOf(bob);

        uint256 token0RewardsAfter = staking.calculateReward(
            bob,
            YieldType.TOKEN0
        );
        uint256 token1RewardsAfter = staking.calculateReward(
            bob,
            YieldType.TOKEN1
        );

        assertEq(
            bobToken0BalanceBefore + token0RewardsBefore,
            bobToken0BalanceAfter
        );
        assertEq(token0RewardsAfter, 0);

        assertEq(
            bobToken1BalanceBefore + token1RewardsBefore,
            bobToken1BalanceAfter
        );
        assertEq(token1RewardsAfter, 0);
    }

    function test_JohnCompoundRewards() public {
        init();

        vm.warp(block.timestamp + 1 days);
        johnStakes();

        vm.warp(block.timestamp + 1 days);
        bobStakes();

        vm.warp(block.timestamp + 5 days);

        uint256 token0RewardsBefore = staking.calculateReward(
            john,
            YieldType.TOKEN0
        );

        (uint256 stakedBalanceBefore, , , ) = staking.stakingDetails(john);

        vm.expectEmit(true, true, true, true);
        emit RewardsCompounded(block.timestamp, john, token0RewardsBefore);

        johnCompoundRewards();

        uint256 token0RewardsAfter = staking.calculateReward(
            john,
            YieldType.TOKEN0
        );

        (uint256 stakedBalanceAfter, , , ) = staking.stakingDetails(john);

        assertEq(stakedBalanceBefore + token0RewardsBefore, stakedBalanceAfter);
        assertEq(token0RewardsAfter, 0);
    }

    // ======== WITHDRAW ======== //

    function test_BobPaysTaxForWithdrawEarlier() public {
        init();
        bobStakes();

        (uint256 balance, , , ) = staking.stakingDetails(bob);
        assertEq(balance, 500 ether);

        uint256 token0BalanceStart = token0.balanceOf(bob);

        vm.warp(block.timestamp + 10 hours);

        bobWithdraw();

        uint256 token0BalanceEnd = token0.balanceOf(bob);

        assertEq(
            token0BalanceStart +
                balance -
                ((balance * staking.WITHDRAW_EARLIER_FEE()) / 100),
            token0BalanceEnd
        );
    }

    function test_RevertsAliceZeroWithdrawTrial() public {
        init();
        aliceStakes();

        vm.expectRevert(Staking_Withdraw_Amount_Cannot_Be_Zero.selector);
        aliceZeroWithdraw();
    }

    function test_AliceWithdrawRevertsWithoutStake() public {
        init();

        vm.expectRevert(Staking_No_Balance_Staked.selector);
        aliceWithdraw();
    }

    function test_JohnWithdrawRevertsWhenExceedsBalance() public {
        init();
        johnStakes();

        vm.expectRevert(Staking_Amount_Exceeds_Balance.selector);
        johnWithdrawMoreThanHave();
    }

    function test_BobCanWithdrawWithoutPayingTax() public {
        init();
        bobStakes();

        uint256 totalStakedStart = staking.totalStaked();
        (uint256 balance, , , ) = staking.stakingDetails(bob);
        assertEq(balance, 500 ether);

        uint256 token0BalanceStart = token0.balanceOf(bob);

        vm.warp(block.timestamp + staking.WITHDRAW_EARLIER_FEE_LOCK_TIME());

        vm.expectEmit(true, true, true, true);
        emit StakedWithdrawed(bob, 500 ether);

        bobWithdraw();

        uint256 token0BalanceEnd = token0.balanceOf(bob);
        uint256 totalStakedEnd = staking.totalStaked();

        assertEq(balance + token0BalanceStart, token0BalanceEnd);
        assertEq(totalStakedStart - 500 ether, totalStakedEnd);
    }

    // ======== COLLECTING FEES ======== //

    function test_EarlierWithdrawalsGeneratesFees() public {
        init();

        uint256 collectedFeesStart = staking.collectedFees();
        generateFeesFromEarlierWithdrawals();
        uint256 collectedFeesEnd = staking.collectedFees();

        assertTrue(collectedFeesEnd > collectedFeesStart);
    }

    function test_BobCannotClaimCollectedFees() public {
        init();

        generateFeesFromEarlierWithdrawals();

        vm.startPrank(bob);
        vm.expectRevert("Ownable: caller is not the owner");
        staking.collectFees();
    }

    function test_ownerCanClaimCollectedFees() public {
        init();

        generateFeesFromEarlierWithdrawals();

        uint256 contractFeesStart = staking.collectedFees();
        uint256 ownerToken0BalanceStart = token0.balanceOf(staking.owner());

        staking.collectFees();

        uint256 contractFeesEnd = staking.collectedFees();
        uint256 ownerToken0BalanceEnd = token0.balanceOf(staking.owner());

        assertTrue(contractFeesStart > 0 && contractFeesEnd == 0);
        assertTrue(ownerToken0BalanceStart == 0 && ownerToken0BalanceEnd > 0);
        assertEq(ownerToken0BalanceEnd, contractFeesStart);
    }

    // ======== EMERGENCY WITHDRAW ======== //

    function test_BobCannotUseEmergencyWithdraw() public {
        vm.startPrank(bob);
        vm.expectRevert("Ownable: caller is not the owner");
        staking.emergencyWithdraw();
        vm.stopPrank();
    }

    function test_OwnerCanUseEmergencyWithdraw() public {
        init();
        bobStakes();
        aliceStakes();

        uint256 contractToken0Balance = token0.balanceOf(address(staking));
        uint256 contractToken1Balance = token1.balanceOf(address(staking));

        uint256 ownerToken0BalanceBefore = token0.balanceOf(staking.owner());
        uint256 ownerToken1BalanceBefore = token1.balanceOf(staking.owner());

        vm.expectEmit(true, true, true, true);
        emit EmergencyWithdrawnFunds(
            contractToken0Balance,
            contractToken1Balance
        );

        staking.emergencyWithdraw();
        uint256 contractToken0BalanceEnd = token0.balanceOf(address(staking));
        uint256 contractToken1BalanceEnd = token1.balanceOf(address(staking));

        uint256 ownerToken0BalanceAfter = token0.balanceOf(staking.owner());
        uint256 ownerToken1BalanceAfter = token1.balanceOf(staking.owner());

        assertTrue(ownerToken0BalanceAfter > ownerToken0BalanceBefore);
        assertEq(contractToken0BalanceEnd, 0);
        assertEq(contractToken1BalanceEnd, 0);
        assertEq(
            ownerToken1BalanceBefore + contractToken1Balance,
            ownerToken1BalanceAfter
        );
        assertEq(staking.totalStaked(), 0);
    }

    // FUZZ TESTS

    function testFuzz_BobStaking(uint256 amount) public {
        init();

        uint256 totalSupply = token0.totalSupply();
        uint256 maxStakeLimit = staking.MAX_ALLOWED_TO_STAKE();
        vm.assume(amount > 0 && amount < totalSupply && amount < maxStakeLimit);

        deal(TOKEN0_ADDRESS, address(bob), amount + 10 ether);

        vm.startPrank(bob);
        token0.approve(address(staking), amount * 10);
        staking.stake(amount);
        vm.stopPrank();

        (uint256 stakedBalance, , , ) = staking.stakingDetails(bob);
        assertEq(stakedBalance, amount);
    }

    // function testFuzz_BobWithdraw(uint256 amount, uint256 timestamp) public {
    //     uint256 minToStake = staking.MIN_STAKED_TO_REWARD();
    //     uint256 maxStakeLimit = staking.MAX_ALLOWED_TO_STAKE();
    //     uint256 withdrawLockTime = staking.WITHDRAW_EARLIER_FEE_LOCK_TIME();
    //     uint256 maxTime = block.timestamp + withdrawLockTime;
    //     uint256 fee = staking.WITHDRAW_EARLIER_FEE();
    //     uint256 totalSupply = token0.totalSupply();
    //     uint256 feeToPay = 0;

    //     init();
    //     vm.assume(
    //         amount > 0 &&
    //             amount < totalSupply &&
    //             amount < maxStakeLimit &&
    //             timestamp <= maxTime
    //     );
    //     // vm.assume(timestamp > block.timestamp && timestamp <= withdrawLockTime);

    //     deal(TOKEN0_ADDRESS, address(bob), amount + 10 ether);

    //     vm.startPrank(bob);

    //     token0.approve(address(staking), amount * 10);
    //     staking.stake(amount);
    //     (uint256 stakedBalance, , , ) = staking.stakingDetails(bob);

    //     assertEq(amount, stakedBalance);

    //     if (timestamp > block.timestamp) {
    //         vm.warp(block.timestamp + timestamp);
    //     } else {
    //         timestamp = block.timestamp;
    //     }

    //     assertTrue(block.timestamp <= timestamp);

    //     uint256 token0BalanceBefore = token0.balanceOf(bob);

    //     assertTrue(token0BalanceBefore > 0);

    //     if (amount <= minToStake && timestamp < withdrawLockTime) {
    //         feeToPay = ((amount * fee) / 100);
    //     }

    //     staking.withdraw(amount);

    //     uint256 token0BalanceAfter = token0.balanceOf(bob);

    //     assertEq(token0BalanceBefore + amount + feeToPay, token0BalanceAfter);

    //     // assert(token0BalanceBefore < token0BalanceAfter);

    //     // assertEq(
    //     //     token0BalanceBefore.add(stakedBalance).sub(feeToPay),
    //     //     token0BalanceAfter
    //     // );

    //     vm.stopPrank();
    // }
}
