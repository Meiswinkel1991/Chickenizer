// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

import "./interfaces/token/IChickenizerETH.sol";
import "./interfaces/Liquity/IBorrowerOperations.sol";
import "./interfaces/Liquity/ITroveManager.sol";
import "./interfaces/Liquity/IHintHelpers.sol";
import "./interfaces/Liquity/ISortedTroves.sol";

error CHKNStakingPool__AmountIsZero();
error CHKNStakingPool__AmountGreaterStackedETH();
error CHKNStakingPool__FailedToSendEther();

contract CHKNStakingPool {
    struct StakerInfo {
        uint256 stakedEther;
        uint256 lastSnapshot;
        uint256 rewardsPerEther;
    }

    /* ====== Interfaces ====== */
    // IChickenizerETH public immutable stakingToken; // cnETH
    IBorrowerOperations private immutable borrowerOperatorLiquity;
    ITroveManager private immutable troveManagerLiquity;
    ISortedTroves private immutable sortedTrovesLiquity;
    IHintHelpers private immutable hintHelpersLiquity;

    /* ====== State Variables ====== */
    uint256 public constant LUSD_GAS_COMPENSATION = 200e18;

    uint256 private totalStakedETH;

    mapping(address => StakerInfo) private stakers;

    /* ====== Events ====== */
    event TotalStakeUpdated(uint256 newTotalStakedTokens);
    event TroveUpdated(uint256 totalCol, uint256 totalDept);

    /** === Modfiers === */

    modifier NonZeroAmount() {
        if (msg.value == 0) {
            revert CHKNStakingPool__AmountIsZero();
        }
        _;
    }

    constructor(
        address _borrowerOperator,
        address _troveManagerLiquityAddress,
        address _hintHelpersAddress,
        address _sortedTroveAddress
    ) {
        borrowerOperatorLiquity = IBorrowerOperations(_borrowerOperator);
        troveManagerLiquity = ITroveManager(_troveManagerLiquityAddress);
        hintHelpersLiquity = IHintHelpers(_hintHelpersAddress);
        sortedTrovesLiquity = ISortedTroves(_sortedTroveAddress);
    }

    /* ====== Functions ====== */

    function openTrove(
        uint256 _amountLUSD,
        uint256 _amountETH,
        uint256 _maxFee
    ) external {
        uint256 _expectedFee = troveManagerLiquity.getBorrowingFeeWithDecay(
            _amountLUSD
        );

        uint256 _expectedDept = _amountLUSD +
            _expectedFee +
            LUSD_GAS_COMPENSATION;

        uint256 _nominalICR = (_amountETH * 1e20) / _expectedDept;

        (address _upperHint, address _lowerHint) = _getHints(_nominalICR);

        borrowerOperatorLiquity.openTrove{value: _amountETH}(
            _maxFee,
            _amountLUSD,
            _upperHint,
            _lowerHint
        );
    }

    function stakeETH() external payable NonZeroAmount {
        uint256 _sentETH = msg.value;

        totalStakedETH += _sentETH;

        stakers[msg.sender].stakedEther += _sentETH;

        emit TotalStakeUpdated(totalStakedETH);
    }

    function unstake(uint256 _amount) external {
        uint256 _balanceStakedTokens = stakers[msg.sender].stakedEther;

        if (_amount > _balanceStakedTokens) {
            revert CHKNStakingPool__AmountGreaterStackedETH();
        }

        stakers[msg.sender].stakedEther -= _amount;

        totalStakedETH -= _amount;

        (bool sent, ) = address(msg.sender).call{value: _amount}("");

        if (!sent) {
            revert CHKNStakingPool__FailedToSendEther();
        }
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    /* ====== Internal Functions ====== */

    function _getHints(uint256 _nominalICR)
        public
        view
        returns (address, address)
    {
        uint256 _numTroves = sortedTrovesLiquity.getSize();

        uint256 _numTrials = _numTroves * 15;

        (address _approxHint, , ) = hintHelpersLiquity.getApproxHint(
            _nominalICR,
            _numTrials,
            42
        );

        (address _upperHint, address _lowerHint) = sortedTrovesLiquity
            .findInsertPosition(_nominalICR, _approxHint, _approxHint);

        return (_upperHint, _lowerHint);
    }

    /* ====== View / Pure Functions ====== */

    function getStakerInformations(address _staker)
        external
        view
        returns (StakerInfo memory)
    {
        return stakers[_staker];
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
