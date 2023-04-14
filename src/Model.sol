//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OPPStaking is Ownable {

    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 stakingBalance;
        uint256 userAccumulator;
    }

    address public constant OPTIMISM_PRIME_TOKEN = 0x676f784d19c7F1Ac6C6BeaeaaC78B02a73427852;
    uint256 public constant MAX_OPP_STAKED = 100_000_000 ether;
    uint256 public immutable OPP_PER_SECOND;

    uint256 public END_STAKING_UNIX_TIME;
    
    uint256 public accumulator;
    uint256 public lastUpdate;
    uint256 public totalStaked;

    bool initialized;
   
    mapping(address => UserInfo) public stakingDetails;
    
    event Staked(address account, uint256 amount);
    event StakedWithdrawed(address account, uint256 amount);

    error OPPStaking_Invalid_Amount();
    error OPPStaking_Stakind_Ended();
    error OPPStaking_Max_Limit_Reached();
    error OPPStaking_Staking_On_Going();

    constructor(address _owner) {
        uint256 oppPerDay = 666_667 ether;    /// 20M per month
        OPP_PER_SECOND = oppPerDay / 86400;
        _transferOwnership(_owner);
    }

    function InitializeStaking(uint256 initialDeposit) external onlyOwner {
        require(!initialized,'Already Initialized');

        initialized = true;
        END_STAKING_UNIX_TIME = block.timestamp + (30 * 24 * 3600); // 30 days

        uint256 rewards = 20_100_000 ether;

        IERC20(OPTIMISM_PRIME_TOKEN).safeTransferFrom(msg.sender, address(this), rewards);
        
        stake(initialDeposit);
    }


    function stake(uint256 amount) public {
        if(block.timestamp > END_STAKING_UNIX_TIME) {
            revert OPPStaking_Stakind_Ended();
        }

        if(totalStaked + amount > MAX_OPP_STAKED) {
            revert OPPStaking_Max_Limit_Reached();
        }

        require(initialized, 'Not initialized');

        uint256 userRewards = calculateReward(msg.sender);
        
        accumulator = getNewAccumulator();
        lastUpdate = block.timestamp;
        
        UserInfo storage userInfo = stakingDetails[msg.sender];

        userInfo.stakingBalance += amount;
        userInfo.userAccumulator = accumulator;

        if(userRewards > 0) {
            IERC20(OPTIMISM_PRIME_TOKEN).safeTransfer(msg.sender, userRewards);
        }

        totalStaked += amount;
    
        IERC20(OPTIMISM_PRIME_TOKEN).safeTransferFrom(msg.sender, address(this), amount);

        emit Staked(msg.sender, amount);
    }

    function claimRewards() public {
        if(block.timestamp <= END_STAKING_UNIX_TIME) {
            uint256 userRewards = calculateReward(msg.sender);

            accumulator = getNewAccumulator();
            lastUpdate = block.timestamp;

            UserInfo storage userInfo = stakingDetails[msg.sender];

            require(userInfo.stakingBalance > 0);

            userInfo.userAccumulator = accumulator;

            if(userRewards > 0) {
                IERC20(OPTIMISM_PRIME_TOKEN).safeTransfer(msg.sender, userRewards);
            }           
        }

        else {
            uint256 userRewards = calculateReward(msg.sender);

            if(userRewards > 0) {
                IERC20(OPTIMISM_PRIME_TOKEN).safeTransfer(msg.sender, userRewards);
            }    

            UserInfo storage userInfo = stakingDetails[msg.sender];

            if(userInfo.stakingBalance > 0) {
                IERC20(OPTIMISM_PRIME_TOKEN).safeTransfer(msg.sender, userInfo.stakingBalance);
                userInfo.stakingBalance = 0;
            }
        }
    }

    function withdrawStaked() external {
        if(block.timestamp <= END_STAKING_UNIX_TIME) {
            revert OPPStaking_Staking_On_Going();
        }
        claimRewards();
    }


    function getNewAccumulator() internal view returns(uint256) {
        if(totalStaked == 0) {
            return 0;
        }

        else {
            if(block.timestamp <= END_STAKING_UNIX_TIME) {
                uint256 numerator =   OPP_PER_SECOND*(block.timestamp-lastUpdate)*1e24;
                uint256 denominator = totalStaked;

                uint256 tokensPerStaked = numerator/denominator;
                return accumulator + tokensPerStaked;
            }
            else {
                uint256 numerator =   OPP_PER_SECOND*(END_STAKING_UNIX_TIME-lastUpdate)*1e24;
                uint256 denominator = totalStaked;

                uint256 tokensPerStaked = numerator/denominator;
                return accumulator + tokensPerStaked;
            }     
        }
    }

    function calculateReward(address account) public view returns (uint256) {
        UserInfo memory userInfo = stakingDetails[account];

        uint256 stakedBalance = userInfo.stakingBalance;
        uint256 _userAccumulator = userInfo.userAccumulator;

        return((stakedBalance * (getNewAccumulator() - _userAccumulator))/1e24);
    }

    function emergencyWithdraw() external onlyOwner {
        uint256 balance = IERC20(OPTIMISM_PRIME_TOKEN).balanceOf(address(this));
        IERC20(OPTIMISM_PRIME_TOKEN).safeTransfer(msg.sender, balance);
    }
}