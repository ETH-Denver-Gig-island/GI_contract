// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDepositNFT {
    function mint(address to) external returns (uint256);

    function burn(uint256 id) external returns (address);
}

contract SimplePool {
    uint256 lockedPeriod; // basic 14 days = 14 * 24 * 60 * 60

    address public owner;
    address public lending;
    IDepositNFT nftAddress;

    struct DepositInfo {
        uint256 amount;
        uint256 lastTimestamp;
    }

    mapping(uint256 => uint256) public totalAmounts;
    mapping(uint256 => DepositInfo) public depositInfos;

    function isOwnerOrLending() private view {
        require(msg.sender == owner || msg.sender == lending, "Not Valid User");
    }

    function isLending() private view {
        require(msg.sender == lending, "Not Valid User");
    }

    constructor(address _owner, address _lending, uint256 _period) {
        owner = _owner;
        lending = _lending;
        lockedPeriod = _period;
    }

    function deposit(address to) external payable {
        uint256 id = nftAddress.mint(to);
        depositInfos[id] = DepositInfo(msg.value, block.timestamp);
        totalAmounts[id] += msg.value;
    }

    function burnToWithdraw(uint256 id, address to) external {
        require(lockedPeriod > block.timestamp, "Not Yet");
        address nftOwner = nftAddress.burn(id);
        require(nftOwner == msg.sender, "This is not yours");

        DepositInfo memory info = depositInfos[id];
        require(info.amount != 0, "Not Valid NFT");
        totalAmounts[id] -= info.amount;

        payable(to).transfer(info.amount);
        delete depositInfos[id];
    }

    function transferETH(address to, uint256 amount) external {
        isOwnerOrLending();
        payable(to).transfer(amount);
    }

    function transferToken(IERC20 token, address to, uint256 amount) external {
        isOwnerOrLending();
        token.transfer(to, amount);
    }

    function getTotalAmounts(address add) view public returns (uint256) {
        
    }

    receive() external payable {}
}
