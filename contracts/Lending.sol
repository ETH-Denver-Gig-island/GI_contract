// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Lending {
    using SafeMath for uint256;

    address public owner;
    uint256 public feePercentage; // 1 == 0.1%
    uint256 public monthlyInterest; // 1 == 0.1%
    IERC20 public token;

    struct BorrowerInfo {
        address dao;
        uint256 borrowedAmount;
        uint256 borrowingTimestamp;
        uint256 deadlineTimestamp;
        uint256 lastInterestCalculationTimestamp;
        uint256 interest;
        uint256 feeAmount;
        uint256 repayAmount;
    }

    mapping(address => BorrowerInfo[]) public borrowerInfos;

    event Borrow(
        address dao,
        address indexed borrower,
        uint256 amount,
        uint256 interest,
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
        uint256 _feePercentage,
        uint256 _monthlyInterest,
        address _token
    ) {
        owner = _owner;
        feePercentage = _feePercentage;
        monthlyInterest = _monthlyInterest;
        token = IERC20(_token);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    function borrow(
        address borrower,
        address dao,
        uint256 amount,
        uint256 deadlineTimestamp
    ) external {
        uint256 borrowingTimestamp = block.timestamp;
        uint256 interest = calculateInterest(
            amount,
            borrowingTimestamp,
            block.timestamp,
            monthlyInterest
        );
        BorrowerInfo memory info = BorrowerInfo(
            dao,
            amount,
            borrowingTimestamp,
            deadlineTimestamp,
            block.timestamp,
            interest,
            0,
            0
        );
        borrowerInfos[borrower].push(info);
        emit Borrow(dao, borrower, amount, interest, 0, deadlineTimestamp);
    }

    function repay() external {
    uint256 amount;
    uint256 interest;
    uint256 fee;
    uint256 repayAmount;

    BorrowerInfo[] storage borrowerInfoList = borrowerInfos[msg.sender];
    for (uint256 i = 0; i < borrowerInfoList.length; i++) {
        BorrowerInfo storage borrowerInfo = borrowerInfoList[i];

        uint256 borrowedAmount = borrowerInfo.borrowedAmount;
        uint256 lastInterestCalculationTimestamp = borrowerInfo.lastInterestCalculationTimestamp;
        uint256 deadlineTimestamp = borrowerInfo.deadlineTimestamp;
        uint256 lendingTime = block.timestamp.sub(lastInterestCalculationTimestamp);
        uint256 interestPerSecond = calculateInterestPerSecond(borrowedAmount, monthlyInterest);
        uint256 newInterest = lendingTime.mul(interestPerSecond);
        uint256 interestAmount = borrowerInfo.interest.add(newInterest);
        uint256 repayableAmount = borrowedAmount.add(interestAmount);

        if (block.timestamp > deadlineTimestamp) {
            uint256 lateInterest = calculateInterest(borrowedAmount, deadlineTimestamp, block.timestamp, monthlyInterest);
            interestAmount = interestAmount.add(lateInterest);
            newInterest = newInterest.add(lateInterest);
        }

        amount = amount.add(borrowedAmount);
        interest = interest.add(newInterest);
        fee = fee.add(borrowerInfo.feeAmount);
        repayAmount = repayAmount.add(borrowerInfo.repayAmount);

        borrowerInfo.lastInterestCalculationTimestamp = block.timestamp;
        borrowerInfo.interest = interestAmount;
    }

    uint256 totalAmount = amount.add(interest);
    uint256 totalFee = fee.add(totalAmount.mul(feePercentage).div(1000));
    uint256 payableAmount = totalAmount.sub(totalFee);
    token.transferFrom(msg.sender, address(this), payableAmount);
    token.transfer(owner, totalAmount.mul(feePercentage).div(1000));

    for (uint256 i = 0; i < borrowerInfoList.length; i++) {
        BorrowerInfo storage borrowerInfo = borrowerInfoList[i];
        uint256 borrowedAmount = borrowerInfo.borrowedAmount;
        uint256 interestAmount = borrowerInfo.interest;

        uint256 borrowerRepayAmount = borrowedAmount.add(interestAmount).mul(payableAmount).div(totalAmount);
        uint256 borrowerFeeAmount = borrowerRepayAmount.mul(feePercentage).div(1000);
        uint256 borrowerPayableAmount = borrowerRepayAmount.sub(borrowerFeeAmount);

        borrowerInfo.feeAmount = borrowerFeeAmount;
        borrowerInfo.repayAmount = borrowerRepayAmount;

        if (borrowerPayableAmount > 0) {
            token.transfer(msg.sender, borrowerPayableAmount);
            emit Repay(msg.sender, borrowedAmount, interestAmount, borrowerFeeAmount, borrowerRepayAmount, block.timestamp);
        }
    }
}


    function pay(address borrower, uint256 amount) external onlyOwner {
        BorrowerInfo[] storage borrowerInfoList = borrowerInfos[borrower];
        require(borrowerInfoList.length > 0, "Borrower not found");

        uint256 totalAmount;
        uint256 totalInterest;
        uint256 totalRepayAmount;
        uint256 totalFeeAmount;

        for (uint256 i = 0; i < borrowerInfoList.length; i++) {
            BorrowerInfo storage borrowerInfo = borrowerInfoList[i];

            uint256 borrowedAmount = borrowerInfo.borrowedAmount;
            uint256 lastInterestCalculationTimestamp = borrowerInfo
                .lastInterestCalculationTimestamp;
            uint256 deadlineTimestamp = borrowerInfo.deadlineTimestamp;
            uint256 lendingTime = block.timestamp.sub(
                lastInterestCalculationTimestamp
            );
            uint256 interestPerSecond = calculateInterestPerSecond(
                borrowedAmount,
                monthlyInterest
            );
            uint256 newInterest = lendingTime.mul(interestPerSecond);
            uint256 interestAmount = borrowerInfo.interest.add(newInterest);
            uint256 repayableAmount = borrowedAmount.add(interestAmount);

            if (block.timestamp > deadlineTimestamp) {
                uint256 lateInterest = calculateInterest(
                    borrowedAmount,
                    deadlineTimestamp,
                    block.timestamp,
                    monthlyInterest
                );
                interestAmount = interestAmount.add(lateInterest);
                newInterest = newInterest.add(lateInterest);
            }

            uint256 payableAmount = repayableAmount.sub(
                borrowerInfo.repayAmount
            );
            uint256 feeAmount = payableAmount.mul(feePercentage).div(1000);
            uint256 repayAmount = payableAmount.sub(feeAmount);

            totalAmount = totalAmount.add(borrowedAmount);
            totalInterest = totalInterest.add(newInterest);
            totalRepayAmount = totalRepayAmount.add(repayAmount);
            totalFeeAmount = totalFeeAmount.add(feeAmount);

            borrowerInfo.interest = interestAmount;
            borrowerInfo.repayAmount = borrowerInfo.repayAmount.add(
                repayAmount
            );
            borrowerInfo.feeAmount = borrowerInfo.feeAmount.add(feeAmount);
        }

        uint256 remainingAmount = amount;
        for (uint256 i = 0; i < borrowerInfoList.length; i++) {
            BorrowerInfo storage borrowerInfo = borrowerInfoList[i];
            uint256 borrowedAmount = borrowerInfo.borrowedAmount;
            uint256 interestAmount = borrowerInfo.interest;
            uint256 repayAmount = borrowerInfo.repayAmount;
            uint256 feeAmount = borrowerInfo.feeAmount;

            uint256 borrowerPayableAmount = borrowedAmount
                .add(interestAmount)
                .sub(repayAmount)
                .sub(feeAmount);
            uint256 borrowerPaidAmount;
            if (borrowerPayableAmount <= remainingAmount) {
                borrowerPaidAmount = borrowerPayableAmount;
                remainingAmount = remainingAmount.sub(borrowerPayableAmount);
                borrowerInfo.repayAmount = borrowerInfo.borrowedAmount.add(
                    borrowerInfo.interest
                );
            } else {
                borrowerPaidAmount = remainingAmount;
                borrowerInfo.repayAmount = borrowerInfo.repayAmount.add(
                    borrowerPaidAmount.mul(borrowerPayableAmount).div(
                        borrowerPayableAmount.add(feeAmount)
                    )
                );
                remainingAmount = 0;
            }

            if (borrowerPaidAmount > 0) {
                token.transferFrom(
                    msg.sender,
                    address(this),
                    borrowerPaidAmount
                );
                token.transfer(
                    borrower,
                    borrowerPaidAmount.mul(borrowedAmount).div(
                        borrowedAmount.add(interestAmount)
                    )
                );
                token.transfer(
                    owner,
                    borrowerPaidAmount
                        .mul(interestAmount)
                        .div(borrowedAmount.add(interestAmount))
                        .mul(feePercentage)
                        .div(1000)
                );
                emit Pay(
                    borrower,
                    borrowedAmount,
                    interestAmount,
                    borrowerPaidAmount,
                    block.timestamp
                );
            }

            if (remainingAmount == 0) {
                break;
            }
        }

        require(remainingAmount == 0, "Insufficient payment");
        if (totalRepayAmount > 0) {
            token.transfer(owner, totalFeeAmount);
            emit Repay(
                borrower,
                totalAmount,
                totalInterest,
                totalFeeAmount,
                totalRepayAmount,
                block.timestamp
            );
        }
    }

    function calculateInterest(
        uint256 amount,
        uint256 startTime,
        uint256 endTime,
        uint256 monthlyInterestRate
    ) private pure returns (uint256) {
        uint256 time = endTime.sub(startTime);
        uint256 interestRate = monthlyInterestRate.mul(time).div(30 days);
        return amount.mul(interestRate).div(1000);
    }

    function calculateInterestPerSecond(
        uint256 amount,
        uint256 monthlyInterestRate
    ) private pure returns (uint256) {
        uint256 interestRatePerSecond = monthlyInterestRate.div(30 days);
        return amount.mul(interestRatePerSecond);
    }
}
