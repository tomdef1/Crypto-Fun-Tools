// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Staking_Tom_DeFi_v011 is ReentrancyGuard, AccessControl {
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
    IERC20 public stakingToken;
    IERC20 public rewardToken;

    uint256 public rewardRate; // tokens per second
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) private _balances;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    // Define Staking & Reward Token
    constructor(address _stakingToken, address _rewardToken) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
    }
    
    // Update reward state before more actions
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    // Stake
    function stake(uint256 _amount) external nonReentrant updateReward(msg.sender) {
        require(_amount > 0, "Cannot stake 0");
        _balances[msg.sender] += _amount;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);
    }

    // Withdraw
    function withdraw(uint256 _amount) public nonReentrant updateReward(msg.sender) {
        require(_amount > 0, "Cannot withdraw 0");
        require(_balances[msg.sender] >= _amount, "Insufficient staked amount");
        _balances[msg.sender] -= _amount;
        stakingToken.transfer(msg.sender, _amount);
        emit Withdrawn(msg.sender, _amount);
    }

    // Withdraw only rewards
    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    // Calculates the amount of reward each token is entitled to at the current moment
    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + ((block.timestamp - lastUpdateTime) * rewardRate * 1e18 / _totalSupply());
    }

    // Calculates total rewards earned by an account
    function earned(address account) public view returns (uint256) {
        return (_balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account]) / 1e18) + rewards[account];
    }

    // Owner sets rate of reward token
    function setRewardRate(uint256 _rate) external onlyRole(CONTROLLER_ROLE) {
        rewardRate = _rate;
    }

    // Define reward token
    function setRewardToken(address _newRewardToken) external onlyRole(CONTROLLER_ROLE) {
        rewardToken = IERC20(_newRewardToken);
    }

    // Define staking token
    function setStakingToken(address _newStakingToken) external onlyRole(CONTROLLER_ROLE) {
        stakingToken = IERC20(_newStakingToken);
    }

    // Emergency exit allowing stakers to withdraw without rewards
    function emergencyExit() external nonReentrant {
        uint256 amount = _balances[msg.sender];
        require(amount > 0, "No tokens to withdraw");
        _balances[msg.sender] = 0;
        stakingToken.transfer(msg.sender, amount);
        rewards[msg.sender] = 0; // Resetting rewards as they won't be claimed using this function
        emit Withdrawn(msg.sender, amount);
    }

    // Force return staked tokens and rewards, stopping everything
    // USE WITH CAUTION as large amounts of stakers could result in mad gas fees
    function forceBOOT() external onlyRole(CONTROLLER_ROLE) {
        for(uint i=0; i < totalStakers; i++) {
            // Logic to iterate over ALL stakers and return their tokens and rewards
            // Address of staker: stakerAddress[i]
            uint256 stakedAmount = _balances[stakerAddress[i]];
            uint256 rewardAmount = rewards[stakerAddress[i]];
            _balances[stakerAddress[i]] = 0;
            rewards[stakerAddress[i]] = 0;
            stakingToken.transfer(stakerAddress[i], stakedAmount);
            rewardToken.transfer(stakerAddress[i], rewardAmount);
        }
        // Stop rewards and staking
        rewardRate = 0;
    }

    // Returns the total number of stakers as an int
    function totalStakers() public view returns (uint256) {
        return totalStakers;
    }

    // Returns the initial reward amount in Ether (or the equivalent unit)
    function initialRewardAmountinEther() public view returns (uint256) {
        // Assuming 'initialReward' is stored when contract starts or reward is set
        return initialReward / 1e18;
    }

    // Returns the current reward amount in Ether (or the equivalent unit)
    function currentRewardAmountinEther() public view returns (uint256) {
        // Assuming 'currentReward' is updated as rewards are paid out
        return currentReward / 1e18;
    }

    // Returns the time remaining in minutes for the staking period
    function timeRemainingMinutes() public view returns (uint256) {
        if (block.timestamp >= stakingEndTime) {
            return 0;
        }
        return (stakingEndTime - block.timestamp) / 60;
    }

    // Recover accidentally sent tokens (ERC20 and 721)
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyRole(DEFAULT_ADMIN_ROLE) {
    IERC20(tokenAddress).transfer(msg.sender, tokenAmount);}
    function recoverERC721(address tokenAddress, uint256 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC721(tokenAddress).transferFrom(address(this), msg.sender, tokenId);}
}
