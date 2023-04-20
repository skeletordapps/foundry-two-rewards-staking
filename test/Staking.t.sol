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

    /*//////////////////////////////////////////////////////////////////////////
                                    INIT TESTS
    //////////////////////////////////////////////////////////////////////////*/

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
        vm.expectEmit(true, true, true, true);
        emit RewardsAdded(token0RewardsToInit, token1RewardsToInit);

        init();

        assertTrue(staking.END_STAKING_UNIX_TIME() >= 30 days);
        assertEq(staking.totalStaked(), 1_000 ether);
    }

    function test_InitRevertsWhenAlreadyInitialized() public {
        init();
        vm.expectRevert(Staking_Already_Initialized.selector);
        staking.init(0, 0, 0);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    STAKE TESTS
    //////////////////////////////////////////////////////////////////////////*/

    function test_StakeRevertsWhenNotInitialized() public {
        vm.expectRevert(Staking_Not_Initialized.selector);
        staking.stake(0);
    }

    function test_RevertsWhenStakingEnded() public {
        init();
        vm.warp(block.timestamp + staking.END_STAKING_UNIX_TIME() + 40 days);

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
        (uint256 startBalance, , , , , ) = staking.stakingDetails(bob);
        bobStakes();
        (uint256 endBalance, , , , , ) = staking.stakingDetails(bob);
        uint256 totalStakedEnd = staking.totalStaked();

        assertTrue(endBalance > startBalance);
        assertEq(endBalance, 500 ether);
        assertEq(totalStakedStart + 500 ether, totalStakedEnd);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            CHECKING REWARDS TESTS
    //////////////////////////////////////////////////////////////////////////*/

    function test_AliceCannotAccumulateRewards() public {
        init();
        aliceStakes();

        (
            uint256 balance,
            uint256 token0Accumulator,
            uint256 token1Accumulator,
            ,
            ,

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
            ,
            ,

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

    /*//////////////////////////////////////////////////////////////////////////
                                CLAIM REWARDS TESTS
    //////////////////////////////////////////////////////////////////////////*/

    function test_CannotClaimWhenHasOptionsSelected() public {
        init();
        bobStakes();

        vm.expectRevert(Staking_No_Rewards_Options_Selected.selector);
        bobClaimsRewardsWithNoOptions();
    }

    function test_BobClaimsZeroRewards() public {
        init();
        bobStakes();

        vm.expectEmit(true, true, true, true);
        emit RewardsClaimed(block.timestamp, bob, 0, 0);
        bobClaimsToken0AndToken1Rewards();
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

        bobClaimsToken0AndToken1Rewards();

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

        bobClaimsToken0AndToken1Rewards();

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

    function test_JohnCompoundsRewards() public {
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

        (uint256 stakedBalanceBefore, , , , , ) = staking.stakingDetails(john);

        vm.expectEmit(true, true, true, true);
        emit RewardsCompounded(block.timestamp, john, token0RewardsBefore);

        johnCompoundsRewards();

        uint256 token0RewardsAfter = staking.calculateReward(
            john,
            YieldType.TOKEN0
        );

        (uint256 stakedBalanceAfter, , , , , ) = staking.stakingDetails(john);

        assertEq(stakedBalanceBefore + token0RewardsBefore, stakedBalanceAfter);
        assertEq(token0RewardsAfter, 0);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                WITHDRAW TESTS
    //////////////////////////////////////////////////////////////////////////*/

    function test_BobPaysTaxForWithdrawEarlier() public {
        init();
        bobStakes();

        (uint256 balance, , , , , ) = staking.stakingDetails(bob);
        assertEq(balance, 500 ether);

        uint256 token0BalanceStart = token0.balanceOf(bob);

        vm.warp(block.timestamp + 10 hours);

        bobWithdrawal();

        uint256 token0BalanceEnd = token0.balanceOf(bob);

        assertEq(
            token0BalanceStart +
                balance -
                ((balance * staking.WITHDRAW_EARLIER_FEE()) / 100),
            token0BalanceEnd
        );
    }

    function test_RevertsAliceZeroWithdrawalTrial() public {
        init();
        aliceStakes();

        vm.expectRevert(Staking_Withdraw_Amount_Cannot_Be_Zero.selector);
        aliceZeroWithdrawal();
    }

    function test_AliceWithdrawalRevertsWithoutStake() public {
        init();

        vm.expectRevert(Staking_No_Balance_Staked.selector);
        aliceWithdrawal();
    }

    function test_JohnWithdrawRevertsWhenExceedsBalance() public {
        init();
        johnStakes();

        vm.expectRevert(Staking_Amount_Exceeds_Balance.selector);
        johnWithdrawalMoreThanHave();
    }

    function test_BobCanWithdrawWithoutPayingTax() public {
        init();
        bobStakes();

        uint256 totalStakedStart = staking.totalStaked();
        (uint256 balance, , , , , ) = staking.stakingDetails(bob);
        assertEq(balance, 500 ether);

        uint256 token0BalanceStart = token0.balanceOf(bob);

        vm.warp(block.timestamp + staking.WITHDRAW_EARLIER_FEE_LOCK_TIME());

        vm.expectEmit(true, true, true, true);
        emit StakeWithdrawn(bob, 500 ether);

        bobWithdrawal();

        uint256 token0BalanceEnd = token0.balanceOf(bob);
        uint256 totalStakedEnd = staking.totalStaked();

        assertEq(balance + token0BalanceStart, token0BalanceEnd);
        assertEq(totalStakedStart - 500 ether, totalStakedEnd);
    }

    function testJohnCanWithdrawAfterStakingPeriod() public {
        init();
        johnStakes();

        vm.warp(block.timestamp + staking.END_STAKING_UNIX_TIME() + 2 days);

        uint256 token0BalanceBefore = token0.balanceOf(john);
        (uint256 stakedBefore, , , , , ) = staking.stakingDetails(john);

        johnWithdrawal();

        uint256 token0BalanceAfter = token0.balanceOf(john);
        (uint256 stakedAfter, , , , , ) = staking.stakingDetails(john);

        assertEq(token0BalanceBefore + stakedBefore, token0BalanceAfter);
        assertEq(stakedAfter, 0);
    }

    /*//////////////////////////////////////////////////////////////////////////
                        CLAIM REWARDS AFTER WITHDRAWAL TESTS
    //////////////////////////////////////////////////////////////////////////*/

    function testBobClaimRewardsAfterWithdrawal() public {
        init();

        vm.warp(block.timestamp + 10 days);

        bobStakes();

        vm.warp(block.timestamp + 10 days);

        uint256 token0Rewards = staking.calculateReward(bob, YieldType.TOKEN0);
        uint256 token1Rewards = staking.calculateReward(bob, YieldType.TOKEN1);

        bobWithdrawal();

        uint256 token0RewardsAfter = staking.calculateReward(
            bob,
            YieldType.TOKEN0
        );

        uint256 token1RewardsAfter = staking.calculateReward(
            bob,
            YieldType.TOKEN1
        );

        assertEq(token0Rewards, token0RewardsAfter);
        assertEq(token1Rewards, token1RewardsAfter);

        uint256 token0Balance = token0.balanceOf(bob);
        uint256 token1Balance = token1.balanceOf(bob);

        bobClaimsToken0AndToken1Rewards();

        uint256 token0BalanceAfter = token0.balanceOf(bob);
        uint256 token1BalanceAfter = token1.balanceOf(bob);

        assertEq(token0Balance + token0RewardsAfter, token0BalanceAfter);
        assertEq(token1Balance + token1RewardsAfter, token1BalanceAfter);
    }

    function testJohnCompoundRewardsAfterWithdrawal() public {
        init();
        vm.warp(block.timestamp + 10 days);
        johnStakes();

        vm.warp(block.timestamp + 100 days);

        uint256 token0Rewards = staking.calculateReward(john, YieldType.TOKEN0);

        johnWithdrawal();

        uint256 token0RewardsAfter = staking.calculateReward(
            john,
            YieldType.TOKEN0
        );

        assertEq(token0Rewards, token0RewardsAfter);

        (uint256 stakingBalance, , , , , ) = staking.stakingDetails(john);

        johnCompoundsRewards();

        (uint256 stakingBalanceAfter, , , , , ) = staking.stakingDetails(john);

        assertEq(stakingBalance + token0RewardsAfter, stakingBalanceAfter);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                COLLECTING FEES TESTS
    //////////////////////////////////////////////////////////////////////////*/

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

        vm.expectEmit(true, true, true, true);
        emit FeesWithdrawn(contractFeesStart);

        staking.collectFees();

        uint256 contractFeesEnd = staking.collectedFees();
        uint256 ownerToken0BalanceEnd = token0.balanceOf(staking.owner());

        assertTrue(contractFeesStart > 0 && contractFeesEnd == 0);
        assertTrue(ownerToken0BalanceStart == 0 && ownerToken0BalanceEnd > 0);
        assertEq(ownerToken0BalanceEnd, contractFeesStart);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            EMERGENCY WITHDRAW TESTS
    //////////////////////////////////////////////////////////////////////////*/

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

    /*//////////////////////////////////////////////////////////////////////////
                                    ADD REWARDS TESTS
    //////////////////////////////////////////////////////////////////////////*/

    function test_addRewards() public {
        uint256 token0Amount = 100 ether;
        uint256 token1Amount = 200 ether;

        // Approve the contract to spend the required amount of tokens
        IERC20(TOKEN0_ADDRESS).approve(address(this), token0Amount);
        IERC20(TOKEN1_ADDRESS).approve(address(this), token1Amount);
        IERC20(TOKEN0_ADDRESS).approve(address(staking), token0Amount);
        IERC20(TOKEN1_ADDRESS).approve(address(staking), token1Amount);

        deal(TOKEN0_ADDRESS, address(this), token0Amount);
        deal(TOKEN1_ADDRESS, address(this), token1Amount);
        deal(TOKEN0_ADDRESS, address(staking), token0Amount);
        deal(TOKEN1_ADDRESS, address(staking), token1Amount);

        uint256 token0Balance = token0.balanceOf(address(staking));
        uint256 token1Balance = token1.balanceOf(address(staking));

        // Call the `addRewards` function
        staking.addRewards(token0Amount, token1Amount);

        uint256 token0BalanceAfter = token0.balanceOf(address(staking));
        uint256 token1BalanceAfter = token1.balanceOf(address(staking));

        // Verify that the rewards have been added
        assert(token0Balance + token0Amount == token0BalanceAfter);
        assert(token1Balance + token1Amount == token1BalanceAfter);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    FUZZ TESTS
    //////////////////////////////////////////////////////////////////////////*/

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

        (uint256 stakedBalance, , , , , ) = staking.stakingDetails(bob);
        assertEq(stakedBalance, amount);
    }

    function testFuzz_BobWithdrawal(uint256 amount, uint256 timestamp) public {
        init();
        vm.assume(
            amount > 0 &&
                amount < token0.totalSupply() &&
                amount < staking.MAX_ALLOWED_TO_STAKE() &&
                timestamp <=
                staking.WITHDRAW_EARLIER_FEE_LOCK_TIME() + block.timestamp
        );

        deal(TOKEN0_ADDRESS, address(bob), amount + 10 ether);

        vm.startPrank(bob);
        token0.approve(address(staking), amount * 10);
        staking.stake(amount);
        vm.stopPrank();

        (uint256 stakedBalance, , , , , ) = staking.stakingDetails(bob);

        assertEq(amount, stakedBalance);

        if (timestamp > block.timestamp) {
            vm.warp(block.timestamp + timestamp);
        } else {
            timestamp = block.timestamp;
        }

        assertTrue(block.timestamp <= timestamp);

        uint256 token0BalanceBefore = token0.balanceOf(bob);

        vm.startPrank(bob);

        staking.withdraw(amount);

        (uint256 stakedBalanceAfter, , , , , ) = staking.stakingDetails(bob);

        vm.stopPrank();

        uint256 token0BalanceAfter = token0.balanceOf(bob);

        assertTrue(token0BalanceBefore < token0BalanceAfter);
        assertEq(stakedBalanceAfter, stakedBalance - amount);

        vm.stopPrank();
    }
}
