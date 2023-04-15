// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract DepositNFT is ERC721Enumerable {
    address public owner;
    address public lending;
    address public pool;

    function isPool() private view {
        require(pool == msg.sender, "Not Lending");
    }

    function isOwner() private view {
        require(owner == msg.sender, "Not Owner");
    }

    constructor(
        address _owner,
        address _lending,
        address _pool
    ) ERC721("Gig NFT", "GNFT") {
        owner = _owner;
        lending = _lending;
        pool = _pool;
    }

    function mint(address to) external returns (uint256) {
        isPool();
        uint256 total = totalSupply();
        _safeMint(to, total);

        return total;
    }

    function burn(uint256 id) external returns (address) {
        isPool();
        address tokenOwner = ownerOf(id);
        _burn(id);

        return tokenOwner;
    }

    function setPoolAddress(address _new) external {
        isOwner();
        pool = _new;
    }
}
