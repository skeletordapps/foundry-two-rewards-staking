//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

interface IStaking {
    enum YieldType {
        TOKEN0,
        TOKEN1
    }
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
}
