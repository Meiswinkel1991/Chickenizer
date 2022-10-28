// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

error ChickenFarmStaking__AmountIsZero();
error ChickenFarmStaking__AmountGreaterStackedETH();

contract ChickenFarmStaking {
    using SafeERC20 for IERC20;

    /** === Interfaces === */
    IERC20 public immutable rewardsToken; // bLUSD

    /** === State Variables === */

    uint256 private rewardPerToken;
    uint256 private totalTokensStaked;

    mapping(address => uint256) private balanceOf;
    mapping(address => uint256) private snapshots;
    mapping(address => uint256) private rewards;

    /** === Events === */

    event UpdateUserStake(address user, uint256 newStake);

    /** === Modfiers === */

    modifier NonZeroAmount() {
        if (msg.value == 0) {
            revert ChickenFarmStaking__AmountIsZero();
        }
        _;
    }

    constructor(address _rewardsTokenAddress) {
        rewardsToken = IERC20(_rewardsTokenAddress);
    }

    /** === Functions === */

    function stakeETH() external payable NonZeroAmount {
        _updateReward(msg.sender);

        balanceOf[msg.sender] += msg.value;

        totalTokensStaked += msg.value;

        emit UpdateUserStake(msg.sender, balanceOf[msg.sender]);
    }

    function unstake(uint256 _amount) public {
        if (_amount == 0) {
            revert ChickenFarmStaking__AmountIsZero();
        }

        if (balanceOf[msg.sender] < _amount) {
            revert ChickenFarmStaking__AmountGreaterStackedETH();
        }

        _updateReward(msg.sender);

        // TODO: send ETH to the user
    }

    /** === Internal Functions === */

    function _updateReward(address _user) internal {
        uint256 _rewardSnapshot = snapshots[_user];
        uint256 _rewardGain = ((balanceOf[_user]) *
            (rewardPerToken - _rewardSnapshot)) / 10**18;

        //update the snapshot of the user
        snapshots[_user] = rewardPerToken;

        //update the claimable rewards of the user
        rewards[_user] += _rewardGain;
    }
}
