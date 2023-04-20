//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

error Settings_Apply_Not_Available_Yet();
error Settings_Range_Not_Allowed();

contract Settings is Ownable {
    uint256 public constant MAX_ALLOWED_TO_STAKE = 100_000_000 ether;

    /// THE LOCK TIME TO UPDATES ANY CONFIG
    uint256 public constant SETTINGS_MIN_LOCK_TIME = 0 hours;
    uint256 public constant SETTINGS_MAX_LOCK_TIME = 24 hours;
    uint256 public SETTINGS_LOCK_TIME = 1 hours;
    uint256 public NEW_SETTINGS_LOCK_TIME = 0 hours;

    /// A LOCK TIME TO CHARGE USERS THAT TRY TO WITHDRAW EARLIER THAN THE SPECIFIED LOCK TIME
    uint256 public constant WITHDRAW_EARLIER_FEE_MIN_LOCK_TIME = 24 hours;
    uint256 public constant WITHDRAW_EARLIER_FEE_MAX_LOCK_TIME = 48 hours;
    uint256 public WITHDRAW_EARLIER_FEE_LOCK_TIME = 24 hours;
    uint256 public NEW_WITHDRAW_EARLIER_FEE_LOCK_TIME = 24 hours;

    /// FEE FOR WITHDRAWING EARLIER THAN THE SPECIFIED LOCK TIME
    uint256 public constant WITHDRAW_EARLIER_MIN_FEE = 0; // 0%
    uint256 public constant WITHDRAW_EARLIER_MAX_FEE = 5; // 5%
    uint256 public WITHDRAW_EARLIER_FEE = 5; // 5%
    uint256 public NEW_WITHDRAW_EARLIER_FEE = 5; // 5%

    /// MIN VALUE STAKED TO START BEING REWARDED
    uint256 public MIN_STAKED_TO_REWARD = 500 ether;
    uint256 public NEW_MIN_STAKED_TO_REWARD = 500 ether;

    /// WHEN STAKING PERIOD ENDS
    uint256 public END_STAKING_UNIX_TIME;
    uint256 public NEW_END_STAKING_UNIX_TIME;

    /// TOKEN 0 REWARDS PER SECOND AVAILABLE
    uint256 public TOKEN0_REWARDS_PER_SECOND;
    uint256 public NEW_TOKEN0_REWARDS_PER_SECOND;

    /// TOKEN 1 REWARDS PER SECOND AVAILABLE
    uint256 public TOKEN1_REWARDS_PER_SECOND;
    uint256 public NEW_TOKEN1_REWARDS_PER_SECOND;

    uint256 public lastSettingsUpdate;

    event Settings_Updated();

    constructor() {
        uint256 token0PerDay = 2 ether;
        uint256 token1PerDay = 5 ether;
        TOKEN0_REWARDS_PER_SECOND = token0PerDay / 86400;
        TOKEN1_REWARDS_PER_SECOND = token1PerDay / 86400;
    }

    /// Store new tokens params and lastSettingsUpdate
    function updateRewardsPerDay(
        uint256 token0PerDay,
        uint256 token1PerDay
    ) external onlyOwner {
        NEW_TOKEN0_REWARDS_PER_SECOND = token0PerDay / 86400;
        NEW_TOKEN1_REWARDS_PER_SECOND = token1PerDay / 86400;
        lastSettingsUpdate = block.timestamp;
    }

    /// Apply previous updates if 24 hours already passed
    function applyRewardsUpdate() external onlyOwner {
        if (block.timestamp < lastSettingsUpdate + SETTINGS_LOCK_TIME)
            revert Settings_Apply_Not_Available_Yet();

        TOKEN0_REWARDS_PER_SECOND = NEW_TOKEN0_REWARDS_PER_SECOND;
        TOKEN1_REWARDS_PER_SECOND = NEW_TOKEN1_REWARDS_PER_SECOND;
        delete lastSettingsUpdate;
        delete NEW_TOKEN0_REWARDS_PER_SECOND;
        delete NEW_TOKEN1_REWARDS_PER_SECOND;

        emit Settings_Updated();
    }

    /// UPDATES THE SETTINGS LOCK TIME
    function updateSettingsLockTime(uint256 time) external onlyOwner {
        if (time < SETTINGS_MIN_LOCK_TIME || time > SETTINGS_MAX_LOCK_TIME)
            revert Settings_Range_Not_Allowed();

        NEW_SETTINGS_LOCK_TIME = time;
        lastSettingsUpdate = block.timestamp;
    }

    /// APPLIES THE NEW SETTINGS LOCK TIME
    function applySettingsLockTimeUpdate() external onlyOwner {
        if (block.timestamp < lastSettingsUpdate + SETTINGS_LOCK_TIME)
            revert Settings_Apply_Not_Available_Yet();

        SETTINGS_LOCK_TIME = NEW_SETTINGS_LOCK_TIME;
        delete NEW_SETTINGS_LOCK_TIME;

        emit Settings_Updated();
    }

    /// UPDATES THE EARLIER WITHDRAW LOCK TIME
    function updateWithdrawEarlierFeeLockTime(uint256 time) external onlyOwner {
        if (
            time < WITHDRAW_EARLIER_FEE_MIN_LOCK_TIME ||
            time > WITHDRAW_EARLIER_FEE_MAX_LOCK_TIME
        ) revert Settings_Range_Not_Allowed();

        NEW_WITHDRAW_EARLIER_FEE_LOCK_TIME = time;
        lastSettingsUpdate = block.timestamp;
    }

    /// APPLIES THE NEW EARLIER WITHDRAW LOCK TIME
    function applyWithdrawEarlierFeeLockTimeUpdate() external onlyOwner {
        if (block.timestamp < lastSettingsUpdate + SETTINGS_LOCK_TIME)
            revert Settings_Apply_Not_Available_Yet();

        WITHDRAW_EARLIER_FEE_LOCK_TIME = NEW_WITHDRAW_EARLIER_FEE_LOCK_TIME;
        delete NEW_WITHDRAW_EARLIER_FEE_LOCK_TIME;

        emit Settings_Updated();
    }

    function updateWithdrawEarlierFee(uint256 fee) external onlyOwner {
        if (fee < WITHDRAW_EARLIER_MIN_FEE || fee > WITHDRAW_EARLIER_MAX_FEE)
            revert Settings_Range_Not_Allowed();

        NEW_WITHDRAW_EARLIER_FEE = fee;
        lastSettingsUpdate = block.timestamp;
    }

    function applyWithdrawEarlierFeeUpdate() external onlyOwner {
        if (block.timestamp < lastSettingsUpdate + SETTINGS_LOCK_TIME)
            revert Settings_Apply_Not_Available_Yet();

        WITHDRAW_EARLIER_FEE = NEW_WITHDRAW_EARLIER_FEE;
        delete NEW_WITHDRAW_EARLIER_FEE;

        emit Settings_Updated();
    }

    function updateMinStakedToReward(uint256 minStaked) external onlyOwner {
        NEW_MIN_STAKED_TO_REWARD = minStaked;
        lastSettingsUpdate = block.timestamp;
    }

    function applyMinStakedToRewardUpdate() external onlyOwner {
        if (block.timestamp < lastSettingsUpdate + SETTINGS_LOCK_TIME)
            revert Settings_Apply_Not_Available_Yet();

        MIN_STAKED_TO_REWARD = NEW_MIN_STAKED_TO_REWARD;
        delete NEW_MIN_STAKED_TO_REWARD;

        emit Settings_Updated();
    }

    function updateStakingPeriod(uint256 period) external onlyOwner {
        NEW_END_STAKING_UNIX_TIME = block.timestamp + period;
        lastSettingsUpdate = block.timestamp;
    }

    function applyStakingPeriodUpdate() external onlyOwner {
        if (block.timestamp < lastSettingsUpdate + SETTINGS_LOCK_TIME)
            revert Settings_Apply_Not_Available_Yet();

        END_STAKING_UNIX_TIME = NEW_END_STAKING_UNIX_TIME;
        delete NEW_END_STAKING_UNIX_TIME;
    }
}
