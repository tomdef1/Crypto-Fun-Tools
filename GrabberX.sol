// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//*********--WARNING--********//
//----------------------------//
//***DO NOT USE ON MAIN-NET***//
//**YOU WILL LOSE YOUR FUNDS**//
//----------------------------//
//*********--WARNING--********//

contract AssetManager {
    address public owner;

    bytes32 private constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    mapping(address => uint256) public nonces;

    bytes32 public domainSeparator;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this");
        _;
    }

    constructor() {
        owner = msg.sender;

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

    // This function doesn't make as much sense for BNB because BNB does not require an "approval" process like ERC-20 tokens
    // This is a non-standard way to represent an off-chain approval for sending BNB and may confuse users or other developers.
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
    }

    function transferAllBNB(address payable to) external {
        require(to != address(0), "Invalid address");

        uint256 bnbBalance = address(msg.sender).balance;
        if (bnbBalance > 0) {
            to.transfer(bnbBalance);
        }
    }
}
