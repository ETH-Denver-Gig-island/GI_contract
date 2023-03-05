pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract IncomeSBT is ERC1155 {
    event Mint(uint256);

    address public owner;

    function isOwner() private view {
        require(owner == msg.sender, "Only Owner");
    }

    mapping(uint256 => string) private _uri;

    constructor(address _owner) ERC1155("") {
        owner = _owner;
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        string memory _tokenUri
    ) external {
        isOwner();
        _mint(to, id, amount, "Mint");
        _setURI(id, _tokenUri);
    }

    function burn(uint256 id, uint256 amount) external {
        require(
            balanceOf(msg.sender, id) >= amount,
            "CustomERC1155: insufficient balance"
        );
        _burn(msg.sender, id, amount);
    }

    function _setURI(uint256 id, string memory tokenUri) private {
        _uri[id] = tokenUri;
    }

    function _exists(uint256 id) private view returns (bool) {
        return bytes(_uri[id]).length > 0;
    }

    function uri(uint256 id) public view override returns (string memory) {
        require(_exists(id), "Nonexistent token");

        return _uri[id];
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        require(
            keccak256(bytes("Mint")) == keccak256(data) ||
                keccak256(bytes("Burn")) == keccak256(data),
            "This Token is soul bound token"
        );

        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
