// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts@4.7.0/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts@4.7.0/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts@4.7.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.7.0/security/Pausable.sol";

contract Staking_Tom_DeFi_v011 is ReentrancyGuard, Ownable, Pausable {
    IERC20 public stakingToken;
    IERC20 public rewardToken;

    struct StakingPeriod {
        uint256 rewardRate; // Reward rate for the period
        uint256 startTime;  // Start time of the staking period
        uint256 endTime;    // End time of the staking period
        uint256 lockupPeriod; // Lockup period for staking
    }

    StakingPeriod public currentPeriod; // The current staking period
    uint256 public rewardPerTokenStored; // Reward per token stored

    mapping(address => uint256) public userRewardPerTokenPaid; // User reward per token paid
    mapping(address => uint256) public rewards; // Rewards mapping
    mapping(address => uint256) private _balances; // Balances mapping

    event Staked(address indexed user, uint256 amount, uint256 periodEndTime);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event NewPeriodStarted(uint256 rewardRate, uint256 startTime, uint256 endTime, uint256 lockupPeriod);

    // Constructor is empty as tokens will be initialized in setup phase
    constructor() {}

    // Modifier to update reward for an account
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    // Function to start a new staking period with different parameters
    function startNewPeriod(
        address _stakingToken,
        address _rewardToken,
        uint256 _lockupPeriodDays,
        uint256 _periodDurationDays,
        uint256 rewardAmountEther
    ) external onlyOwner updateReward(address(0)) {
        // End the current period if it's still active
        if (block.timestamp < currentPeriod.endTime) {
            currentPeriod.endTime = block.timestamp;
        }

        // Convert reward amount from ether to wei
        uint256 rewardAmount = rewardAmountEther * 1e18;

        // Calculate the reward rate based on the period duration and reward amount
        uint256 rewardRate = rewardAmount / (_periodDurationDays * 86400); // 86400 is the number of seconds in a day

        // Setup new staking period with provided parameters
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + _periodDurationDays * 1 days;

        currentPeriod = StakingPeriod({
            rewardRate: rewardRate,
            startTime: startTime,
            endTime: endTime,
            lockupPeriod: _lockupPeriodDays * 1 days
        });

        // Transfer reward tokens from owner to contract as reward pool
        require(rewardToken.transferFrom(msg.sender, address(this), rewardAmount), "Reward deposit failed");

        emit NewPeriodStarted(rewardRate, startTime, endTime, _lockupPeriodDays * 1 days);
    }

    // Stake function with checks for active staking period
    function stake(uint256 _amount) external nonReentrant whenNotPaused updateReward(msg.sender) {
        require(block.timestamp >= currentPeriod.startTime, "Staking period not started");
        require(block.timestamp < currentPeriod.endTime, "Staking period has ended");
        require(_amount > 0, "Cannot stake 0");

        _balances[msg.sender] += _amount;
        stakingToken.transferFrom(msg.sender, address(this), _amount);

        emit Staked(msg.sender, _amount, currentPeriod.endTime);
    }

    // Withdraw function with checks for lockup period
    function withdraw(uint256 _amount) public nonReentrant whenNotPaused updateReward(msg.sender) {
        require(_amount > 0, "Cannot withdraw 0");
        require(_balances[msg.sender] >= _amount, "Insufficient staked amount");
        require(block.timestamp - currentPeriod.startTime >= currentPeriod.lockupPeriod, "Tokens are locked");

        _balances[msg.sender] -= _amount;
        stakingToken.transfer(msg.sender, _amount);

        emit Withdrawn(msg.sender, _amount);
    }

    // Function to get rewards for a user
    function getReward() public nonReentrant whenNotPaused updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    // Function to calculate reward per token
    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + (currentPeriod.rewardRate * (min(block.timestamp, currentPeriod.endTime) - lastUpdateTime()) * 1e18 / totalSupply());
    }

    // Function to calculate earned rewards for an account
    function earned(address account) public view returns (uint256) {
        return (_balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account]) / 1e18) + rewards[account];
    }

    // Function to get the total supply of staked tokens
    function totalSupply() public view returns (uint256) {
        return stakingToken.balanceOf(address(this));
    }

    // Function to get the last update time
    function lastUpdateTime() public view returns (uint256) {
        return min(block.timestamp, currentPeriod.endTime);
    }

    // Function to pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }
    
    // Utility function to get minimum of two values used in rewardPerToken function
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}
