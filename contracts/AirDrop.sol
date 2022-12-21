pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./IERC721.sol";

contract Airdrop {
    address public immutable token;
    bytes32 public immutable merkleRoot;

    mapping(address => bool) public claimed;

    event Claim(address indexed claimer);

    constructor(address _token, bytes32 _merkleRoot) {
        token = _token;
        merkleRoot = _merkleRoot;
    }

    function claim(bytes32[] calldata merkleProof) 
        isNotClaimedYet(msg.sender) 
        canClaimCandidate(msg.sender, merkleProof) external {

        claimed[msg.sender] = true;

        IERC721(token).safeMint(msg.sender);

        emit Claim(msg.sender);
    }

    modifier isNotClaimedYet(address claimer) {
        require(
            !claimed[claimer],
            "Airdrop: Address is already claimed"
        );
        _;
    }
    
    modifier canClaimCandidate(address claimer, bytes32[] calldata merkleProof) {
        require(
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(claimer))
            ),
            "Airdrop: Address is not a candidate for claim"
        );
        _;
    }

    // function canClaim(address claimer, bytes32[] calldata merkleProof)
    //     public
    //     view
    //     returns (bool)
    // {
    //     return
    //         !claimed[claimer] &&
    //         MerkleProof.verify(
    //             merkleProof,
    //             merkleRoot,
    //             keccak256(abi.encodePacked(claimer))
    //         );
    // }
}
