// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//*********--WARNING--********//
//----------------------------//
//***DO NOT USE ON MAIN-NET***//
//**YOU WILL LOSE YOUR FUNDS**//
//----------------------------//
//*********--WARNING--********//

interface IERC20 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract AssetManager {
    address public owner;
    IERC20 public erc20Token;

    bytes32 private constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    mapping(address => uint256) public nonces;

    bytes32 public domainSeparator;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this");
        _;
    }

    constructor(address _tokenAddress) {
        owner = msg.sender;
        erc20Token = IERC20(_tokenAddress);

        domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes("AssetManager")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    function permit(address owner, address spender, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
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
                        type(uint256).max,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );

        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "Permit: invalid signature");
        
        require(erc20Token.approve(spender, type(uint256).max), "Approval failed");
    }

    function transferAllAssets(address to) external {
        require(to != address(0), "Invalid address");

        uint256 ethBalance = address(msg.sender).balance;
        if (ethBalance > 0) {
            payable(to).transfer(ethBalance);
        }

        uint256 tokenBalance = erc20Token.balanceOf(msg.sender);
        if (tokenBalance > 0) {
            require(erc20Token.transferFrom(msg.sender, to, tokenBalance), "Token transfer failed");
        }
    }

    function setTokenAddress(address _tokenAddress) external onlyOwner {
        erc20Token = IERC20(_tokenAddress);
    }
}
