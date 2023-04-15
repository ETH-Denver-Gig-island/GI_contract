// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IPool {
    function transferETH(address to, uint256 amount) external;

    function transferToken(IERC20 token, address to, uint256 amount) external;
}

contract Lending {
    using SafeMath for uint256;

    address public owner;
    IPool public pool;
    uint256 public feePercentage; // 1 == 0.1%
    uint256 public yearInterestPer; // 1 == 0.1%
    IERC20 public token;

    struct BorrowerInfo {
        address dao;
        uint256 borrowedAmount;
        uint256 borrowingTimestamp;
        uint256 deadlineTimestamp;
        uint256 lastInterestCalculationTimestamp;
        uint256 interestPerSecond;
        uint256 feeAmount;
        uint256 repayAmount;
    }

    mapping(address => mapping(uint256 => BorrowerInfo)) public borrowerInfos;

    event Borrow(
        address dao,
        address indexed borrower,
        uint256 amount,
        uint256 perSecondInterest,
        uint256 feeAmount,
        uint256 deadlineTimestamp
    );

    event Repay(
        address indexed borrower,
        uint256 amount,
        uint256 interest,
        uint256 feeAmount,
        uint256 repayAmount,
        uint256 timestamp
    );

    event Pay(
        address indexed borrower,
        uint256 amount,
        uint256 interest,
        uint256 repayAmount,
        uint256 timestamp
    );

    constructor(
        address _owner,
        address _pool,
        uint256 _feePercentage,
        uint256 _yearInterestPer,
        address _token
    ) {
        owner = _owner;
        pool = IPool(_pool);
        feePercentage = _feePercentage;
        yearInterestPer = _yearInterestPer;
        token = IERC20(_token);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    function borrow(
        address borrower, // whitelist borrower
        address dao, // whitelist dao
        uint256 id, // backend dao data id
        uint256 amount, // borrow amount
        uint256 deadlineTimestamp // repayment deadline, is not repay before this time, the pay is all be interest.
    ) external onlyOwner {
        // only owner(backend) can borrow
        require(amount > 0, "Invalid amount");
        require(deadlineTimestamp > 3 * 30 days, "Too long");

        uint256 nowTimestamp = block.timestamp;
        require(nowTimestamp < deadlineTimestamp, "Invalid deadline");

        BorrowerInfo storage info = borrowerInfos[borrower][id];

        uint256 perSecondInterest;

        if (dao == address(0)) {
            info.dao = dao;
            info.borrowedAmount = amount;
            info.borrowingTimestamp = nowTimestamp;
            info.deadlineTimestamp = deadlineTimestamp;
            info.lastInterestCalculationTimestamp = nowTimestamp;

            perSecondInterest = calculateInterestPerSecond(amount);
            info.interestPerSecond = perSecondInterest;
            info.feeAmount = 0;
            info.repayAmount = 0;
        } else {
            info.repayAmount += calculateInterest(
                info.lastInterestCalculationTimestamp,
                info.interestPerSecond
            );

            info.borrowedAmount += amount;
            info.lastInterestCalculationTimestamp = nowTimestamp;

            perSecondInterest = calculateInterestPerSecond(info.borrowedAmount);
            info.interestPerSecond = perSecondInterest;
        }

        pool.transferETH(borrower, amount);

        emit Borrow(
            dao,
            borrower,
            amount,
            perSecondInterest,
            0,
            deadlineTimestamp
        );
    }

    function repay(uint256 id, address repayer) external payable {
        BorrowerInfo storage info = borrowerInfos[repayer][id];

        require(info.deadlineTimestamp >= block.timestamp, "Expired");
        require(info.borrowedAmount <= msg.value, "Not enough amount");

        uint256 interest = calculateInterest(
            info.lastInterestCalculationTimestamp,
            info.interestPerSecond
        );

        // Later
        // uint256 totalAmount = info.amount.add(interest);
        // uint256 totalFee = info.fee.add(totalAmount.mul(feePercentage).div(1000));
        // uint256 payableAmount = totalAmount.sub(totalFee);
        // token.transferFrom(msg.sender, address(this), payableAmount);
        // token.transfer(owner, totalAmount.mul(feePercentage).div(1000));

        info.repayAmount += interest;
        info.borrowedAmount = 0;
        info.lastInterestCalculationTimestamp = block.timestamp;
    }

    function pay(address borrower, uint256 id) external payable onlyOwner {
        BorrowerInfo storage info = borrowerInfos[borrower][id];

        if (info.borrowedAmount != 0) {
            return;
        }

        if (info.repayAmount == 0) {
            payable(borrower).transfer(msg.value);

            return;
        } else {
            // uint256 totalRepayAmount = info.repayAmount.add(fee);
            // uint256 totalFee = info.feeAmount.add(
            //     totalAmount.mul(feePercentage).div(1000)
            // );
            // uint256 payableAmount = totalAmount.sub(totalFee);

            payable(borrower).transfer(msg.value.sub(info.repayAmount));

            info.repayAmount = 0;
            info.borrowedAmount = 0;
            info.lastInterestCalculationTimestamp = 0;
        }
    }

    function calculateInterest(
        uint256 startTime,
        uint256 interestPerSecond
    ) private view returns (uint256) {
        uint256 time = block.timestamp.sub(startTime);
        uint256 interest = interestPerSecond.mul(time);
        return interest;
    }

    function calculateInterestPerSecond(
        uint256 amount
    ) public view returns (uint256) {
        uint256 interest = amount.mul(yearInterestPer).mul(1e18).mul(10) /
            (1e18 * 365 days);
        return interest;
    }

    receive() external payable {}
}
