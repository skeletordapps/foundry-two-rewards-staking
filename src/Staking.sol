//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "forge-std/console.sol";
import "./Settings.sol";

error Staking_Not_Initialized();
error Staking_Already_Initialized();
error Staking_Period_Ended();
error Staking_Max_Limit_Reached();
error Staking_No_Rewards_Available();
error Staking_No_Balance_Staked();
error Staking_Amount_Exceeds_Balance();
error Staking_Withdraw_Amount_Cannot_Be_Zero();
error Staking_Apply_Not_Available_Yet();
error Staking_No_Rewards_Options_Selected();
error Staking_Insufficient_Amount_To_Stake();

enum YieldType {
    TOKEN0,
    TOKEN1
}

/**
 * @title Staking contract
 * @author 0xTheL
 * @notice Contract for staking tokens and earning rewards
 * @dev This contract allows users to stake tokens and earn rewards over a period of time.
 *      The contract owner can set the reward rate and duration of the staking period.
 */
contract Staking is Ownable, Settings {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Variables and data structures

    struct UserInfo {
        uint256 stakingBalance;
        uint256 token0Accumulator;
        uint256 token1Accumulator;
        uint256 lastActionTimestamp;
    }

    address public TOKEN0;
    address public TOKEN1;

    uint256 public token0Accumulator;
    uint256 public token1Accumulator;

    uint256 public lastUpdate;
    uint256 public totalStaked;
    uint256 public collectedFees;

    mapping(address => UserInfo) public stakingDetails;

    // Events

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

    /**
     * @dev Modifier that checks if the staking period is ongoing, the user is staking a non-zero amount of tokens,
     * and the total amount staked by all users does not exceed a maximum limit.
     * Calls the `canStake` function to perform the actual checks.
     * @param amount The amount of tokens the user wants to stake.
     **/
    modifier onlyIfCanStake(uint256 amount) {
        canStake(amount);
        _;
    }

    constructor(address _token0, address _token1) {
        TOKEN0 = _token0;
        TOKEN1 = _token1;
    }

    /**
     * @dev Initializes the staking contract with the required parameters.
     *      This function can only be called by the contract owner.
     *      If the contract has already been initialized, this function will revert.
     *
     * @notice This function transfers 1,000 of TOKEN0 and TOKEN1 to the staking contract.
     *         The staking period will end 30 days after the function is called.
     */
    function init(
        uint256 initialDeposit,
        uint256 rewardsToken0,
        uint256 rewardsToken1
    ) external onlyOwner {
        if (END_STAKING_UNIX_TIME > 0) revert Staking_Already_Initialized();

        END_STAKING_UNIX_TIME = block.timestamp + 30 days;
        IERC20(TOKEN0).safeTransferFrom(
            msg.sender,
            address(this),
            rewardsToken0
        );
        IERC20(TOKEN1).safeTransferFrom(
            msg.sender,
            address(this),
            rewardsToken1
        );

        stake(initialDeposit);
    }

    /**
     * @dev Check if the staking period is ongoing, the user is staking a non-zero amount of tokens,
     * and the total amount staked by all users does not exceed a maximum limit.
     * @param amount The amount of tokens the user wants to stake.
     * reverts with Staking_Not_Initialized if the staking period has not been initialized.
     * reverts with Staking_Period_Ended if the staking period has ended.
     * reverts with Staking_Insufficient_Amount_To_Stake if the user is staking a zero amount of tokens.
     * reverts with Staking_Max_Limit_Reached if the total amount staked by all users would exceed the maximum limit
     * after the current `amount` being staked is added.
     */
    function canStake(uint256 amount) private view returns (bool) {
        if (END_STAKING_UNIX_TIME == 0) revert Staking_Not_Initialized();

        if (block.timestamp > END_STAKING_UNIX_TIME) {
            revert Staking_Period_Ended();
        }

        if (amount == 0) revert Staking_Insufficient_Amount_To_Stake();

        if (totalStaked + amount > MAX_ALLOWED_TO_STAKE)
            revert Staking_Max_Limit_Reached();

        return true;
    }

    /**
     * @dev Stake a certain amount of tokens into the staking contract.
     *
     * Requirements:
     * - Staking must have been initialized.
     * - The staking period must not have ended.
     * - The amount being staked must not exceed the maximum allowed.
     *
     * Effects:
     * - Updates the staking details of the user, including their staked balance and last staking timestamp.
     * - If the user's staking balance is greater than or equal to the minimum required to receive rewards,
     *   their token0Accumulator and token1Accumulator are updated.
     * - Updates the total staked balance.
     * - Transfers the staked tokens from the user to the staking contract.
     * - Emits a `Staked` event.
     *
     * @param amount The amount of tokens to stake.
     */
    function stake(uint256 amount) public onlyIfCanStake(amount) {
        UserInfo storage userInfo = stakingDetails[msg.sender];
        userInfo.stakingBalance += amount;

        updateAccumulators(userInfo, YieldType.TOKEN0);
        updateAccumulators(userInfo, YieldType.TOKEN1);

        totalStaked += amount;
        lastUpdate = block.timestamp;

        IERC20(TOKEN0).safeTransferFrom(msg.sender, address(this), amount);

        emit Staked(msg.sender, amount);
    }

    /**
     * @dev Withdraws the specified amount of tokens from the staking contract.
     * @param amount The amount of tokens to withdraw.
     * @notice A withdrawal fee may apply if the tokens are withdrawn before the WITHDRAW_EARLIER_FEE_LOCK_TIME has passed.
     * @notice If the amount to withdraw exceeds the available balance, the function will revert.
     * @notice If the amount to withdraw is zero, the function will revert.
     * @notice Emits a StakedWithdrawed event on successful withdrawal.
     */
    function withdraw(uint256 amount) external {
        if (amount == 0) revert Staking_Withdraw_Amount_Cannot_Be_Zero();

        UserInfo storage userInfo = stakingDetails[msg.sender];
        uint256 balance = userInfo.stakingBalance;

        if (balance == 0) revert Staking_No_Balance_Staked();
        if (amount > balance) revert Staking_Amount_Exceeds_Balance();

        uint256 fee = 0;

        if (
            block.timestamp <
            userInfo.lastActionTimestamp + WITHDRAW_EARLIER_FEE_LOCK_TIME
        ) {
            fee = amount.mul(WITHDRAW_EARLIER_FEE).div(100);
        }

        userInfo.stakingBalance -= amount;

        updateAccumulators(userInfo, YieldType.TOKEN0);
        updateAccumulators(userInfo, YieldType.TOKEN1);

        totalStaked -= amount;
        collectedFees += fee;
        lastUpdate = block.timestamp;

        IERC20(TOKEN0).safeTransfer(msg.sender, amount.sub(fee));

        emit StakedWithdrawed(msg.sender, amount);
    }

    /**
     * @dev Allows the user to claim and/or compound their staked rewards.
     *
     * @param claimToken0 A boolean indicating whether to claim rewards in Token0.
     * @param claimToken1 A boolean indicating whether to claim rewards in Token1.
     * @param compoundToken0 A boolean indicating whether to compound rewards in Token0.
     *
     * Requirements:
     * - At least one reward option (claim or compound) must be selected.
     * - The staker must have rewards based on previous staked tokens in the contract.
     */
    function claimRewards(
        bool claimToken0,
        bool claimToken1,
        bool compoundToken0
    ) external {
        if (!claimToken0 && !claimToken1 && !compoundToken0)
            revert Staking_No_Rewards_Options_Selected();

        UserInfo storage userInfo = stakingDetails[msg.sender];

        if (claimToken0 && !compoundToken0) claimToken0Rewards(userInfo);
        if (claimToken1) claimToken1Rewards(userInfo);
        if (compoundToken0) compoundToken0Rewards(userInfo);

        lastUpdate = block.timestamp;
    }

    /**
     * @dev Internal function to claim accumulated TOKEN0 rewards for the user and transfer them to the user's address.
     * @param userInfo The UserInfo struct that contains the user's staking details.
     * Emits a RewardsClaimed event.
     * Reverts if no rewards are available to claim.
     */
    function claimToken0Rewards(UserInfo storage userInfo) internal {
        uint256 userToken0Rewards = calculateReward(
            msg.sender,
            YieldType.TOKEN0
        );

        if (userToken0Rewards > 0) {
            updateAccumulators(userInfo, YieldType.TOKEN0);

            IERC20(TOKEN0).safeTransfer(msg.sender, userToken0Rewards);
        }

        emit RewardsClaimed(block.timestamp, msg.sender, userToken0Rewards, 0);
    }

    /**
     * @dev Internal function to claim accumulated TOKEN1 rewards for the user and transfer them to the user's address.
     * @param userInfo The UserInfo struct that contains the user's staking details.
     * Emits a RewardsClaimed event.
     * Reverts if no rewards are available to claim.
     */
    function claimToken1Rewards(UserInfo storage userInfo) internal {
        uint256 userToken1Rewards = calculateReward(
            msg.sender,
            YieldType.TOKEN1
        );

        if (userToken1Rewards > 0) {
            updateAccumulators(userInfo, YieldType.TOKEN1);

            IERC20(TOKEN1).safeTransfer(msg.sender, userToken1Rewards);
        }

        emit RewardsClaimed(block.timestamp, msg.sender, 0, userToken1Rewards);
    }

    /**
     * @dev Internal function to compound the rewards for Token0.
     * The function mutates state.
     * @param userInfo The user's staking details.
     * Emits a `RewardsCompounded` event.
     * Reverts if there are no rewards available to claim.
     */
    function compoundToken0Rewards(UserInfo storage userInfo) internal {
        uint256 userToken0Rewards = calculateReward(
            msg.sender,
            YieldType.TOKEN0
        );

        if (canStake(userToken0Rewards)) {
            userInfo.stakingBalance += userToken0Rewards;

            updateAccumulators(userInfo, YieldType.TOKEN0);
        }

        emit RewardsCompounded(block.timestamp, msg.sender, userToken0Rewards);
    }

    /**
     * @dev Updates the user's yield accumulators based on the current timestamp and staking details.
     * @param userInfo The struct containing the user's staking details.
     * @param yieldType The type of yield being updated (TOKEN0 or TOKEN1).
     */
    function updateAccumulators(
        UserInfo storage userInfo,
        YieldType yieldType
    ) internal {
        uint256 accumulator = 0;

        if (
            userInfo.stakingBalance >= MIN_STAKED_TO_REWARD &&
            block.timestamp <= END_STAKING_UNIX_TIME
        ) {
            accumulator = getNewAccumulator(yieldType);

            if (yieldType == YieldType.TOKEN0) {
                token0Accumulator = accumulator;
            } else {
                token1Accumulator = accumulator;
            }
        }

        if (yieldType == YieldType.TOKEN0) {
            userInfo.token0Accumulator = accumulator;
        } else {
            userInfo.token1Accumulator = accumulator;
        }

        userInfo.lastActionTimestamp = block.timestamp;
    }

    /**
     * @dev Calculates a new accumulator value based on the total staked amount, the elapsed time
     * since the last update, and the reward rate per second for the specified yield type.
     * If the total staked amount is below the minimum staked required to receive rewards,
     * or if the staking period has already ended, returns 0.
     * @param yieldType The type of yield for which to calculate the new accumulator value.
     * @return The new accumulator value for the specified yield type.
     */
    function getNewAccumulator(
        YieldType yieldType
    ) private view returns (uint256) {
        if (totalStaked == 0 || totalStaked < MIN_STAKED_TO_REWARD) return 0;

        uint256 timestamp = block.timestamp <= END_STAKING_UNIX_TIME
            ? block.timestamp
            : END_STAKING_UNIX_TIME;

        uint256 numerator = yieldType == YieldType.TOKEN0
            ? TOKEN0_REWARDS_PER_SECOND * (timestamp - lastUpdate) * 1e24
            : TOKEN1_REWARDS_PER_SECOND * (timestamp - lastUpdate) * 1e6;

        uint256 tokensPerStaked = numerator.div(totalStaked);

        uint256 accumulator = yieldType == YieldType.TOKEN0 // CHECKED
            ? token0Accumulator
            : token1Accumulator;

        return accumulator + tokensPerStaked;
    }

    /**
     * @dev Calculates the amount of reward tokens earned by an account.
     * @param account The address of the account to calculate rewards for.
     * @param yieldType The type of yield to calculate rewards for (Token0 or Token1).
     * @return The amount of reward tokens earned by the account.
     */
    function calculateReward(
        address account,
        YieldType yieldType
    ) public view returns (uint256) {
        UserInfo memory userInfo = stakingDetails[account];

        uint256 acc = getNewAccumulator(yieldType);
        uint256 userAcc = yieldType == YieldType.TOKEN0
            ? userInfo.token0Accumulator
            : userInfo.token1Accumulator;

        return ((userInfo.stakingBalance * (acc - userAcc)) /
            (yieldType == YieldType.TOKEN0 ? 1e24 : 1e6));
    }

    /**
     * @dev Allows the contract owner to collect the accumulated fees.
     * Transfers the collected fees in TOKEN0 to the contract owner's address.
     */
    function collectFees() external onlyOwner {
        uint256 fees = collectedFees;
        collectedFees = 0;

        IERC20(TOKEN0).safeTransfer(owner(), fees);
    }

    /**
     * @notice This function needs to be used with caution in an extremely bad scenario.
     * @dev Allows the contract owner to withdraw all the staked tokens in an emergency situation.
     * The function will transfer all the staked tokens held by the contract to the owner's address.
     * This function should only be used in emergency situations and can lead to a loss of rewards for stakers.
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 token0Balance = IERC20(TOKEN0).balanceOf(address(this));
        uint256 token1Balance = IERC20(TOKEN1).balanceOf(address(this));

        totalStaked = 0;
        IERC20(TOKEN0).safeTransfer(msg.sender, token0Balance);
        IERC20(TOKEN1).safeTransfer(msg.sender, token1Balance);

        emit EmergencyWithdrawnFunds(token0Balance, token1Balance);
    }
}
