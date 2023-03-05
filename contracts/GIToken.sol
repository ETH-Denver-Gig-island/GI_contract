// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface ILendingPool {
    function mint(address to, uint256 amount) external;
}

contract MyToken is ERC20 {
    address public owner;
    ILendingPool public lendingPool;

    constructor(address _lendingPool) ERC20("MyToken", "MTK") {
        lendingPool = ILendingPool(_lendingPool);

        // 초기 발행량을 lendingpool에게 발행해줍니다.
        uint256 initialSupply = 1e8 * 10**decimals();
        _mint(_lendingPool, initialSupply);
    }

    function mint(address to, uint256 amount) external {
        require(
            msg.sender == address(lendingPool),
            "ERC20: only lending pool can mint tokens"
        );
        _mint(to, amount);
    }
}
